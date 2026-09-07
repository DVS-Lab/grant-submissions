# SDOH output map

All paths are relative to `2025_R03-SDOH/`. “Rebuildable” means reproducible from the one XLSX plus the public repository and internet access.

## Public outputs

| Path | Producer | Purpose | Share? | Inspect? | Rebuildable? |
|---|---|---|---:|---:|---:|
| `config/reproducibility-sources.json` | maintained config | Fixed public-source versions/checksums | Yes | Yes | No—source of truth |
| `config/reproduction-contract.json` | maintained config | Safe aggregate expected structure | Yes | Yes | No—reviewed contract |
| `docs/analysis-master-dictionary.csv` | maintained metadata | Documents all 91 master columns | Yes | Yes | No—reviewed metadata |
| `derivatives/model-screening/*.csv` | historical workflow | Aggregate formulas/coefficients used as public references | Yes | As needed | No—preserved history |

## Private inputs

| Path | Producer | Purpose | Share? | Inspect? | Rebuildable? |
|---|---|---|---:|---:|---:|
| `private-data/QualtricsData_SDOH_DEIDENTIFIED.xlsx` | controlled handoff | Sole authoritative participant input | No/publicly | Yes, controlled | No |

## Private intermediate files

| Path | Producer | Purpose | Share? | Inspect? | Rebuildable? |
|---|---|---|---:|---:|---:|
| `private-data/derived/zip-validation-private.csv` | `context/01` | Private ZIP validity audit | No | If debugging | Yes |
| `private-data/derived/zip-zcta-linkage-private.csv` | `context/02` | Private ZIP/ZCTA linkage | No | If validating GIS | Yes |
| `private-data/derived/context-*.csv` | `context/03`–`10` | Linked components and coverage checks | No | If validating GIS | Yes |
| `private-data/derived/pm25-zcta-annual.csv` | PM2.5 Python helper | Annual ZCTA values used for summary | No | For PM2.5 validation | Yes |
| `private-data/derived/core-scores.csv` | `pipeline/02` | Row-level derived scores | No | For scoring validation | Yes |

## Private final analyst outputs

| Path | Producer | Purpose | Share? | Inspect? | Rebuildable? |
|---|---|---|---:|---:|---:|
| `private-data/derived/analysis-master.csv` | `pipeline/03` | Geography-free 709×91 analytic master | No | Yes | Yes |
| `private-data/derived/melanie-review-packet.md` | `pipeline/08` | Primary scientific-review entry point | No | Yes—first | Yes |
| `private-data/derived/grant-results-audit.md` | `pipeline/08` | Balanced result/warning audit | No | Yes | Yes |
| `private-data/derived/grant-candidate-findings.md` | `pipeline/08` | Candidate statements and nulls | No | Yes | Yes |
| `private-data/derived/grant-candidate-results.csv` | `pipeline/06` | Full fixed-framework model output | No | Yes | Yes |
| `private-data/derived/model-screen-rerun.csv` and `model-screen-comparison.csv` | `pipeline/05` | Historical formula reproduction/comparison | No | As needed | Yes |
| `private-data/derived/context-correlation.csv` and `.png` | `context/09` | Exposure redundancy audit | No | Yes | Yes |
| `private-data/derived/figure-index.md` and `figures/*.png` | `pipeline/07` | Eleven private draft figures and metadata | No | Yes | Yes |
| `private-data/derived/reproduction-check.md` | verifier | PASS/WARNING/FAIL against public contract | No | Yes—first | Yes |
| `private-data/derived/run-provenance.json` | `pipeline/09` | Private source/code/environment identity | No | Yes when comparing runs | Yes |

## Rebuildable cache

| Path | Producer | Purpose | Share? | Inspect? | Rebuildable? |
|---|---|---|---:|---:|---:|
| `private-data/reference/.venv-context/` | runner | Isolated pinned Python environment | No need | No | Yes |
| `private-data/reference/.r-library/`, `.r-bootstrap/`, `.renv-cache/` | R bootstrap | Isolated locked R environment/cache | No need | No | Yes |
| `private-data/reference/pm25/` | PM2.5 helper | Eleven checksummed ACAG grids | Public-origin but do not hand off | No | Yes |
| `private-data/reference/cb_2020_*.zip` and tabular sources | context preparation | Checksummed fixed-vintage national data | Public-origin but do not hand off | If debugging | Yes |

Preview safe cache removal with `bash scripts/clean-private-cache.sh --dry-run`. The script never targets private inputs or `private-data/derived/`.
