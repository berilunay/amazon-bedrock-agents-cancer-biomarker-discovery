# Medidata MCP Server

Access Medidata Solutions' clinical trial data management platform for study design, patient data, and trial analytics.

## Access

Requires a **Medidata Rave account** with appropriate study permissions. OAuth authentication is handled through the MCP connection flow.

## Setup

```json
{
  "mcpServers": {
    "medidata": {
      "type": "http",
      "url": "https://mcp.imedidata.com/mcp"
    }
  }
}
```

## Capabilities

- Access clinical trial data from Medidata Rave EDC
- Query study metrics and enrollment data
- Retrieve site performance and data quality metrics

## Source

Maintained by [Medidata Solutions](https://www.medidata.com/) (a Dassault Systemes company).
