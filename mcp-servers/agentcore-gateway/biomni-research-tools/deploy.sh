#!/bin/bash
set -e
set -o pipefail

# Standalone deployment for Biomni Research Tools MCP Server (Gateway only)
# Deploys: Lambda functions + Cognito + AgentCore Gateway
# Does NOT deploy: Agent Runtime, Memory, Streamlit UI
#
# Usage: ./deploy.sh [APP_NAME]
#   APP_NAME defaults to "biomni-research-tools"
#   Set AWS_PROFILE and AWS_REGION before running if needed.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
AGENT_DIR="$REPO_ROOT/agents_catalog/28-Research-agent-biomni-gateway-tools"
PREREQ_DIR="$AGENT_DIR/prerequisite"
CFN_DIR="$SCRIPT_DIR/cfn"

# ----- Config -----
APP_NAME=${1:-biomni-research-tools}
INFRA_STACK_NAME="${APP_NAME}-infra"
COGNITO_STACK_NAME="${APP_NAME}-cognito"
AGENTCORE_STACK_NAME="${APP_NAME}-agentcore"

REGION=${AWS_REGION:-$(aws configure get region 2>/dev/null || echo "us-west-2")}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
FULL_BUCKET_NAME="${APP_NAME}-${REGION}-${ACCOUNT_ID}"

echo "========================================"
echo "Biomni Research Tools - MCP Server Deploy"
echo "========================================"
echo "Region:   $REGION"
echo "Account:  $ACCOUNT_ID"
echo "App Name: $APP_NAME"
echo "Bucket:   $FULL_BUCKET_NAME"
echo "Stacks:   $INFRA_STACK_NAME, $COGNITO_STACK_NAME, $AGENTCORE_STACK_NAME"
echo "========================================"

