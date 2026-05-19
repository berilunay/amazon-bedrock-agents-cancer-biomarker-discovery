# Cortellis MCP Server

Access Clarivate's regulatory intelligence platform for drug approvals, regulatory filings, and compliance data.

## Access

Requires a **Clarivate Cortellis subscription** and API credentials. Contact Clarivate for access.

## Setup

```json
{
  "mcpServers": {
    "cortellis": {
      "type": "http",
      "url": "https://api.clarivate.com/lifesciences/mcp-regulatory/mcp"
    }
  }
}
```

## Capabilities

- Search regulatory submissions and approval histories
- Track drug approval timelines across global markets
- Access FDA, EMA, and other regulatory agency filings
- Retrieve competitive intelligence on drug programs

## Source

Maintained by [Clarivate](https://clarivate.com/products/cortellis/).
