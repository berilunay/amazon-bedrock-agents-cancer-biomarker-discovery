# PubMed MCP Server

Search and retrieve biomedical literature from PubMed's 35M+ article database maintained by the U.S. National Library of Medicine.

## Access

Freely accessible. No API key or authentication required.

## Setup

```json
{
  "mcpServers": {
    "pubmed": {
      "type": "http",
      "url": "https://pubmed.mcp.claude.com/mcp"
    }
  }
}
```

## Capabilities

- Search PubMed articles by keyword, author, journal, date range
- Retrieve abstracts and metadata
- Access MeSH term-based filtering

## Source

Hosted by Anthropic as part of the Claude Life Sciences plugin marketplace.
