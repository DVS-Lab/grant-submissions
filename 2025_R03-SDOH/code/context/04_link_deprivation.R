source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "context", "_context_helpers.R"))
link <- read_context_csv("zip-zcta-linkage-private.csv")
path <- file.path(reference_dir(), "rgcsdi-2015-2019-zcta.csv")
sdi <- utils::read.csv(path, colClasses = "character", check.names = FALSE)
require_columns(sdi, c("ZCTA5_FIPS", "SDI_score"), "RGC SDI ZCTA file")
sdi$ZCTA5_FIPS <- normalize_zip(sdi$ZCTA5_FIPS)
sdi$SDI_score <- suppressWarnings(as.numeric(sdi$SDI_score))
out <- data.frame(study_id = link$study_id, sdi_zcta = sdi$SDI_score[match(link$zcta_current, sdi$ZCTA5_FIPS)])
write_context_csv(out, "context-deprivation.csv")

adi_lines <- c(
  "# ADI ZIP/ZCTA proxy status",
  "",
  "No ADI proxy was generated. Neighborhood Atlas validates ADI at census block-group geography and requires credentialed access to its block-group files. A ZIP-only participant location cannot be linked directly without an explicitly weighted block-group-to-ZCTA aggregation.",
  "",
  "A future `adi_zcta_proxy` should be created only after an approved Neighborhood Atlas vintage and a reproducible population-weighted block-group-to-ZCTA crosswalk are supplied. It must remain an exploratory sensitivity exposure and be labeled as an unvalidated ZIP/ZCTA approximation."
)
writeLines(adi_lines, context_file("adi-proxy-status.md"))
message("Linked ZCTA SDI; documented the concrete ADI access/validation barrier.")
