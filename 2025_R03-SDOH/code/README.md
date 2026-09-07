# SDOH analysis code

## Current

`pipeline/` and `context/` together form the validated N=709 workflow. There is
exactly one documented entry point:

```bash
bash 2025_R03-SDOH/scripts/run-private-pipeline.sh
```

The pipeline's boundaries and output files are documented in
[`pipeline/README.md`](pipeline/README.md); source-specific geographic methods
are documented in [`context/README.md`](context/README.md).

## Legacy reference only

- `scoring/scoring-mastersheet.Rmd` contains reusable historical scoring blocks
  alongside cross-study measures absent from N=709. It is not a current runner.
  In particular, its Planfulness `Q341_24` attention-check assumption is stale,
  and its positional FEVS sum omits `fevs_1`.
- `ExploratoryFEVS_ECOG.Rmd` and `mk.R` preserve divergent exploratory analyses
  and code associated with older public figures. They are neither canonical nor
  preregistered and should not be rerun as the grant workflow.

These files remain in place to preserve scientific history without creating
path churn. Their status is conspicuously legacy; analysts should not merge
their full gambling workflows into the current analysis master.
