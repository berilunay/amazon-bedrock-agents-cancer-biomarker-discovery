# Claude Code - HCLS Toolkit Connection Guide

Connect the HCLS MCP servers and skills to Claude Code so you can ask natural biomedical questions without naming servers or tools.

## Prerequisites

- AWS CLI configured with credentials that can read SSM parameters
- Deployed Biomni Gateway and/or OLS Runtime (see `mcp-servers/` for deployment)
- Claude Code installed (`claude` CLI available)

## Quick Setup

### Step 1: Install Skills

Skills teach Claude *which tools to use* for different biomedical questions. Install them first:

```bash
cd /path/to/amazon-bedrock-agents-healthcare-lifesciences

# Copy skills to Claude Code's auto-load directory
cp -r skills/ .claude/skills/
```

### Step 2: Verify Skills Are Installed

```bash
# Check that skill files exist
ls .claude/skills/*/SKILL.md | head -10
```

You should see entries like:
```
.claude/skills/research-biomedical-databases/SKILL.md
.claude/skills/genomics-variant-interpretation/SKILL.md
.claude/skills/terminology-ontology-lookup/SKILL.md
.claude/skills/biomarker-pathway-analysis/SKILL.md
```

You can also verify inside a Claude Code session by asking:

> "What HCLS skills do you have available?"

Claude should list biomedical database research, variant interpretation, ontology lookup, pathway analysis, etc.

### Step 3: Get Authentication Tokens

Tokens expire in 60 minutes. Source these scripts before each session:

```bash
export AWS_PROFILE=<your-profile>
export AWS_REGION=us-west-2

# Biomni Research Tools (30+ biomedical database tools)
source mcp-servers/agentcore-gateway/biomni-research-tools/get-token.sh

# Ontology Lookup Service (OLS terminology search)
source mcp-servers/agentcore-runtime/ontology-lookup-service/get-token.sh
```

### Step 4: Register MCP Servers

```bash
# AgentCore Gateway: Biomni Research (30+ biomedical database tools)
claude mcp add --transport http biomni-research "$BIOMNI_GATEWAY_URL" \
  --header "Authorization: Bearer $BIOMNI_MCP_TOKEN"

# AgentCore Runtime: Ontology Lookup Service (7 terminology tools)
claude mcp add --transport http ontology-lookup "$OLS_MCP_URL" \
  --header "Authorization: Bearer $OLS_MCP_TOKEN"

# AWS Public: AWS Knowledge (no auth required)
claude mcp add --transport http awsknowledge "https://knowledge-mcp.global.api.aws"

# Third-party: Open Targets (no auth required)
claude mcp add --transport http open-targets "https://mcp.platform.opentargets.org/mcp"
```

### Step 5: Start Claude Code and Test

```bash
claude
```

## Testing — One Example Per MCP Server Category

Ask these natural questions. Skills route Claude to the correct tools automatically:

| Category | Example Question | Expected Behavior |
|----------|-----------------|-------------------|
| agentcore-gateway | "Look up human insulin protein and give me the UniProt ID" | Uses Biomni → UniProt tools, returns P01308 |
| agentcore-runtime | "What are the children of seizure (HP:0001250) in HPO?" | Uses OLS → get_term_children, returns seizure subtypes |
| aws-public | "Find AWS documentation about Bedrock AgentCore" | Uses AWS Knowledge tools, returns doc links |
| third-party | "What diseases are associated with EGFR?" | Uses Open Targets tools, returns cancer associations |

You should NOT need to name the MCP server or tool — the skill handles routing.

If Claude asks "which tool should I use?" that means skills aren't loaded. Re-run Step 1 and restart the session.

## Alternative: Configure via `.mcp.json`

Instead of `claude mcp add`, place this in your project root or `~/.claude/.mcp.json`:

```json
{
  "mcpServers": {
    "biomni-research": {
      "type": "http",
      "url": "${BIOMNI_GATEWAY_URL}",
      "headers": {
        "Authorization": "Bearer ${BIOMNI_MCP_TOKEN}"
      }
    },
    "ontology-lookup": {
      "type": "http",
      "url": "${OLS_MCP_URL}",
      "headers": {
        "Authorization": "Bearer ${OLS_MCP_TOKEN}"
      }
    },
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
```

## Token Refresh

Tokens expire after 60 minutes. To refresh mid-session:

```bash
# Re-source tokens
source mcp-servers/agentcore-gateway/biomni-research-tools/get-token.sh
source mcp-servers/agentcore-runtime/ontology-lookup-service/get-token.sh

# Remove and re-add servers with new tokens
claude mcp remove biomni-research
claude mcp add --transport http biomni-research "$BIOMNI_GATEWAY_URL" \
  --header "Authorization: Bearer $BIOMNI_MCP_TOKEN"

claude mcp remove ontology-lookup
claude mcp add --transport http ontology-lookup "$OLS_MCP_URL" \
  --header "Authorization: Bearer $OLS_MCP_TOKEN"
```

## Run Automated Integration Tests

Validates skills + MCP servers work together end-to-end (9 tests across all categories):

```bash
AWS_PROFILE=<your-profile> AWS_REGION=us-west-2 ./tests/test_integration.sh
```

Or test individual server groups:

```bash
./tests/test_integration.sh --biomni    # Biomni Gateway + research skills (4 tests)
./tests/test_integration.sh --ols       # OLS Runtime + terminology skills (3 tests)
```

## Reference

- [AgentCore MCP Server with Claude Code](https://github.com/awslabs/agentcore-samples/tree/main/02-use-cases/claude-code-gateway-mcp-server)
- Tokens are Cognito M2M tokens valid for 60 minutes
- Skills are loaded from `.claude/skills/` automatically on session start
