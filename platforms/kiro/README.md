# Kiro - HCLS Toolkit Connection Guide

Connect the HCLS MCP servers (Biomni Research Gateway + OLS Runtime) and skills to Kiro.

## Prerequisites

- AWS CLI configured with credentials that can read SSM parameters
- Node.js (for `mcp-proxy-for-aws` stdio wrapper)
- Deployed Biomni Gateway and/or OLS Runtime (see `mcp-servers/` for deployment)

## 1. MCP Server Configuration

Add to your project's `.kiro/settings/mcp.json` file. For authenticated servers, use `mcp-proxy-for-aws` as a stdio wrapper which handles Cognito token refresh automatically:

```json
{
  "mcpServers": {
    "biomni-research": {
      "command": "npx",
      "args": [
        "mcp-proxy-for-aws@latest",
        "--endpoint", "YOUR_BIOMNI_GATEWAY_URL",
        "--ssm-prefix", "/app/biomni-research-tools/agentcore"
      ]
    },
    "ontology-lookup": {
      "command": "npx",
      "args": [
        "mcp-proxy-for-aws@latest",
        "--endpoint", "YOUR_OLS_MCP_URL",
        "--ssm-prefix", "/app/ontology-lookup-service/agentcore"
      ]
    },
    "awsknowledge": {
      "type": "http",
      "url": "https://knowledge-mcp.global.api.aws"
    },
    "aws-healthomics": {
      "command": "uvx",
      "args": ["awslabs.aws-healthomics-mcp-server@latest"],
      "env": {
        "HEALTHOMICS_DEFAULT_MAX_RESULTS": "100"
      }
    }
  }
}
```

### Alternative: Direct HTTP with Manual Token

If you prefer direct HTTP transport (requires manual token refresh every 60 minutes):

```json
{
  "mcpServers": {
    "biomni-research": {
      "transportType": "http",
      "url": "YOUR_BIOMNI_GATEWAY_URL",
      "headers": {
        "Authorization": "Bearer YOUR_TOKEN_HERE"
      }
    }
  }
}
```

Get the token with:

```bash
source mcp-servers/agentcore-gateway/biomni-research-tools/get-token.sh
echo $BIOMNI_MCP_TOKEN
```

## 2. Install Skills as Steering Files

```bash
cp -r platforms/kiro/steering/ .kiro/steering/
cp platforms/kiro/POWER.md .kiro/POWER.md
```

## 3. Token Management

The `mcp-proxy-for-aws` wrapper handles token refresh transparently. If using direct HTTP transport, tokens expire in 60 minutes and you must update the config manually.

## Reference

- [AWS Agent Toolkit pattern](https://github.com/aws/agent-toolkit-for-aws)
- Existing Kiro Power for agent development: `powers/hcls-agentcore-builder/`
