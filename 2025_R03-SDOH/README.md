# 2025 R03 SDOH

This directory preserves scoring and analysis code, documentation, and aggregate
figures for the SDOH project. Participant-level source and derivative datasets are
maintained privately and are intentionally absent from this public repository.

## Private inputs

- Set `SDOH_SOURCE_DATA` to the private local analytic source before running the
  scoring notebook.
- Set `SDOH_PRIVATE_DERIVATIVES_DIR` to the private output directory if the
  default ignored `private-data/derived` location is not appropriate.
- Set `SDOH_ATTENTION_CHECK_FIELD` to the reviewed source column whose passing
  value is `3`; the original notebook did not document its name.
- Set `SDOH_PRIVATE_MASTER` before running the exploratory analysis scripts.

Do not place Qualtrics exports, exact DOB, addresses, full ZIPs, contact data,
panel/vendor IDs, crosswalks, or row-level scoring outputs in this repository.
The eventual public participant dataset requires a separate disclosure-risk and
scientific review; it should use an arbitrary project-specific `study_id`, not a
Qualtrics `ResponseId`.

## Important scientific issue

`ntb_total` is the total for the **Need to Belong** scale (`ntb_1`–`ntb_10`). It
is not an objective neuropsychological battery score. Existing analyses are
preserved unchanged, but this interpretation must be corrected during analytic
review before reporting results.

See [`docs/privacy-protections.md`](docs/privacy-protections.md) for a summary of
how public repository files are handled to protect participant privacy.
