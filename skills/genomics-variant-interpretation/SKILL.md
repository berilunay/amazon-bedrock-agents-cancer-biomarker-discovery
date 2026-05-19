---
name: genomics-variant-interpretation
description: Use when interpreting genomic variants from VCF files, performing clinical variant classification using ClinVar/VEP annotations, analyzing allele frequencies against population data (1000 Genomes), or generating clinical reports for genetic counseling.
---

# Genomics Variant Interpretation

## When to use this skill

- Interpret variants in specific genes (BRCA1/2, TP53, CYP2D6)
- Classify variant pathogenicity using ClinVar + VEP annotations
- Compare allele frequencies against population databases (1000 Genomes)
- Analyze a patient cohort for pharmacogenomic or cancer-risk variants
- Generate clinical-grade variant reports

## Workflow: Clinical Variant Interpretation

### Step 1: Select the appropriate analysis tool

| User question | Tool | Parameters |
|---------------|------|------------|
| Variants in specific genes | `query_variants_by_gene` | gene_symbols, sample_ids |
| Chromosomal region analysis | `query_variants_by_chromosome` | chromosome, position_range |
| Rare variant discovery | `analyze_allele_frequencies` | frequency_threshold |
| Cohort comparison | `compare_sample_variants` | sample_ids (min 2) |
| Complex/custom questions | `execute_dynamic_genomics_query` | user_question |

### Step 2: Apply quality filtering

All queries automatically enforce:
- `qual > 30` (quality score threshold)
- `PASS` filter status
- Cardinality checks on VEP annotation arrays

These filters ensure only high-confidence variants enter clinical interpretation.

### Step 3: Interpret clinical significance

Classification hierarchy (act on highest applicable):

| ClinVar Significance | VEP Impact | Action |
|---------------------|------------|--------|
| Pathogenic | HIGH | Immediate clinical attention |
| Pathogenic | MODERATE | Clinical attention, confirm with functional data |
| Likely_pathogenic | HIGH | Strong candidate, recommend confirmatory testing |
| Likely_pathogenic | MODERATE | Monitor, include in report |
| Uncertain_significance (VUS) | HIGH | Flag for reassessment, research interest |
| VUS | MODERATE | Monitor, periodic reclassification |
| Benign / Likely_benign | Any | No clinical action |

Priority scoring (used in query results):
```
Pathogenic + HIGH impact = 10
Pathogenic + MODERATE = 9
Likely_pathogenic + HIGH = 8
Likely_pathogenic + MODERATE = 7
VUS + HIGH = 6
HIGH impact (no ClinVar) = 5
VUS + MODERATE = 4
All others = 1
```

### Step 4: Assess population frequency context

Use `analyze_allele_frequencies` with 1000 Genomes data:

| Frequency category | Threshold | Interpretation |
|-------------------|-----------|----------------|
| Very Rare | < 0.001 (0.1%) | Potential novel pathogenic variant |
| Rare | < 0.01 (1%) | Candidate for rare disease |
| Uncommon | < 0.05 (5%) | May be population-specific |
| Common | >= 0.05 | Likely benign polymorphism |

Rule: Pathogenic variants for Mendelian diseases are almost always < 1% frequency.

### Step 5: Generate clinical report

Structure: Patient ID, Gene, Variant (chr:pos:ref>alt), Consequence, Impact, ClinVar significance, Population frequency (1000G AF + rarity category), Associated disease (CLNDN), Clinical interpretation, Recommended follow-up.

## Tool Reference

### query_variants_by_gene
```
Input: gene_symbols ("BRCA1,BRCA2,TP53"), sample_ids (optional), include_frequency (bool)
Output: Variants with VEP annotation, ClinVar significance, priority score
Use for: Targeted gene panels, cancer predisposition, pharmacogenomics
```

### query_variants_by_chromosome
```
Input: chromosome ("17"), sample_ids (optional), position_range ("32000000-33000000")
Output: All PASS variants in region with annotations
Use for: CNV analysis, specific loci investigation, regional patterns
```

### analyze_allele_frequencies
```
Input: sample_ids (optional), frequency_threshold (default 0.01)
Output: Variants with rarity classification, quality tiers, 1000G comparison
Use for: Rare disease analysis, novel variant discovery, population genetics
```

### compare_sample_variants
```
Input: sample_ids ("NA21135,NA21137" -- minimum 2)
Output: Per-sample summary: total variants, pathogenic count, impact distribution, quality metrics
Use for: Family studies, cohort stratification, trio analysis
```

### execute_dynamic_genomics_query
```
Input: user_question (natural language), sample_ids (optional)
Output: Custom SQL generated and executed against HealthOmics stores
Use for: Complex questions not covered by specialized tools
```

## Data Architecture

Variant data lives in AWS HealthOmics stores queried via Athena:
- **Variant Store** (genomicsvariantstore): sample, position, alleles, quality, VEP annotations
- **Annotation Store** (genomicsannotationstore): ClinVar attributes (CLNSIG, CLNDN, GENEINFO)

Stores are joined on: contigname + start + referenceallele + alternatealleles[1]

VEP annotation fields: `symbol`, `impact`, `consequence`, `biotype`, `sift_prediction`, `polyphen_prediction`
ClinVar fields: `CLNSIG`, `CLNDN`, `GENEINFO`, `CLNREVSTAT`, `RS`, `ALLELEID`

## Common Analysis Patterns

| Pattern | Genes | Filter | Action |
|---------|-------|--------|--------|
| Cancer predisposition | BRCA1, BRCA2, TP53, PALB2, CHEK2, ATM | Pathogenic/Likely_pathogenic | Genetic counseling referral |
| Pharmacogenomics | CYP2D6, CYP2C19, CYP2C9, DPYD, TPMT | Functional impact alleles | Medication dosing adjustment |
| Rare disease triage | All (frequency filter) | Very Rare + HIGH + not Benign | Candidate list for clinical review |

## Conventions

- Lead reports with the most actionable finding first
- Include population frequency context for every pathogenic call
- Distinguish germline (inherited) from somatic (tumor) context
- For VUS: note classification may change with new evidence
- Never state a variant is definitively causal without functional evidence
- Include quality metrics (qual, depth) to assess confidence
