---
name: research-biomedical-databases
description: Use when a developer needs to query biomedical databases (UniProt, ClinVar, gnomAD, PDB, Reactome, Open Targets, etc.) via the Biomni Research Tools MCP server. Covers protein lookup, variant interpretation, pathway analysis, drug-target associations, and genomic annotation queries.
---

# Research Biomedical Databases

## When to use this skill

- Developer asks "how do I query UniProt/ClinVar/gnomAD/PDB from my agent?"
- Developer wants to look up protein information, variant significance, or pathway data
- Developer needs to combine multiple database queries for a research workflow
- Developer asks about the Biomni Gateway tools or biomedical database access

## Prerequisites

The Biomni Research Tools MCP server must be deployed and configured. See `mcp-servers/agentcore-gateway/biomni-research-tools/README.md` for deployment.

Quick setup (after deployment):

```bash
cd mcp-servers/agentcore-gateway/biomni-research-tools
source get-token.sh
claude mcp add --transport http biomni-research "$BIOMNI_GATEWAY_URL" --header "Authorization: Bearer $BIOMNI_MCP_TOKEN"
```

## MCP Server: `biomni-research`

This server provides 30 tools covering biomedical databases. Tools are discovered automatically via the MCP protocol — use `tools/list` or the built-in discovery tool to find the right one for your query.

### Database Coverage

| Category | Databases | Use when you need |
|----------|-----------|-------------------|
| Protein & Structure | UniProt, AlphaFold, InterPro, PDB, STRING, PRIDE, EMDB | Protein function, 3D structure, domains, interactions |
| Genomic Variants | ClinVar, gnomAD, dbSNP, Ensembl, UCSC, GWAS Catalog, RegulomeDB | Variant significance, population frequencies, gene models |
| Pathways & Targets | Reactome, Open Targets, Monarch, GtoPdb, OpenFDA, ClinicalTrials | Pathways, drug-target links, pharmacology, trials |
| Cancer & Expression | cBioPortal, GEO | Tumor mutations, gene expression datasets |
| Specialized | JASPAR, MPD, Synapse, WoRMS, Paleobiology | TF motifs, mouse phenotypes, shared datasets |

### Discovery Tool

The server includes a discovery tool that returns a subset of tools matching a keyword context. Use it when you're unsure which specific tool to call:

```
"Search for tools related to protein structure prediction"
```

## Query Patterns

All database tools accept a `prompt` parameter with a natural language query. The system translates it to the appropriate API call. Some tools also accept an `endpoint` parameter for direct API access.

### Single Database Query

Ask naturally — Claude will discover and call the appropriate tool from the `biomni-research` server:

```
"Find human insulin receptor protein, include GO annotations"
→ Calls the UniProt tool with prompt parameter

"What pathogenic variants exist for BRCA1?"
→ Calls the ClinVar tool with prompt parameter

"Show me the insulin signaling pathway"
→ Calls the Reactome tool with prompt parameter
```

### Multi-Database Workflow: Variant Interpretation

1. **Identify variant**: Query ClinVar for "BRCA1 c.5266dupC pathogenic variants"
2. **Check frequency**: Query gnomAD for "BRCA1 5382insC allele frequency"
3. **Get protein impact**: Query UniProt for "BRCA1 protein domains and functional sites"
4. **Check structure**: Query AlphaFold with uniprot_id "P38398"
5. **Find pathways**: Query Reactome for "BRCA1 DNA repair pathways"

### Multi-Database Workflow: Drug Target Analysis

1. **Find target-disease link**: Query Open Targets for "CDK4 associations with breast cancer"
2. **Get target biology**: Query UniProt for "CDK4 function and interactions"
3. **Check interactions**: Query STRING for "CDK4 protein interaction network"
4. **Find compounds**: Query GtoPdb for "CDK4 inhibitors and ligands"
5. **Check trials**: Query ClinicalTrials for "CDK4 inhibitor phase 3 breast cancer"

### Multi-Database Workflow: Gene Expression & Phenotype

1. **Find expression data**: Query GEO for "TP53 expression in hepatocellular carcinoma"
2. **Check phenotypes**: Query Monarch for "TP53 loss of function phenotypes"
3. **Cancer mutations**: Query cBioPortal for "TP53 mutations in liver cancer"
4. **Regulatory elements**: Query RegulomeDB for "regulatory variants near TP53 promoter"

## Tips

- Queries are natural language — be specific about organism (human/mouse), gene name, and what information you need
- Use `max_results` parameter to limit response size when exploring
- Chain queries: start broad (identify the entity) → go deep (get specific data)
- For variant interpretation, always check both ClinVar (clinical) AND gnomAD (population frequency)
- For drug targets, combine Open Targets (evidence) + STRING (network) + GtoPdb (pharmacology)

## Error Handling

- If a tool returns empty results, try alternative gene names or identifiers (HGNC symbol vs. Ensembl ID)
- Rate limits may apply on some databases — space queries if you hit 429 errors
- Some databases (gnomAD, GWAS Catalog) work better with specific variant IDs than gene names
