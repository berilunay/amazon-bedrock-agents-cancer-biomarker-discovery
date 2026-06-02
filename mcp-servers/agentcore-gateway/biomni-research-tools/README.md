# Biomni Research Tools — AgentCore Gateway MCP Server

35 biomedical database and literature tools deployed as an MCP endpoint via Amazon Bedrock AgentCore Gateway.

## Tools Available

### Database Tools (28)

| Tool | Database | What you can query |
|------|----------|-------------------|
| `query_uniprot` | UniProt | Protein sequences, functions, annotations |
| `query_alphafold` | AlphaFold DB | Protein structure predictions |
| `query_interpro` | InterPro | Protein families, domains, functional sites |
| `query_pdb` | RCSB PDB | 3D macromolecular structures |
| `query_pdb_identifiers` | RCSB PDB | Detailed data/downloads for specific PDB IDs |
| `query_stringdb` | STRING | Protein-protein interactions |
| `query_clinvar` | ClinVar | Genetic variant clinical significance |
| `query_gnomad` | gnomAD | Population variant frequencies |
| `query_ensembl` | Ensembl | Genomic annotations, gene models |
| `query_ucsc` | UCSC Genome Browser | Genomic regions, tracks, annotations |
| `query_dbsnp` | dbSNP | Single nucleotide polymorphisms |
| `query_geo` | GEO | Gene expression datasets |
| `query_gwas_catalog` | GWAS Catalog | Genome-wide association study results |
| `query_reactome` | Reactome | Biological pathways |
| `query_opentarget` | Open Targets | Drug target–disease associations |
| `query_monarch` | Monarch Initiative | Gene–phenotype–disease relationships |
| `query_cbioportal` | cBioPortal | Cancer genomics datasets |
| `query_openfda` | OpenFDA | Drug/device/food safety reports |
| `query_clinicaltrials` | ClinicalTrials.gov | Clinical study registrations |
| `query_regulomedb` | RegulomeDB | Regulatory variant annotations |
| `query_pride` | PRIDE | Proteomics identifications |
| `query_gtopdb` | GtoPdb | Pharmacological targets and ligands |
| `query_mpd` | Mouse Phenome DB | Mouse strain phenotype data |
| `query_emdb` | EMDB | Electron microscopy structures |
| `query_synapse` | Synapse | Biomedical datasets (Sage Bionetworks) |
| `query_jaspar` | JASPAR | Transcription factor binding profiles |
| `query_worms` | WoRMS | Marine species taxonomy |
| `query_paleobiology` | PBDB | Paleobiology fossil records |

### Literature Tools (7)

| Tool | What it does |
|------|-------------|
| `query_pubmed` | Search PubMed for papers |
| `query_arxiv` | Search arXiv preprints |
| `query_scholar` | Search Google Scholar |
| `search_google` | General web search |
| `extract_url_content` | Extract text from a webpage |
| `extract_pdf_content` | Extract text from a PDF URL |
| `fetch_supplementary_info_from_doi` | Fetch supplementary data for a paper by DOI |

All tools accept natural language queries and automatically construct the appropriate API calls.

## Prerequisites

| Requirement | Details |
|-------------|---------|
| AWS CLI | Configured with appropriate credentials |
| Python 3.12+ | With `uv` package manager |
| AWS Account | Permissions: CloudFormation, Lambda, Cognito, S3, IAM, AgentCore |
| Region | `us-east-1` or `us-west-2` (AgentCore availability) |

## Deployment

The deployment creates: S3 bucket → Lambda functions (database + literature) → Cognito authentication → AgentCore Gateway endpoint.

### Step 1: Clone and install dependencies

```bash
cd agents_catalog/28-Research-agent-biomni-gateway-tools
uv sync
```

### Step 2: Run the prerequisite deployment

```bash
./scripts/prereq.sh [BUCKET_NAME] [INFRA_STACK] [COGNITO_STACK] [AGENTCORE_STACK]
```

Defaults: `researchapp`, `researchappStackInfra`, `researchappStackCognito`, `researchappStackAgentCore`

This script:
1. Creates an S3 bucket (`{name}-{region}-{account_id}`)
2. Zips Lambda function code (database + literature handlers)
3. Uploads Lambda zips and API specs to S3
4. Deploys 3 CloudFormation stacks sequentially:
   - **Infrastructure** — Lambda functions, IAM roles, API Gateway
   - **Cognito** — User pool, app client, resource server for OAuth2
   - **AgentCore** — Gateway configuration with Lambda targets

### Step 3: Create the AgentCore Gateway

```bash
python scripts/agentcore_gateway.py create --name researchapp-gw
```

### Step 4: Retrieve your MCP endpoint

```bash
aws ssm get-parameter \
  --name /app/researchapp/agentcore/gateway_url \
  --query Parameter.Value --output text
```

## Connecting to Your AI Assistant

### Claude Code / Cursor

Add to your project `.mcp.json` or `~/.claude/.mcp.json`:

```json
{
  "mcpServers": {
    "biomni-research": {
      "type": "http",
      "url": "<GATEWAY_URL_FROM_STEP_4>"
    }
  }
}
```

### Kiro

Add to your project `mcp.json`:

```json
{
  "mcpServers": {
    "biomni-research": {
      "transportType": "http",
      "url": "<GATEWAY_URL_FROM_STEP_4>"
    }
  }
}
```

### Amazon Quick

1. Open **Settings → Capabilities**
2. Add MCP server: type `HTTP`, URL = your Gateway URL

### Programmatic (Python)

```python
from strands import Agent
from strands.mcp import MCPClient
from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client

mcp_client = MCPClient(
    lambda: streamablehttp_client(url="<GATEWAY_URL>")
)

agent = Agent(tools=[mcp_client])
agent("What proteins interact with BRCA1?")
```

## Authentication

The Gateway uses Cognito OAuth2 (client credentials grant). For AI coding assistants that support MCP natively, the Gateway URL works directly. For programmatic access:

```bash
# Get Cognito details
POOL_ID=$(aws ssm get-parameter --name /app/researchapp/cognito/user_pool_id --query Parameter.Value --output text)
CLIENT_ID=$(aws ssm get-parameter --name /app/researchapp/cognito/client_id --query Parameter.Value --output text)
CLIENT_SECRET=$(aws secretsmanager get-secret-value --secret-id /app/researchapp/cognito/client_secret --query SecretString --output text)

# Get OAuth2 token
TOKEN=$(curl -s -X POST "https://<cognito-domain>/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&scope=researchapp/read researchapp/write" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
```

## Verification

After deployment, test the endpoint:

```bash
python tests/test_gateway.py --prompt "What proteins interact with TP53?"
```

## Cleanup

```bash
aws cloudformation delete-stack --stack-name researchappStackAgentCore
aws cloudformation delete-stack --stack-name researchappStackCognito
aws cloudformation delete-stack --stack-name researchappStackInfra
```

## Source

Full agent implementation: [`agents_catalog/28-Research-agent-biomni-gateway-tools/`](../../../agents_catalog/28-Research-agent-biomni-gateway-tools/)
