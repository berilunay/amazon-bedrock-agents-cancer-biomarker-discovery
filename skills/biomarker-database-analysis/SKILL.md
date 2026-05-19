---
name: biomarker-database-analysis
description: Use when a researcher needs to query biomedical databases for biomarker discovery, build target profiles from UniProt/Open Targets/STRING, rank biomarker candidates by evidence strength, or generate SQL queries against clinical genomic databases.
---

# Biomarker Database Analysis

## When to use this skill

- Researcher asks to find biomarkers associated with a disease or cancer type
- Query clinical genomic databases for survival, gene expression, or mutation data
- Build protein/target profiles from biomedical databases
- Rank biomarker candidates by statistical evidence (p-value, effect size)
- Generate or optimize SQL for biomarker data retrieval

## MCP Servers Used

- **`biomni-research`** — for external biomedical database queries (UniProt, Open Targets, STRING, ClinVar)
- Clinical genomic databases may use separate tools (Redshift/Athena) depending on deployment

## Workflow: Query Clinical Genomic Database

### Step 1: Understand the schema before querying

Always retrieve the database schema first to understand available tables and columns.

```
Tool: get_schema
Purpose: Retrieve table names, column names, data types, and descriptions
```

Key columns in a typical clinical genomic table:
- `case_id` -- patient identifier
- `survival_status` -- alive/dead (boolean or 0/1)
- `survival_duration` -- time in days or years
- Gene expression columns (e.g., `gdf15`, `lrig1`, `cdh2`, `postn`, `vcan`)
- Clinical metadata: `age_at_histological_diagnosis`, `smoking_status`, `chemotherapy`, `histology`

### Step 2: Formulate and refine the SQL query

Decision tree for query type:
- **Patient demographics** -> Simple SELECT with WHERE/GROUP BY
- **Biomarker expression** -> SELECT gene columns with clinical filters
- **Survival correlation** -> SELECT survival_status, survival_duration, biomarker columns
- **Cohort comparison** -> GROUP BY with aggregation (COUNT, AVG)

Rules:
1. Write queries as single lines (no newlines)
2. Never modify column names from the schema
3. Use aggregation (COUNT, AVG, GROUP BY) to reduce output size
4. Always validate with `refine_sql` before execution

```
Tool: refine_sql
Input: sql (the query), question (rationale for this step -- not the user's original question)
Purpose: Optimize for efficiency, add aggregation, fix column references
```

### Step 3: Execute and interpret results

```
Tool: query_redshift (or query_database)
Input: The refined SQL query
Output: Row-level results from the clinical database
```

### Step 4: Build target profiles from external databases

For deeper biomarker validation, use the `biomni-research` MCP server with natural language queries:

| Database | Query approach |
|----------|---------------|
| UniProt | "CDK4 protein function, domains, post-translational modifications" |
| Open Targets | "CDK4 disease associations and genetic evidence scores" |
| STRING | "CDK4 protein-protein interaction network" |
| ClinVar | "CDK4 pathogenic variants and clinical significance" |

### Step 5: Rank candidates by evidence strength

Scoring framework for biomarker prioritization:

| Evidence type | Weight | Source |
|---------------|--------|--------|
| Statistical significance (p < 0.05) | High | Cox regression from clinical data |
| Known pathogenic association | High | ClinVar, Open Targets |
| Protein interaction in disease network | Medium | STRING (confidence > 0.7) |
| Literature support (3+ publications) | Medium | PubMed |
| Gene expression differential | Medium | Clinical database |
| Functional annotation match | Low | UniProt |

## Query Patterns

**Find top biomarkers for survival:**
```sql
SELECT survival_status, survival_duration, gdf15, lrig1, cdh2, postn, vcan FROM clinical_genomic WHERE chemotherapy = 'Yes'
```

**Cohort demographics:**
```sql
SELECT smoking_status, COUNT(DISTINCT case_id) AS num_patients FROM clinical_genomic WHERE age_at_histological_diagnosis > 50 GROUP BY smoking_status
```

**Disease-specific expression:**
```sql
SELECT survival_status, COUNT(*) AS count FROM clinical_genomic WHERE histology = 'Adenocarcinoma' GROUP BY survival_status
```

## Key Conventions

- Map survival_status: `False/Alive = 0`, `True/Dead = 1`
- Expression values are continuous (higher = more expressed in tumor)
- Always include quality filters and use parameterized queries when available
- Store query results in shared memory for downstream agents (statistician, pathway analyst)
- When results exceed 100 rows, summarize with aggregation before presenting to user
