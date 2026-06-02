# 10x Genomics MCP Server

Access 10x Genomics tools for single-cell and spatial genomics analysis via a locally-run MCP bundle binary.

## Access

Freely accessible. No API key required. The MCPB binary is downloaded from GitHub releases.

## Setup

```json
{
  "mcpServers": {
    "10x-genomics": "https://github.com/10XGenomics/txg-mcp/releases/latest/download/txg-node.mcpb"
  }
}
```

## Prerequisites

- Node.js runtime (for the MCPB binary execution)
- The binary is automatically downloaded and cached on first use

## Capabilities

- Single-cell RNA-seq analysis guidance
- Spatial transcriptomics data interpretation
- Cell Ranger and Space Ranger workflow assistance
- 10x Genomics product and protocol documentation

## Source

Maintained by [10x Genomics](https://www.10xgenomics.com/). Repository: [10XGenomics/txg-mcp](https://github.com/10XGenomics/txg-mcp).