# ----- 0. Download schema_db if not present -----
SCHEMA_DIR="$PREREQ_DIR/lambda-database/python/schema_db"
if [ ! -d "$SCHEMA_DIR" ] || [ -z "$(ls -A "$SCHEMA_DIR" 2>/dev/null)" ]; then
  echo "📥 Downloading Biomni schema files..."
  mkdir -p "$SCHEMA_DIR"
  URLS=$(curl -s "https://api.github.com/repos/snap-stanford/Biomni/contents/biomni/tool/schema_db" | python3 -c "
import sys, json
items = json.load(sys.stdin)
for item in items:
    if item['name'].endswith('.pkl'):
        print(item['download_url'])
")
  for url in $URLS; do
    filename=$(basename "$url")
    echo "  Downloading $filename..."
    curl -sL "$url" -o "$SCHEMA_DIR/$filename"
  done
  echo "✅ Schema files downloaded ($(ls "$SCHEMA_DIR" | wc -l | tr -d ' ') files)"
else
  echo "✅ Schema files already present ($(ls "$SCHEMA_DIR" | wc -l | tr -d ' ') files)"
fi

# ----- 1. Create S3 bucket -----
echo ""
echo "🪣 Creating S3 bucket: $FULL_BUCKET_NAME"
aws s3 mb "s3://$FULL_BUCKET_NAME" --region "$REGION" 2>/dev/null || \
  echo "  Bucket already exists."

# ----- 2. Build Lambda packages -----
echo ""
echo "📦 Building Lambda deployment packages..."
cd "$PREREQ_DIR"
python3 create_lambda_zip.py

DB_ZIP_FILE="database-gateway-function.zip"
LIT_ZIP_FILE="literature-gateway-function.zip"

# Generate hashes for cache busting
DB_HASH=$(shasum -a 256 "$DB_ZIP_FILE" | cut -d' ' -f1 | cut -c1-8)
LIT_HASH=$(shasum -a 256 "$LIT_ZIP_FILE" | cut -d' ' -f1 | cut -c1-8)

DB_S3_KEY="lambda-code/database-gateway-function-${DB_HASH}.zip"
LIT_S3_KEY="lambda-code/literature-gateway-function-${LIT_HASH}.zip"

# API spec files
DB_API_SPEC_FILE="lambda-database/api_spec.json"
LIT_API_SPEC_FILE="lambda-literature/api_spec.json"
DB_API_S3_KEY="api-specs/database-api-spec.json"
LIT_API_S3_KEY="api-specs/literature-api-spec.json"

# ----- 3. Upload to S3 -----
echo ""
echo "☁️  Uploading to S3..."
aws s3 cp "$DB_ZIP_FILE" "s3://$FULL_BUCKET_NAME/$DB_S3_KEY"
aws s3 cp "$LIT_ZIP_FILE" "s3://$FULL_BUCKET_NAME/$LIT_S3_KEY"
aws s3 cp "$DB_API_SPEC_FILE" "s3://$FULL_BUCKET_NAME/$DB_API_S3_KEY"
aws s3 cp "$LIT_API_SPEC_FILE" "s3://$FULL_BUCKET_NAME/$LIT_API_S3_KEY"
echo "✅ Uploaded all artifacts"

# ----- 4. Deploy CloudFormation stacks -----
deploy_stack() {
  local stack_name=$1
  local template_file=$2
  shift 2

  echo ""
  echo "🚀 Deploying: $stack_name"

  if output=$(aws cloudformation deploy \
    --stack-name "$stack_name" \
    --template-file "$template_file" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region "$REGION" \
    "$@" 2>&1); then
    echo "✅ $stack_name deployed successfully"
    return 0
  elif echo "$output" | grep -qi "No changes to deploy"; then
    echo "ℹ️  No changes for $stack_name"
    return 0
  else
    echo "❌ Error deploying $stack_name:"
    echo "$output"
    return 1
  fi
}

# Stack 1: Infrastructure (Lambdas + IAM roles)
deploy_stack "$INFRA_STACK_NAME" "$CFN_DIR/infrastructure.yaml" \
  --parameter-overrides \
    "AppName=$APP_NAME" \
    "LambdaS3Bucket=$FULL_BUCKET_NAME" \
    "DatabaseLambdaS3Key=$DB_S3_KEY" \
    "LiteratureLambdaS3Key=$LIT_S3_KEY"

# Stack 2: Cognito (auth)
deploy_stack "$COGNITO_STACK_NAME" "$CFN_DIR/cognito.yaml" \
  --parameter-overrides \
    "AppName=$APP_NAME"

# Stack 3: AgentCore (Gateway + targets)
deploy_stack "$AGENTCORE_STACK_NAME" "$CFN_DIR/agentcore.yaml" \
  --parameter-overrides \
    "AppName=$APP_NAME" \
    "S3Bucket=$FULL_BUCKET_NAME" \
    "GatewayName=${APP_NAME}-gw"

# ----- 5. Output results -----
echo ""
echo "========================================"
echo "✅ Deployment Complete!"
echo "========================================"

GATEWAY_URL=$(aws ssm get-parameter --name "/app/${APP_NAME}/agentcore/gateway_url" --query Parameter.Value --output text --region "$REGION" 2>/dev/null || echo "PENDING")

echo ""
echo "Gateway URL: $GATEWAY_URL"
echo ""
echo "Next steps:"
echo ""
echo "  1. Get token:  source get-token.sh $APP_NAME"
echo "  2. Register:   claude mcp add --transport http biomni-research \"\$BIOMNI_GATEWAY_URL\" --header \"Authorization: Bearer \$BIOMNI_MCP_TOKEN\""
echo ""
echo "========================================"
echo ""
echo "⚠️  Post-deploy (optional, for literature tools):"
echo "  aws ssm put-parameter --name '/app/${APP_NAME}/anthropic_api_key' --value 'YOUR_KEY' --type 'SecureString' --overwrite --region $REGION"
echo "  aws ssm put-parameter --name '/app/${APP_NAME}/pubmed_email' --value 'YOUR_EMAIL' --type 'String' --overwrite --region $REGION"

cd "$SCRIPT_DIR"
