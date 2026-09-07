source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "context", "_context_helpers.R"))
lines <- c(
  "# Crime/disorder source audit",
  "",
  "## Sources evaluated",
  "",
  "- FBI Crime Data Explorer / UCR: authoritative national source, but agency- or jurisdiction-level reporting is not a consistent ZIP/ZCTA exposure and reporting coverage varies by place and year.",
  "- National Neighborhood Data Archive crime products: established academic source, but available releases are generally tract/place/county constructs or derived from heterogeneous local open-data systems; no single contemporary national ZCTA measure with consistent coverage was identified.",
  "- CDC/PLACES and Environmental Justice Index: nationally reproducible small-area contextual resources, but neither supplies a direct crime/disorder rate suitable as the requested construct.",
  "- Commercial neighborhood scores and ranking sites: rejected because methods, vintages, and national reproducibility are opaque.",
  "",
  "## Recommendation",
  "",
  "Do not add a misleading ZIP crime score. If crime/disorder is essential for the grant, Melanie should choose between a county-level FBI/UCR sensitivity exposure (with explicit reporting-coverage diagnostics) and a vetted tract-level academic product after determining whether the loss of geographic/temporal comparability is scientifically acceptable."
)
writeLines(lines, context_file("crime-source-audit.md"))
message("Completed crime/disorder source audit; no defensible national ZIP measure was forced into the pipeline.")
