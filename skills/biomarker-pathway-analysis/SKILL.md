---
name: biomarker-pathway-analysis
description: Use when a researcher needs to analyze biological pathways for biomarker discovery, map disease mechanisms to druggable targets using Reactome/KEGG, identify pathway enrichment from gene sets, or understand mechanism-of-action for candidate biomarkers.
---

# Biomarker Pathway Analysis

## When to use this skill

- Researcher asks which pathways a gene/biomarker belongs to
- Identify druggable targets within a disease pathway
- Map metagene clusters to biological mechanisms
- Understand mechanism-of-action for candidate biomarkers
- Perform pathway enrichment analysis on a gene set

## MCP Server: `biomni-research`

Pathway analysis uses the `biomni-research` MCP server. Tools are discovered automatically — ask your question naturally and Claude will find the right tool.

## Workflow: Pathway-Based Biomarker Discovery

### Step 1: Identify the gene set of interest

Sources for gene sets:
- Output from `biomarker-database-analysis` (top genes by p-value)
- Known cancer driver genes (e.g., EGFR, KRAS, TP53, BRCA1/2)
- Metagene clusters from expression analysis
- Differentially expressed genes from cohort comparison

### Step 2: Query pathway databases

Use the `biomni-research` server with natural language queries:

| Goal | Query approach |
|------|---------------|
| Find pathways for a gene | "EGFR signaling pathways in Reactome" |
| Find disease pathways | "pathways involved in non-small cell lung cancer" |
| Get pathway interactions | "protein interaction network for CDK4" via STRING |
| Validate drug targets | "CDK4 drug target tractability" via Open Targets |
| Cross-reference function | "CDK4 molecular function and biological process" via UniProt |

### Step 3: Map pathway hierarchy

Reactome organizes pathways hierarchically. Navigate from broad to specific:

```
Top-level: Signal Transduction
  -> RAS signaling
    -> KRAS activation
      -> Downstream effectors (RAF, MEK, ERK)
```

Decision tree for pathway depth:
- **Broad overview needed** -> Query top-level pathways only
- **Mechanism-of-action** -> Drill into sub-pathways with specific reactions
- **Drug target identification** -> Find terminal nodes with known inhibitors

### Step 4: Identify druggable targets in pathway

For each pathway hit, assess druggability:

1. Query Open Targets for tractability assessment:
   - Small molecule tractable
   - Antibody tractable
   - Other modalities (PROTAC, gene therapy)

2. Check existing drugs:
   - Approved drugs targeting this pathway node
   - Clinical trial compounds (Phase I-III)
   - Tool compounds for validation

3. Prioritize by:
   - Distance from disease-associated node (closer = better)
   - Number of approved drugs (validated target)
   - Safety profile of existing modulators

### Step 5: Build pathway-to-biomarker rationale

Connect pathway findings back to biomarker candidates:

```
Gene (biomarker candidate)
  -> Pathway membership (Reactome)
    -> Disease relevance (pathway implicated in condition)
      -> Mechanistic explanation (how gene contributes to disease)
        -> Clinical utility (can measure this to stratify patients)
```

## Pathway Analysis Patterns

**EGFR pathway in NSCLC:**
- Query: EGFR, KRAS, ALK, ROS1, BRAF, MET, HER2, RET
- Pathways: RTK signaling, RAS-MAPK, PI3K-AKT-mTOR
- Biomarker implication: Mutation status predicts TKI response

**Metagene cluster interpretation:**
- Cluster of co-expressed genes -> query each for pathway membership
- Identify shared pathways -> that pathway drives the co-expression
- Example: GDF15, POSTN, VCAN cluster -> TGF-beta / extracellular matrix remodeling

**Survival-associated pathway enrichment:**
1. Take top 10 genes by Cox regression p-value
2. Query Reactome for each gene
3. Count pathway overlaps (enrichment)
4. Pathways with 3+ genes = significantly enriched

## Decision Framework: When to Use Pathway Analysis

| Scenario | Recommended approach |
|----------|---------------------|
| Single gene of interest | Query Reactome + UniProt for function context |
| Gene panel (5-20 genes) | Pathway enrichment: find shared pathways |
| Drug target validation | Open Targets tractability + existing drugs |
| Mechanism explanation | Full pathway walk: gene -> pathway -> disease |
| Novel biomarker discovery | Combine pathway + expression + survival data |

## Conventions

- Always report pathway evidence level (curated vs. inferred)
- Include Reactome stable IDs (R-HSA-xxxxx) for reproducibility
- For STRING interactions, use confidence threshold >= 0.7 (high confidence)
- When multiple pathways match, rank by: disease relevance > gene count > evidence level
- Cross-reference pathway findings with literature (PubMed) for validation
