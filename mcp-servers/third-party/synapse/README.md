# Synapse MCP Server

Access Sage Bionetworks' Synapse platform for collaborative research data management, sharing, and analysis.

## Access

Requires a **Synapse account**. Register free at [synapse.org](https://www.synapse.org/). OAuth authentication is handled through the MCP connection flow.

## Setup

```json
{
  "mcpServers": {
    "synapse": {
      "type": "http",
      "url": "https://mcp.synapse.org/mcp"
    }
  }
}
```

## Capabilities

- Browse and search shared research datasets
- Access project files, annotations, and provenance
- Query tables and views within Synapse projects

## Source

Maintained by [Sage Bionetworks](https://sagebionetworks.org/).
