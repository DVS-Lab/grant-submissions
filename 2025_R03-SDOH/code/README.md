# SDOH analysis code

The scripts in this directory preserve earlier scoring and exploratory work for
reuse. They are not a single validated analysis pipeline for the reviewed N=709
source.

## `scoring/scoring-mastersheet.Rmd`

This is a prior scoring implementation, privacy-hardened to read the reviewed
private source and write row-level derivatives outside Git. It contains useful
scoring logic as well as legacy and non-core measures. It is not complete or
current for every grant-relevant measure. A future N=709 pipeline must verify
the core measure definitions, item mappings, missing-data handling, and output
fields before relying on these blocks.

## `ExploratoryFEVS_ECOG.Rmd`

This is a prior exploratory analysis of FEVS, eCog, demographic, and social
variables. It reads a private analysis-ready master and contains code associated
with the existing exploratory figures. Its models and plots can be recycled,
but it is exploratory rather than a canonical or preregistered analysis set.

## `mk.R`

This is a near-duplicate but divergent version of
`ExploratoryFEVS_ECOG.Rmd`; neither file is a subset or superset of the other.
They share most data preparation, demographic comparisons, and interaction
models, but `mk.R` includes model blocks absent from the R Markdown file, while
the R Markdown file includes its own duplicated comparison block, document
structure, package differences, and a different loneliness interaction model.
Both are retained because consolidation would require deciding which divergent
blocks are authoritative.
