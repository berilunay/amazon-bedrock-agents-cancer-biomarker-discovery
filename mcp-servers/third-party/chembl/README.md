# ChEMBL MCP Server

Access ChEMBL chemical compound data, bioactivity measurements, and drug-likeness information via deepsense.ai's hosted MCP endpoint.

## Access

Freely accessible. No API key or authentication required.

## Setup

```json
{
  "mcpServers": {
    "chembl": {
      "type": "http",
      "url": "https://mcp.deepsense.ai/chembl/mcp"
    }
  }
}
```

## Capabilities

- Search compounds by name, structure, or properties
- Retrieve bioactivity data (IC50, EC50, Ki values)
- Look up drug-likeness and ADMET properties
- Access target and assay information

## Source

ChEMBL data from EMBL-EBI, hosted by [deepsense.ai](https://deepsense.ai/).
