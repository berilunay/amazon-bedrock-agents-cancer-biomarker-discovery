# Open Targets MCP Server

Query the Open Targets Platform for gene-disease associations, drug targets, and evidence linking targets to diseases.

## Access

Freely accessible. No API key or authentication required.

## Setup

```json
{
  "mcpServers": {
    "open-targets": {
      "type": "http",
      "url": "https://mcp.platform.opentargets.org/mcp"
    }
  }
}
```

## Capabilities

- Search for target-disease associations with evidence scores
- Look up drug mechanisms of action and indications
- Retrieve genetic and functional genomics evidence
- Access pharmacogenomics and safety data

## Source

Maintained by the [Open Targets](https://platform.opentargets.org/) consortium (EMBL-EBI and Wellcome Sanger Institute).
