#!/bin/bash
# Integration test: Skills + MCP Servers via Claude Code
#
# Tests that Claude Code can:
#   1. Connect to deployed MCP servers (Biomni Gateway + OLS Runtime)
#   2. Use skills to guide tool selection
#   3. Execute real tool calls and get results
#
# Prerequisites:
#   - AWS_PROFILE set to a profile with access to account 942514891246
#   - AWS_REGION=us-west-2
#   - Biomni Gateway and OLS Runtime deployed
#   - Claude Code installed
#
# Usage:
#   ./tests/test_integration.sh              # Run all integration tests
#   ./tests/test_integration.sh --biomni     # Test Biomni Gateway + skills only
#   ./tests/test_integration.sh --ols        # Test OLS Runtime + skills only

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

REGION=${AWS_REGION:-us-west-2}
PASSED=0
FAILED=0
TOTAL=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "============================================================"
echo " HCLS Toolkit Integration Test"
echo " Skills + MCP Servers via Claude Code"
echo "============================================================"
echo ""

# ---- Step 1: Get tokens ----
echo "--- Getting authentication tokens ---"

if [ "$1" != "--ols" ]; then
  eval "$(bash -c '
    export AWS_PROFILE='"${AWS_PROFILE:-}"'
    export AWS_REGION='"${AWS_REGION:-us-west-2}"'
    source "'"$REPO_ROOT"'/mcp-servers/agentcore-gateway/biomni-research-tools/get-token.sh" >/dev/null 2>&1
    echo "export BIOMNI_MCP_TOKEN=\"$BIOMNI_MCP_TOKEN\""
    echo "export BIOMNI_GATEWAY_URL=\"$BIOMNI_GATEWAY_URL\""
  ')"
  if [ -z "$BIOMNI_MCP_TOKEN" ]; then
    echo -e "${RED}FAIL: Could not get Biomni token${NC}"
    exit 1
  fi
  echo "  Biomni Gateway: token obtained"
fi

if [ "$1" != "--biomni" ]; then
  eval "$(bash -c '
    export AWS_PROFILE='"${AWS_PROFILE:-}"'
    export AWS_REGION='"${AWS_REGION:-us-west-2}"'
    source "'"$REPO_ROOT"'/mcp-servers/agentcore-runtime/ontology-lookup-service/get-token.sh" >/dev/null 2>&1
    echo "export OLS_MCP_TOKEN=\"$OLS_MCP_TOKEN\""
    echo "export OLS_MCP_URL=\"$OLS_MCP_URL\""
  ')"
  if [ -z "$OLS_MCP_TOKEN" ]; then
    echo -e "${RED}FAIL: Could not get OLS token${NC}"
    exit 1
  fi
  echo "  OLS Runtime:    token obtained"
fi
echo ""

# ---- Step 2: Create temporary MCP config ----
MCP_CONFIG=$(mktemp /tmp/hcls-test-mcp-XXXXXX.json)

# Build MCP config with only the servers we have tokens for
python3 -c "
import json
servers = {}
biomni_url = '${BIOMNI_GATEWAY_URL:-}'
biomni_token = '${BIOMNI_MCP_TOKEN:-}'
ols_url = '${OLS_MCP_URL:-}'
ols_token = '${OLS_MCP_TOKEN:-}'
if biomni_url and biomni_token:
    servers['biomni-research'] = {'type': 'http', 'url': biomni_url, 'headers': {'Authorization': f'Bearer {biomni_token}'}}
if ols_url and ols_token:
    servers['ontology-lookup'] = {'type': 'http', 'url': ols_url, 'headers': {'Authorization': f'Bearer {ols_token}'}}
with open('$MCP_CONFIG', 'w') as f:
    json.dump({'mcpServers': servers}, f, indent=2)
print(f'  MCP config: $MCP_CONFIG ({len(servers)} servers)')
"
echo ""

# ---- Helper function ----
run_test() {
  local test_name="$1"
  local prompt="$2"
  local expect_pattern="$3"
  local skill_file="$4"

  TOTAL=$((TOTAL + 1))
  echo -n "  [$TOTAL] $test_name... "

  # Build system prompt with skill content if provided
  local sys_prompt="You have access to MCP tools for biomedical research. Use them to answer the question. Be concise and return factual results."
  if [ -n "$skill_file" ] && [ -f "$REPO_ROOT/skills/$skill_file/SKILL.md" ]; then
    sys_prompt="$sys_prompt

Here is your domain skill guidance:

$(cat "$REPO_ROOT/skills/$skill_file/SKILL.md")"
  fi

  # Run Claude Code in print mode with MCP config and skill-enhanced system prompt
  set +e
  RESULT=$(claude -p "$prompt" \
    --mcp-config "$MCP_CONFIG" \
    --system-prompt "$sys_prompt" \
    --allowedTools "mcp__biomni-research__*,mcp__ontology-lookup__*" \
    --max-budget-usd 0.50 \
    2>/dev/null)
  local exit_code=$?
  set -e
  if [ $exit_code -ne 0 ] && [ -z "$RESULT" ]; then
    RESULT="CLAUDE_ERROR (exit code $exit_code)"
  fi

  if echo "$RESULT" | grep -qi "$expect_pattern"; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
  elif echo "$RESULT" | grep -q "CLAUDE_ERROR"; then
    echo -e "${RED}FAIL (claude error)${NC}"
    echo "       $(echo "$RESULT" | tail -1 | cut -c1-120)"
    FAILED=$((FAILED + 1))
  else
    echo -e "${RED}FAIL (pattern '$expect_pattern' not found)${NC}"
    echo "       Response preview: $(echo "$RESULT" | head -3 | cut -c1-120)"
    FAILED=$((FAILED + 1))
  fi
}

