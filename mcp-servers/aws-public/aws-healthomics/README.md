# AWS HealthOmics MCP Server

Local MCP server providing 60+ tools for managing AWS HealthOmics workflows, runs, sequence stores, and reference stores.

## Prerequisites

- AWS credentials configured (`aws configure`)
- [uv](https://astral.sh/uv) installed: `curl -LsSf https://astral.sh/uv/install.sh | sh`

## Setup

```json
{
  "mcpServers": {
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

Optionally create `.healthomics/config.toml` with `omics_iam_role`, `run_output_uri`, and `run_storage_type`.

## Capabilities

- Workflow management (create, version, lint WDL/CWL/Nextflow)
- Run execution, monitoring, and performance analysis
- Sequence and reference store management
- ECR container and Git integration via CodeConnections

## Source

- Package: [awslabs.aws-healthomics-mcp-server](https://pypi.org/project/awslabs.aws-healthomics-mcp-server/)
- Guide: [sample-healthomics-agentic-setup](https://github.com/aws-samples/sample-healthomics-agentic-setup)
