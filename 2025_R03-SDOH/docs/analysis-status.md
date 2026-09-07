# SDOH analysis status

## Authoritative private source

The authoritative participant-level source is the reviewed N=709 file supplied
through controlled private storage. It uses `study_id` as the join key and is
not stored in Git. Current and childhood ZIPs also remain private. No
participant-level data belong in this public repository.

## Existing reusable work

- `code/scoring/scoring-mastersheet.Rmd` preserves prior, privacy-hardened
  scoring blocks.
- `code/ExploratoryFEVS_ECOG.Rmd` and `code/mk.R` preserve related but divergent
  exploratory FEVS/eCog, demographic, and social analyses.
- `derivatives/figures/` contains four prior exploratory figures.
- `docs/analytic-variable-dictionary.csv` is a partial, legacy public
  dictionary. It is not a complete description of the N=709 analytic source.

No aggregate FEVS/OAFEM model-screen CSVs or generator script were located in
the repository during this cleanup.

## What can be recycled

- Scoring blocks after their measure definitions and item mappings are verified.
- Prior FEVS, eCog, loneliness, demographic, and social model and plotting code.
- Prior model formulas embedded in the exploratory scripts.
- Existing contextual-variable names used by the exploratory work.

## Major incomplete items

- Build one validated N=709 scoring pipeline.
- Verify and complete OAFEM scoring.
- Implement and verify PROMIS and health scoring.
- Transparently regenerate every grant-relevant derived variable.
- Build reproducible current-ZIP contextual linkage with source and vintage
  documented.
- Locate or recreate auditable generator code for the prior model screen.
- Rerun candidate models with the clean N=709 source.
- Produce grant-ready figures and results.

## Privacy and data-release status

The row-level N=709 source remains private. A candidate public-use dataset is
future work, not an existing repository artifact. Full ZIP must not be included
in a public-use dataset, and any participant-level release requires a formal
disclosure-risk review before publication.
