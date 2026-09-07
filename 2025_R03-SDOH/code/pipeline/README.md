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
3. `code/context/00`–`10` — public-source preparation, ZIP/ZCTA linkage,
   SDI, Social Capital Atlas, ACS Gini, PM2.5, RUCA, source audit, context
   master, exposure correlations, and validation;
4. `03_build_analysis_master.R` — one private analysis-ready master without ZIP;
5. `04_validate_scores.R` — score ranges, coverage, and scoring-integrity checks;
6. `05_rerun_prior_model_screen.R` — formula-driven historical screen rerun;
7. `06_grant_candidate_analyses.R` — 216 fixed Family A–G specifications and
   labeled sensitivities;
8. `07_generate_figure_candidates.R` — 11 systematic private draft figures;
9. `08_build_review_packet.R` — balanced results audit, opportunity review,
   candidate findings, and Melanie's private review packet.

All row-level data, current results, and current figures are written below
`private-data/derived/`, which is ignored by Git. The scripts do not apply a
new participant exclusion.

## Optional environment variables

- `SDOH_SOURCE_DATA`: authoritative workbook path. If unset, the shell entry
  point uses `private-data/QualtricsData_SDOH_DEIDENTIFIED.xlsx`.
- `SDOH_PRIVATE_DERIVATIVES_DIR`: private output directory.
- `SDOH_CONTEXT_PYTHON`: Python executable containing `geopandas`, `rasterio`,
  `xarray`, `netCDF4`, `exactextract`, `pandas`, and `numpy`. By default the
  PM2.5 script checks ignored `private-data/reference/.venv-context/bin/python`
  and prints this exact requirement if it is absent.

## Scientific boundaries

All core scoring questions are resolved. OAFEM uses the explicit 30-item map
and published severity hierarchy; PROMIS-29 Profile v2.0 uses official domain
T-score tables; CTB maps all 24 allocation choices to 1–6; fraud distinguishes
lifetime from past-12-month loss. Context and current results remain
preliminary and cross-sectional, and current ZIP is a coarse exposure proxy.
