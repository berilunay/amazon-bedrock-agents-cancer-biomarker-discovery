# AWS MCP Server

Local stdio proxy to the AWS MCP server providing authenticated access to 300+ AWS services, documentation search, and sandboxed script execution.

## Prerequisites

- AWS credentials configured (`aws configure`)
- [uv](https://astral.sh/uv) installed: `curl -LsSf https://astral.sh/uv/install.sh | sh`

## Setup

```json
{
  "mcpServers": {
    "aws-mcp": {
      "command": "uvx",
      "args": ["mcp-proxy-for-aws@latest", "https://aws-mcp.us-east-1.api.aws/mcp"]
    }
  }
}
```

## Capabilities

- `search_documentation` -- search AWS docs (no auth required)
- `retrieve_skill` -- discover and load AWS skills on demand
- `call_aws` -- authenticated access to 300+ AWS services
- `run_script` -- sandboxed Python script execution

## HCLS Use Cases

Deploy CloudFormation stacks, create/invoke Lambda functions, query Athena, manage S3 buckets, and configure IAM roles for agent infrastructure.

## Source

Part of the [AWS Agent Toolkit](https://github.com/aws/agent-toolkit-for-aws) (aws-core plugin).
