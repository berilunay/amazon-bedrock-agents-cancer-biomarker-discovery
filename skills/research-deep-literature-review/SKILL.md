---
name: research-deep-literature-review
description: Use when a developer needs to conduct systematic literature searches, find research papers, extract content from publications, or build evidence summaries from biomedical databases and web sources via the Biomni Research Tools MCP server.
---

# Deep Literature Review

## When to use this skill

- Developer asks "find papers about X" or "what's the latest research on Y?"
- Developer needs to build an evidence summary from multiple publications
- Developer wants to extract specific data from a paper or PDF
- Developer needs to search across biomedical literature and databases
- Developer asks about systematic literature review workflows

## MCP Server: `biomni-research`

This server provides tools for biomedical database queries including literature-related functionality. Tools are discovered automatically via the MCP protocol.

Quick setup (after deployment):

```bash
cd mcp-servers/agentcore-gateway/biomni-research-tools
source get-token.sh
claude mcp add --transport http biomni-research "$BIOMNI_GATEWAY_URL" --header "Authorization: Bearer $BIOMNI_MCP_TOKEN"
```

## Search Strategy

### Choosing the Right Approach

| Research Type | Query approach (via biomni-research) |
|---------------|--------------------------------------|
| Clinical evidence (trials, outcomes) | Query ClinicalTrials database |
| Variant significance | Query ClinVar + gnomAD |
| Drug safety / regulatory | Query OpenFDA |
| Protein biology | Query UniProt + InterPro |
| Cancer genomics | Query cBioPortal + GEO |
| Pathway mechanisms | Query Reactome + Open Targets |

### Effective Query Construction

All tools accept natural language prompts. Be specific:

```
"Find pathogenic BRCA1 variants associated with breast cancer"
"EGFR T790M resistance mutation frequency in Asian populations"
"CDK4/6 inhibitors clinical trials phase 3 breast cancer"
"TP53 expression in hepatocellular carcinoma datasets"
```

## Literature Review Workflows

### Workflow 1: Rapid Evidence Summary

Goal: Quickly assess the state of evidence on a topic.

1. **Broad database search**: Query relevant databases for the topic
2. **Cross-reference**: Check multiple databases for consistency
3. **Extract details**: Use PDF extraction tool for full-text papers
4. **Synthesize**: Combine database evidence with extracted findings

### Workflow 2: Competitive Intelligence (Drug Development)

1. **Find clinical trials**: Query ClinicalTrials for "drug/target phase 2 phase 3 results"
2. **Check target biology**: Query Open Targets + UniProt for target validation
3. **Regulatory context**: Query OpenFDA for drug safety signals
4. **Extract details**: Use PDF extraction for advisory briefing documents

### Workflow 3: Systematic Literature Search

1. **Define PICO**: Population, Intervention, Comparison, Outcome
2. **Multi-database search**: Query ClinVar + ClinicalTrials + Open Targets
3. **Cross-reference**: Compare findings across databases for consistency
4. **Validate**: Check population frequencies (gnomAD) for genomic findings

### Workflow 4: Technology Landscape

1. **Foundational biology**: Query UniProt + Reactome for mechanism
2. **Clinical translation**: Query ClinicalTrials for applications
3. **Cancer data**: Query cBioPortal for mutation/expression profiles
4. **Regulatory status**: Query OpenFDA for approved therapies

## Tips

- **Be specific with organisms**: Always specify "human" to avoid cross-species results
- **Use standard identifiers**: Gene symbols (BRCA1), UniProt IDs (P38398), RS numbers (rs80357906)
- **Start broad, narrow down**: First query identifies the entity → follow-up gets specific data
- **Cross-validate**: If a finding appears across multiple database tools, it's more reliable
- **Extract strategically**: Only use PDF extraction when you need methods details or specific data points

## Combining with Other Skills

Literature review is most powerful when combined with other database queries:

1. **Find variant**: Query ClinVar for "EGFR T790M pathogenic"
2. **Check frequency**: Query gnomAD for "EGFR T790M population frequency"
3. **Check pathways**: Query Reactome for "EGFR signaling cascade"
4. **Find trials**: Query ClinicalTrials for "EGFR T790M osimertinib"

This multi-database feedback loop produces comprehensive evidence packages.
