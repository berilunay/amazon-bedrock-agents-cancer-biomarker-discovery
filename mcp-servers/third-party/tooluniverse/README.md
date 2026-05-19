# ToolUniverse MCP Server

Discover and use bioinformatics tools from Harvard MIMS Lab's ToolUniverse collection, covering genomics, proteomics, and computational biology workflows.

## Access

Freely accessible. No API key required. The MCPB binary is downloaded from GitHub releases.

## Setup

```json
{
  "mcpServers": {
    "tooluniverse": "https://github.com/MIMS-Harvard/ToolUniverse/releases/latest/download/tooluniverse.mcpb"
  }
}
```

## Prerequisites

- Node.js runtime (for the MCPB binary execution)
- The binary is automatically downloaded and cached on first use

## Capabilities

- Discover bioinformatics tools by task description
- Get usage instructions and parameter guidance for tools
- Access curated tool recommendations for common workflows

## Source

Maintained by [Harvard MIMS Lab](https://mims.hms.harvard.edu/). Repository: [MIMS-Harvard/ToolUniverse](https://github.com/MIMS-Harvard/ToolUniverse).