# ---- Test Suite: Biomni Gateway + Skills ----
if [ "$1" != "--ols" ]; then
  echo "--- Biomni Gateway + Research Skills ---"
  echo ""

  # Test 1: Database query (tests research-biomedical-databases skill)
  run_test "UniProt protein lookup" \
    "Use the biomni-research tools to query UniProt for human insulin protein. Return the protein name and ID." \
    "insulin\|P01308\|INS" \
    "research-biomedical-databases"

  # Test 2: Variant database (tests genomics-variant-interpretation skill)
  run_test "ClinVar variant lookup" \
    "Use the biomni-research tools to query ClinVar for BRCA1 pathogenic variants. Return at least one variant." \
    "BRCA1\|pathogenic\|breast" \
    "genomics-variant-interpretation"

  # Test 3: Gene expression (tests research-deep-literature-review skill)
  run_test "Gene expression lookup" \
    "Use the biomni-research tools to query for TP53 gene expression data. Return gene name or expression info." \
    "TP53\|p53\|tumor\|expression\|gene" \
    "research-deep-literature-review"

  # Test 4: Pathway query (tests biomarker-pathway-analysis skill)
  run_test "Reactome pathway query" \
    "Use the biomni-research tools to query Reactome for insulin signaling pathway. Return the pathway name." \
    "insulin\|signal\|pathway" \
    "biomarker-pathway-analysis"

  echo ""
fi

# ---- Test Suite: OLS Runtime + Skills ----
if [ "$1" != "--biomni" ]; then
  echo "--- OLS Runtime + Terminology Skills ---"
  echo ""

  # Test 5: Term search (tests terminology-ontology-lookup skill)
  run_test "Ontology term search" \
    "Use the ontology-lookup tools to search for 'diabetes mellitus' terms. Return the term label and ontology." \
    "diabetes\|MONDO\|DOID\|mellitus" \
    "terminology-ontology-lookup"

  # Test 6: Ontology info
  run_test "Ontology metadata" \
    "Use the ontology-lookup tools to get information about the MONDO ontology. Return the title and description." \
    "Mondo\|Disease\|Ontology\|mondo" \
    "terminology-ontology-lookup"

  # Test 7: Term hierarchy (tests terminology-ontology-lookup skill)
  run_test "Term children lookup" \
    "Use the ontology-lookup tools to get the children of seizure (HP:0001250) in HPO. Return child term names." \
    "seizure\|motor\|focal\|tonic" \
    "terminology-ontology-lookup"

  echo ""
fi

# ---- Test Suite: Public MCP Servers (one per category) ----
if [ -z "$1" ]; then
  echo "--- Public MCP Servers (aws-public + third-party) ---"
  echo ""

  # Create a separate config with public servers
  PUBLIC_CONFIG=$(mktemp /tmp/hcls-test-public-XXXXXX.json)
  cat > "$PUBLIC_CONFIG" << 'PUBEOF'
{
  "mcpServers": {
    "awsknowledge": {
      "type": "http",
      "url": "https://knowledge-mcp.global.api.aws"
    },
    "open-targets": {
      "type": "http",
      "url": "https://mcp.platform.opentargets.org/mcp"
    }
  }
}
PUBEOF

  # Test: AWS Knowledge (aws-public category)
  TOTAL=$((TOTAL + 1))
  echo -n "  [$TOTAL] AWS Knowledge MCP (aws-public)... "
  set +e
  RESULT=$(claude -p "Use the awsknowledge tools to search for Amazon Bedrock AgentCore documentation. Return the title of one result." \
    --mcp-config "$PUBLIC_CONFIG" \
    --system-prompt "You have access to AWS Knowledge MCP tools. Use them to answer." \
    --allowedTools "mcp__awsknowledge__*" \
    --max-budget-usd 0.25 \
    2>/dev/null)
  local_exit=$?
  set -e
  if echo "$RESULT" | grep -qi "bedrock\|agentcore\|agent\|AWS"; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
  else
    echo -e "${RED}FAIL${NC}"
    echo "       $(echo "$RESULT" | head -2 | cut -c1-120)"
    FAILED=$((FAILED + 1))
  fi

  # Test: Open Targets (third-party category)
  TOTAL=$((TOTAL + 1))
  echo -n "  [$TOTAL] Open Targets MCP (third-party)... "
  set +e
  RESULT=$(claude -p "Use the open-targets tools to search for EGFR. Return the target name." \
    --mcp-config "$PUBLIC_CONFIG" \
    --system-prompt "You have access to Open Targets MCP tools. Use them to answer concisely in one sentence." \
    --allowedTools "mcp__open-targets__*" \
    --max-budget-usd 0.50 \
    2>/dev/null)
  local_exit=$?
  set -e
  if echo "$RESULT" | grep -qi "EGFR\|cancer\|lung\|target\|disease"; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
  else
    echo -e "${RED}FAIL${NC}"
    echo "       $(echo "$RESULT" | head -2 | cut -c1-120)"
    FAILED=$((FAILED + 1))
  fi

  rm -f "$PUBLIC_CONFIG"
  echo ""
fi

# ---- Cleanup and Results ----
rm -f "$MCP_CONFIG"

echo "============================================================"
echo " Results: $PASSED passed, $FAILED failed, $TOTAL total"
echo "============================================================"

if [ $FAILED -gt 0 ]; then
  exit 1
fi
