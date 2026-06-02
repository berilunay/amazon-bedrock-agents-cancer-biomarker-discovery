# AWS Public MCP Servers

Existing AWS-published MCP servers that HCLS skills reference for infrastructure and service operations. No deployment needed — configure them in your AI assistant.

## Available Servers

| Server | Transport | AWS Creds | What it provides |
|--------|-----------|-----------|------------------|
| [aws-healthomics](aws-healthomics/) | stdio (local) | Required | 60+ HealthOmics workflow/run/store management tools |
| [aws-knowledge](aws-knowledge/) | HTTP (remote) | None | AWS documentation search and architecture guidance |
| [agentcore-docs](agentcore-docs/) | stdio (local) | None | AgentCore API reference and documentation |
| [strands-docs](strands-docs/) | stdio (local) | None | Strands Agents SDK documentation |
| [aws-mcp](aws-mcp/) | stdio (local) | Required | 300+ AWS service operations (IAM, S3, Lambda, Athena, etc.) |

## Prerequisites

All local (stdio) servers require:
- [uv](https://astral.sh/uv) installed: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- AWS credentials for servers that make AWS API calls

Remote (HTTP) servers require no local installation.

## How HCLS Skills Use These

HCLS skills define domain workflows. When those workflows need AWS infrastructure actions, the skill directs the AI assistant to the appropriate AWS MCP server:

| Domain action | AWS MCP server |
|---------------|---------------|
| Run genomics workflows | aws-healthomics |
| Query data in S3/Athena | aws-mcp |
| Deploy agent infrastructure | aws-mcp + agentcore-docs |
| Look up AWS best practices | aws-knowledge |
| Build with Strands framework | strands-docs |
