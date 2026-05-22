# Third-Party MCP Servers

Public MCP servers from life sciences tool providers. These require no deployment — configure them in your AI assistant to get immediate access to biomedical databases, literature, and domain tools.

## Available Servers

| Server | Provider | Auth | What it provides |
|--------|----------|------|------------------|
| [pubmed](pubmed/) | U.S. National Library of Medicine | Free | Biomedical literature search (35M+ articles) |
| [open-targets](open-targets/) | Open Targets | Free | Gene-disease associations, drug targets, evidence |
| [chembl](chembl/) | deepsense.ai | Free | Chemical compound data, bioactivity, drug-likeness |
| [clinical-trials](clinical-trials/) | deepsense.ai | Free | ClinicalTrials.gov search and filtering |
| [biorxiv](biorxiv/) | deepsense.ai | Free | Preprint biology/medicine literature |
| [synapse](synapse/) | Sage Bionetworks | Account | Collaborative research data platform |
| [biorender](biorender/) | BioRender | Subscription | Scientific figure and diagram creation |
| [consensus](consensus/) | Consensus | Free* | Evidence-based answers from research papers |
| [cortellis](cortellis/) | Clarivate | Subscription | Regulatory intelligence, drug approvals |
| [adisinsight](adisinsight/) | Springer Nature | Subscription | Drug development pipeline intelligence |
| [medidata](medidata/) | Medidata Solutions | Account | Clinical trial data management |
| [wiley](wiley/) | Wiley | Subscription | Academic literature (Scholar Gateway) |
| [owkin](owkin/) | Owkin | Account | AI-powered biomarker discovery |
| [10x-genomics](10x-genomics/) | 10x Genomics | Free | Single-cell and spatial genomics (local binary) |
| [tooluniverse](tooluniverse/) | MIMS Harvard | Free | Bioinformatics tool discovery (local binary) |

*Free for basic use; premium features may require an account.

## Configuration

Each server folder contains a `.mcp.json` file. To use a server, add its config to your assistant:

**Claude Code** — merge into your project's `.mcp.json` or reference the file  
**Kiro** — add to `.kiro/settings/mcp.json`  
**Amazon Quick** — Settings → Capabilities → Add MCP Server → paste the URL  
**Cursor** — add to `.cursor/mcp.json`

## Source

These servers are sourced from the [Anthropic Life Sciences](https://github.com/anthropics/life-sciences) plugin marketplace. They are independently maintained by their respective providers.
