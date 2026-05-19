# Amazon Quick - HCLS Toolkit Connection Guide

Connect the HCLS MCP servers (Biomni Research Gateway + OLS Runtime) to Amazon Quick.

## Prerequisites

- Amazon Quick installed
- AWS CLI configured (for token generation)
- Deployed Biomni Gateway and/or OLS Runtime (see `mcp-servers/` for deployment)

## 1. Get Authentication Tokens

Tokens expire in 60 minutes. Run before configuring:

```bash
# Biomni Research Tools
source mcp-servers/agentcore-gateway/biomni-research-tools/get-token.sh

# Ontology Lookup Service
source mcp-servers/agentcore-runtime/ontology-lookup-service/get-token.sh
```

## 2. Add MCP Servers

1. Open Amazon Quick
2. Go to **Settings > Capabilities > Add MCP Server**
3. Add each server:

| Server | Transport | URL | Authorization Header |
|--------|-----------|-----|---------------------|
| Biomni Research | HTTP | `$BIOMNI_GATEWAY_URL` | `Bearer $BIOMNI_MCP_TOKEN` |
| Ontology Lookup | HTTP | `$OLS_MCP_URL` | `Bearer $OLS_MCP_TOKEN` |
| AWS Knowledge | HTTP | `https://knowledge-mcp.global.api.aws` | (none) |
| PubMed | HTTP | `https://pubmed.mcp.claude.com/mcp` | (none) |
| Open Targets | HTTP | `https://mcp.platform.opentargets.org/mcp` | (none) |

For stdio-based servers:

| Server | Command |
|--------|---------|
| AWS HealthOmics | `uvx awslabs.aws-healthomics-mcp-server@latest` |

## 3. Skills Limitation

Skills (structured workflow guidance) are not directly supported in Amazon Quick yet. The MCP tools themselves provide the core biomedical research functionality. For skill-guided workflows, use Claude Code or Kiro instead.

## Token Refresh

Tokens expire after 60 minutes. To refresh:

1. Re-run the `get-token.sh` script for the expired server
2. Update the Authorization header in **Settings > Capabilities** with the new token

## Reference

- Public MCP servers (AWS Knowledge, PubMed, Open Targets) require no authentication
- Biomni and OLS tokens are Cognito M2M tokens valid for 60 minutes
