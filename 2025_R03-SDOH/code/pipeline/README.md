# Current N=709 private pipeline

This directory contains the current reproducible workflow for the reviewed
private SDOH source. The only analyst entry point is:

```bash
bash 2025_R03-SDOH/scripts/run-private-pipeline.sh
```

The shell entry point verifies the privacy boundary, discovers the documented
local workbook (or honors `SDOH_SOURCE_DATA`), and runs these scripts in order:

1. `01_validate_source.R` — schema, key, structure, and privacy checks;
2. `02_score_core_measures.R` — justified item recoding and core scores;
3. `03_build_analysis_master.R` — one private analysis-ready master;
4. `04_validate_scores.R` — range, missingness, and agreement checks;
5. `04b_audit_context_linkage.R` — evidence-based linkage status;
6. `05_rerun_prior_model_screen.R` — formula-driven historical screen rerun;
7. `06_grant_candidate_analyses.R` — fixed grant-question framework;
8. `07_generate_figure_candidates.R` — systematic private draft figures.

All row-level data, current results, and current figures are written below
`private-data/derived/`, which is ignored by Git. The scripts do not apply a
new participant exclusion.

## Optional environment variables

- `SDOH_SOURCE_DATA`: authoritative workbook path. If unset, the shell entry
  point uses `private-data/QualtricsData_SDOH_DEIDENTIFIED.xlsx`.
- `SDOH_PRIVATE_DERIVATIVES_DIR`: private output directory.
- `SDOH_CONTEXT_DATA`: reviewed private context linkage keyed by `study_id`.
- `SDOH_CONTEXT_VARIABLE`: primary reviewed contextual exposure used by the
  fixed context models.

## Scientific boundaries

FEVS, eCog, 7 Up 7 Down/SUSD, UCLA loneliness, MSPSS, and Need to Belong
scoring are implemented with explicit response maps. PROMIS raw domain sums
are implemented, but T-scores await confirmation of the administered version.
OAFEM responses are recoded, but the workbook's generic item names cannot be
aligned reliably to published severity weights; the emitted unweighted
complete-case score is a diagnostic marked for scientific review.
