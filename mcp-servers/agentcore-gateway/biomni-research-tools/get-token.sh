#!/bin/bash
# Fetches a Cognito M2M access token for the Biomni Research Tools MCP Gateway.
# Usage: source get-token.sh [APP_NAME]
#   Sets BIOMNI_MCP_TOKEN and BIOMNI_GATEWAY_URL in the current shell.
#   Then register with: claude mcp add --transport http biomni-research "$BIOMNI_GATEWAY_URL" --header "Authorization: Bearer $BIOMNI_MCP_TOKEN"

APP_NAME=${1:-biomni-research-tools}
REGION=${AWS_REGION:-$(aws configure get region 2>/dev/null || echo "us-west-2")}

# Retrieve Cognito and Gateway config from SSM
GATEWAY_URL=$(aws ssm get-parameter --name "/app/${APP_NAME}/agentcore/gateway_url" --query Parameter.Value --output text --region "$REGION")
CLIENT_ID=$(aws ssm get-parameter --name "/app/${APP_NAME}/agentcore/machine_client_id" --query Parameter.Value --output text --region "$REGION")
CLIENT_SECRET=$(aws ssm get-parameter --name "/app/${APP_NAME}/agentcore/cognito_secret" --query Parameter.Value --output text --region "$REGION")
COGNITO_DOMAIN=$(aws ssm get-parameter --name "/app/${APP_NAME}/agentcore/cognito_domain" --query Parameter.Value --output text --region "$REGION")
AUTH_SCOPE=$(aws ssm get-parameter --name "/app/${APP_NAME}/agentcore/cognito_auth_scope" --query Parameter.Value --output text --region "$REGION")

# Strip protocol prefix for token endpoint
COGNITO_DOMAIN_CLEAN="${COGNITO_DOMAIN#https://}"

# Request token via client_credentials grant
TOKEN_RESPONSE=$(curl -s -X POST "https://${COGNITO_DOMAIN_CLEAN}/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}&scope=${AUTH_SCOPE}")

# Extract access token
BIOMNI_MCP_TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])" 2>/dev/null)

if [ -z "$BIOMNI_MCP_TOKEN" ]; then
  echo "ERROR: Failed to get token. Response: $TOKEN_RESPONSE" >&2
  return 1 2>/dev/null || exit 1
fi

export BIOMNI_MCP_TOKEN
export BIOMNI_GATEWAY_URL="$GATEWAY_URL"

echo "Gateway URL: $BIOMNI_GATEWAY_URL"
echo "Token expires in: 60 minutes"
echo ""
echo "Register with Claude Code:"
echo "  claude mcp add --transport http biomni-research \"\$BIOMNI_GATEWAY_URL\" --header \"Authorization: Bearer \$BIOMNI_MCP_TOKEN\""
echo ""
echo "Or add to .mcp.json (headers with env var):"
echo "  {\"mcpServers\":{\"biomni-research\":{\"type\":\"http\",\"url\":\"$GATEWAY_URL\",\"headers\":{\"Authorization\":\"Bearer \${BIOMNI_MCP_TOKEN}\"}}}}"
