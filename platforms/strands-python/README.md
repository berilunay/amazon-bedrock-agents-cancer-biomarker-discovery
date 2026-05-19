# Strands Agents (Python) - HCLS Toolkit Connection Guide

Connect the HCLS MCP servers (Biomni Research Gateway + OLS Runtime) programmatically via Strands Agents in Python.

## Prerequisites

```bash
pip install strands-agents strands-agents-tools boto3
```

## 1. Get Tokens Programmatically

```python
import boto3
import requests

def get_cognito_token(app_name: str, region: str = "us-west-2") -> tuple[str, str]:
    """Fetch Cognito M2M token and MCP URL from SSM parameters."""
    ssm = boto3.client("ssm", region_name=region)

    def get_param(key):
        return ssm.get_parameter(Name=f"/app/{app_name}/agentcore/{key}")["Parameter"]["Value"]

    gateway_url = get_param("gateway_url") if "biomni" in app_name else get_param("mcp_url")
    client_id = get_param("machine_client_id")
    client_secret = get_param("cognito_secret")
    cognito_domain = get_param("cognito_domain").replace("https://", "")
    auth_scope = get_param("cognito_auth_scope")

    resp = requests.post(
        f"https://{cognito_domain}/oauth2/token",
        data={
            "grant_type": "client_credentials",
            "client_id": client_id,
            "client_secret": client_secret,
            "scope": auth_scope,
        },
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )
    token = resp.json()["access_token"]
    return gateway_url, token
```

## 2. Connect MCP Servers with Strands Agent

```python
from strands import Agent
from strands.tools.mcp import MCPClient
from mcp.client.streamable_http import streamablehttp_client

# Get tokens (expire in 60 minutes)
biomni_url, biomni_token = get_cognito_token("biomni-research-tools")
ols_url, ols_token = get_cognito_token("ontology-lookup-service")

# Create MCP clients
biomni_client = MCPClient(
    lambda: streamablehttp_client(
        url=biomni_url,
        headers={"Authorization": f"Bearer {biomni_token}"},
    )
)

ols_client = MCPClient(
    lambda: streamablehttp_client(
        url=ols_url,
        headers={"Authorization": f"Bearer {ols_token}"},
    )
)

# Create agent with both tool sets
with biomni_client, ols_client:
    agent = Agent(
        model="us.anthropic.claude-sonnet-4-20250514",
        tools=[*biomni_client.list_tools(), *ols_client.list_tools()],
        system_prompt="You are a biomedical research assistant with access to 30+ databases.",
    )
    response = agent("Find clinical trials for KRAS G12C inhibitors in NSCLC")
    print(response)
```

## 3. Token Refresh Pattern

For long-running applications, refresh tokens before they expire:

```python
import time

class TokenManager:
    def __init__(self, app_name: str, region: str = "us-west-2"):
        self.app_name = app_name
        self.region = region
        self._token = None
        self._url = None
        self._expires_at = 0

    def get_token(self) -> tuple[str, str]:
        if time.time() > self._expires_at - 300:  # refresh 5 min before expiry
            self._url, self._token = get_cognito_token(self.app_name, self.region)
            self._expires_at = time.time() + 3600  # 60 min
        return self._url, self._token
```

## 4. Shell-Based Token (Alternative)

If you prefer using the existing shell scripts:

```bash
source mcp-servers/agentcore-gateway/biomni-research-tools/get-token.sh
source mcp-servers/agentcore-runtime/ontology-lookup-service/get-token.sh
python my_agent.py
```

Then in Python, read from environment:

```python
import os

biomni_url = os.environ["BIOMNI_GATEWAY_URL"]
biomni_token = os.environ["BIOMNI_MCP_TOKEN"]
ols_url = os.environ["OLS_MCP_URL"]
ols_token = os.environ["OLS_MCP_TOKEN"]
```

## Reference

- [Strands Agents MCP documentation](https://strandsagents.com/latest/user-guide/concepts/tools/mcp-tools/)
- Tokens are Cognito M2M tokens valid for 60 minutes
