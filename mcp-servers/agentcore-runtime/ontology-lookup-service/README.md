# Ontology Lookup Service - AgentCore Runtime MCP Server

7 ontology tools deployed as an MCP endpoint via Amazon Bedrock AgentCore Runtime, providing access to 200+ biomedical ontologies (MONDO, ChEBI, HPO, GO, SNOMED, EFO, DOID, and more) through the EBI Ontology Lookup Service.

## Tools Available

| Tool | What it does |
|------|-------------|
| `search_terms` | Search across 200+ ontologies for terms matching a query |
| `get_ontology_info` | Get metadata about a specific ontology (name, description, version, term count) |
| `search_ontologies` | Search available ontologies by keyword |
| `get_term_info` | Get full details for a specific term (label, description, synonyms, xrefs) |
| `get_term_children` | Get immediate children of a term in the ontology hierarchy |
| `get_term_ancestors` | Get all ancestors of a term up to the root |
| `find_similar_terms` | Find semantically similar terms across ontologies |

### Example Queries

- "Search for diabetes-related terms in MONDO"
- "Get details for HP:0001250 (seizures)"
- "Find children of CHEBI:23367 (molecular entity)"
- "What ontologies cover cardiovascular diseases?"
- "Find terms similar to 'myocardial infarction' across all ontologies"

## Architecture

```
Client (Claude Code / Kiro / Python)
    |
    | HTTPS + JWT token
    v
AgentCore Runtime (MCP protocol, streamable-http)
    |
    | HTTP
    v
EBI OLS4 API (https://www.ebi.ac.uk/ols4/)
    |
    v
200+ Ontologies (MONDO, HPO, GO, ChEBI, SNOMED, EFO, DOID, ...)
```

The server runs as a containerized MCP endpoint on AgentCore Runtime. It wraps the open-source [ols-mcp-server](https://github.com/seandavi/ols-mcp-server) with patches for AgentCore compatibility (stateless HTTP mode).

## Prerequisites

| Requirement | Details |
|-------------|---------|
| AWS CLI | Configured with appropriate credentials |
| Python 3.12+ | With `uv` package manager |
| git | For cloning OLS source |
| @aws/agentcore CLI | `npm install -g @aws/agentcore` |
| Docker | Running (for container build) |
| AWS Account | Permissions: CloudFormation, Cognito, IAM, ECR, Bedrock AgentCore |
| Region | `us-east-1` or `us-west-2` (AgentCore availability) |

## Deployment

The deployment creates: Cognito authentication stack, clones and patches OLS MCP server, then configures and launches to AgentCore Runtime.

### Quick Start

```bash
cd mcp-servers/agentcore-runtime/ontology-lookup-service

# Install CLI
npm install -g @aws/agentcore
pip install uv

# Deploy (default AppName: ontology-lookup-service)
./deploy.sh
```

### Custom App Name

```bash
./deploy.sh my-ols-server
```

### What the Deploy Script Does

1. Deploys Cognito stack (`cfn/cognito.yaml`) for OAuth2 M2M authentication
2. Clones OLS MCP server from `https://github.com/seandavi/ols-mcp-server.git`
3. Patches `server.py` for AgentCore Runtime (stateless HTTP + streamable-http transport)
4. Generates pinned `requirements.txt` with FastMCP 2.x constraint
5. Scaffolds an `@aws/agentcore` project with BYO agent (protocol=MCP, CUSTOM_JWT auth)
6. Deploys container to AgentCore Runtime via `agentcore deploy`
7. Stores endpoint URL in SSM Parameter Store

### SSM Parameters Created

| Parameter | Description |
|-----------|-------------|
| `/app/ontology-lookup-service/agentcore/mcp_url` | MCP endpoint URL |
| `/app/ontology-lookup-service/agentcore/agent_arn` | Agent ARN |
| `/app/ontology-lookup-service/agentcore/agent_id` | Agent ID |
| `/app/ontology-lookup-service/agentcore/machine_client_id` | Cognito client ID |
| `/app/ontology-lookup-service/agentcore/cognito_secret` | Cognito client secret |
| `/app/ontology-lookup-service/agentcore/cognito_domain` | Cognito domain |
| `/app/ontology-lookup-service/agentcore/cognito_auth_scope` | OAuth2 scope |
| `/app/ontology-lookup-service/agentcore/cognito_discovery_url` | OIDC discovery URL |

## Connecting to Your AI Assistant

### Step 1: Get an access token

```bash
source get-token.sh
# Sets: OLS_MCP_TOKEN, OLS_MCP_URL
```

### Step 2: Connect your platform

#### Claude Code

```bash
claude mcp add --transport http \
  --header "Authorization: Bearer $OLS_MCP_TOKEN" \
  ontology-lookup "$OLS_MCP_URL"
```

Or add to `.mcp.json`:

```json
{
  "mcpServers": {
    "ontology-lookup": {
      "type": "http",
      "url": "<OLS_MCP_URL>",
      "headers": {
        "Authorization": "Bearer ${OLS_MCP_TOKEN}"
      }
    }
  }
}
```

#### Kiro

Add to your project `mcp.json`:

```json
{
  "mcpServers": {
    "ontology-lookup": {
      "transportType": "http",
      "url": "<OLS_MCP_URL>",
      "headers": {
        "Authorization": "Bearer ${OLS_MCP_TOKEN}"
      }
    }
  }
}
```

#### Amazon Q Desktop

1. Open **Settings > Capabilities**
2. Add MCP server: type `HTTP`, URL = your MCP URL, add Authorization header

#### Programmatic (Python with Strands)

```python
from strands import Agent
from strands.mcp import MCPClient
from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client

mcp_client = MCPClient(
    lambda: streamablehttp_client(url="<OLS_MCP_URL>")
)

agent = Agent(tools=[mcp_client])
agent("What are the children of HP:0001250 in HPO?")
```

## File Structure

```
ontology-lookup-service/
  deploy.sh           # Main deployment script
  get-token.sh        # Cognito token retrieval (source this)
  patch_ols.py        # Patches OLS server.py for AgentCore
  cfn/
    cognito.yaml      # Cognito User Pool + M2M client
  README.md           # This file
```

## Cleanup

```bash
# Delete Cognito stack
aws cloudformation delete-stack --stack-name ontology-lookup-service-cognito

# Delete AgentCore Runtime agent (via SDK or console)
# The agent name is: ols_mcp_server

# Delete SSM parameters
aws ssm delete-parameters --names \
  "/app/ontology-lookup-service/agentcore/mcp_url" \
  "/app/ontology-lookup-service/agentcore/agent_arn" \
  "/app/ontology-lookup-service/agentcore/agent_id" \
  "/app/ontology-lookup-service/agentcore/machine_client_id" \
  "/app/ontology-lookup-service/agentcore/cognito_secret" \
  "/app/ontology-lookup-service/agentcore/userpool_id" \
  "/app/ontology-lookup-service/agentcore/cognito_domain" \
  "/app/ontology-lookup-service/agentcore/cognito_auth_scope" \
  "/app/ontology-lookup-service/agentcore/cognito_discovery_url" \
  "/app/ontology-lookup-service/agentcore/cognito_token_url"
```

## Source

- OLS MCP Server: [github.com/seandavi/ols-mcp-server](https://github.com/seandavi/ols-mcp-server)
- EBI OLS4 API: [www.ebi.ac.uk/ols4](https://www.ebi.ac.uk/ols4/)
- Reference deployment script: [`agents_catalog/35-Terminology-agent/deploy_ols_mcp_server.py`](../../../agents_catalog/35-Terminology-agent/deploy_ols_mcp_server.py)
