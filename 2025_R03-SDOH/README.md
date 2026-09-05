# 2025 R03 SDOH

This directory preserves scoring and analysis code, documentation, and aggregate
figures for the SDOH project. Participant-level source and derivative datasets
are maintained privately and are intentionally absent from this public
repository.

## Private analytic inputs

The authoritative analytic source is the reviewed, direct-identifier-free
709-participant dataset maintained outside Git.

- Set `SDOH_SOURCE_DATA` to the private analytic source.
- The source must contain project-specific `study_id`.
- It must not contain Qualtrics `ResponseId`, exact DOB, contact information,
  vendor/panel identifiers, or other direct identifiers.
- Set `SDOH_PRIVATE_DERIVATIVES_DIR` for private row-level scoring outputs.
- Set `SDOH_PRIVATE_MASTER` for private analysis-ready derivatives.
- Set `SDOH_ATTENTION_CHECK_FIELD` only after the appropriate source variable
  has been reviewed and confirmed.

Full current/childhood ZIP and any address-level information needed for GIS
linkage must remain within the controlled private environment.

Participant-level CSV, TSV, Excel, RDS/RData, Parquet, Feather, SAV, DTA,
Qualtrics/REDCap exports, crosswalks, contact data, and row-level scoring outputs
must not be committed to this repository.

Any future public participant dataset requires separate disclosure-risk and
scientific review and should use a random project-specific `study_id`.

## Important scientific issue

`ntb_total` is the total for the **Need to Belong** scale (`ntb_1`–`ntb_10`).
It is not an objective neuropsychological battery score.

See [`docs/privacy-protections.md`](docs/privacy-protections.md).
