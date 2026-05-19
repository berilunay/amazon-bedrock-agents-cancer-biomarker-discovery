# Wiley Scholar Gateway MCP Server

Search and access academic literature across Wiley's journal portfolio via the Scholar Gateway AI connector.

## Access

Requires a **Wiley institutional or personal subscription** for full-text access. Abstract search may be available without authentication.

## Setup

```json
{
  "mcpServers": {
    "wiley": {
      "type": "http",
      "url": "https://connector.scholargateway.ai/mcp"
    }
  }
}
```

## Capabilities

- Search Wiley's academic journal catalog
- Retrieve article abstracts and metadata
- Access full-text content (subscription-dependent)

## Source

Maintained by [Wiley](https://www.wiley.com/) via [Scholar Gateway](https://scholargateway.ai/).
