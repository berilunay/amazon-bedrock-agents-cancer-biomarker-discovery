---
name: biomarker-multi-agent-discovery
description: Use when orchestrating a multi-agent biomarker discovery workflow that requires coordinating database queries, pathway analysis, literature review, statistical modeling, and clinical evidence synthesis to produce ranked biomarker panels.
---

# Biomarker Multi-Agent Discovery

## When to use this skill

- Complex biomarker discovery requiring multiple analysis modalities
- Coordinating database queries with statistical survival analysis
- Synthesizing findings from literature, pathways, and clinical data into a biomarker panel
- Questions that span multiple sub-domains (e.g., "find best biomarker for survival in chemo patients and show evidence")

## Architecture: Agents-as-Tools Pattern

The orchestrator dispatches to specialized sub-agents, each wrapped as a tool:

```
Orchestrator (Supervisor)
  |-- biomarker_database_analyst_agent  -> SQL queries on clinical genomic data
  |-- clinical_evidence_research_agent  -> PubMed + Knowledge Base search
  |-- statistician_agent                -> Survival regression, Kaplan-Meier plots
  |-- medical_imaging_agent             -> Radiomics biomarker extraction
```

Cross-agent data sharing uses AgentCore Memory: the database agent stores query results, and downstream agents (statistician) retrieve them automatically.

## Orchestration Workflow

### Step 1: Classify the user query

Map the question to required sub-agents:

| Query type | Agents needed | Sequence |
|-----------|---------------|----------|
| Demographics / counts | Database analyst only | Single call |
| Literature evidence | Clinical evidence researcher only | Single call |
| Statistical analysis (p-values, survival) | Database analyst -> Statistician | Sequential |
| Imaging biomarkers | Database analyst -> Medical imaging | Sequential |
| Comprehensive discovery | All agents | Multi-step |
| Pathway interpretation | Database analyst -> Literature | Sequential |

### Step 2: Execute database queries first

For any analysis requiring patient data:

1. Call `biomarker_database_analyst_agent` with the data retrieval question
2. Results are automatically stored in shared memory
3. Include required columns: survival_status, survival_duration, biomarker expression values

Example dispatch:
```
Query: "What are the top 5 biomarkers with overall survival for chemo patients?"
-> Database agent: "Query all records including survival status, survival duration in years, and gene expression values for patients where chemotherapy = 'Yes'"
```

### Step 3: Feed results to downstream agents

**For statistical analysis:**
```
-> Statistician agent: "Fit a survival regression model on the query results"
```
The statistician retrieves data from memory automatically. No S3 path needed.

**For visualization:**
```
-> Statistician agent: "Generate a bar chart of the top 5 biomarkers by p-value"
-> Statistician agent: "Plot Kaplan-Meier curve for GDF15 with threshold 10"
```

**For literature validation:**
```
-> Clinical evidence researcher: "Search PubMed for evidence on GDF15 as a biomarker in NSCLC"
```

### Step 4: Synthesize findings into ranked biomarker panel

Combine outputs from all agents into a consolidated report:

```
Biomarker Panel Report
=====================
1. [Gene] - p-value: X, HR: Y
   - Pathway: [from pathway analysis]
   - Literature: [N publications supporting]
   - Clinical significance: [interpretation]

2. [Gene] - p-value: X, HR: Y
   ...
```

Ranking criteria (in priority order):
1. Statistical significance (lowest p-value from Cox regression)
2. Clinical significance (hazard ratio magnitude)
3. Pathway relevance (membership in disease-associated pathways)
4. Literature support (number of supporting publications)
5. Biological plausibility (protein function matches disease mechanism)

### Step 5: Generate actionable recommendations

For each top biomarker, provide:
- Measurement method (IHC, RNA-seq, blood test)
- Patient stratification threshold (expression cutoff)
- Potential clinical utility (prognostic vs. predictive vs. diagnostic)
- Next validation steps (cohort size, assay development)

## Tool Dispatch Reference

| Agent | Tools | Input | Output |
|-------|-------|-------|--------|
| Database Analyst | get_schema, query_redshift, refine_sql | Data question | Query results (auto-stored in memory) |
| Clinical Evidence | query_pubmed, retrieve | Evidence question | Literature summary with citations |
| Statistician | run_code, plot_kaplan_meier, fit_survival_regression | Analysis request | Regression, charts (S3 paths), p-values |
| Medical Imaging | compute_imaging_biomarker, analyze_imaging_biomarker | Patient IDs | Radiomics features (sphericity, elongation) |

## Example Multi-Step Sequences

**"Find best biomarker for survival in chemo patients with visualization":**
1. Database agent -> Statistician (Cox regression) -> Statistician (Kaplan-Meier) -> Literature -> Synthesize

**"Compare imaging biomarkers for patients with lowest GDF15":**
1. Database agent (find patients) -> Medical imaging (compute + visualize) -> Synthesize

## Conventions

- Always explain the multi-step plan to the user before executing
- Present results from each agent separately, then provide consolidated summary
- Include S3 paths for any generated charts or images
- When agents fail, explain which step failed and what alternatives exist
- Medical/statistical concepts must be explained in accessible language
- Memory events expire after 3 days -- no manual cleanup needed
