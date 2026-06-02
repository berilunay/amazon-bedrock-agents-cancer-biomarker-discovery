# bioRxiv MCP Server

Search and retrieve preprint articles from bioRxiv and medRxiv via deepsense.ai's hosted MCP endpoint.

## Access

Freely accessible. No API key or authentication required.

## Setup

```json
{
  "mcpServers": {
    "biorxiv": {
      "type": "http",
      "url": "https://mcp.deepsense.ai/biorxiv/mcp"
    }
  }
}
```

## Capabilities

- Search preprints by keyword, author, or subject area
- Retrieve abstracts and metadata for biology and medicine preprints
- Filter by date range and category

## Source

bioRxiv/medRxiv data from Cold Spring Harbor Laboratory, hosted by [deepsense.ai](https://deepsense.ai/).
