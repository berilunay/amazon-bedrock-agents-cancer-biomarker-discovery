# Clinical Trials MCP Server

Search and filter ClinicalTrials.gov data for active, completed, and recruiting trials via deepsense.ai's hosted MCP endpoint.

## Access

Freely accessible. No API key or authentication required.

## Setup

```json
{
  "mcpServers": {
    "clinical-trials": {
      "type": "http",
      "url": "https://mcp.deepsense.ai/clinical_trials/mcp"
    }
  }
}
```

## Capabilities

- Search clinical trials by condition, intervention, or sponsor
- Filter by phase, status, location, and date range
- Retrieve study design, endpoints, and enrollment data
- Access results and outcome measures for completed trials

## Source

ClinicalTrials.gov data, hosted by [deepsense.ai](https://deepsense.ai/).
