source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "context", "_context_helpers.R"))
z <- read_context_csv("zip-validation-private.csv")
crosswalk_path <- file.path(reference_dir(), "uds_crosswalk_2022.csv")
if (!file.exists(crosswalk_path)) stop("Run 00_prepare_context_sources.R first.")
xw <- utils::read.csv(crosswalk_path, colClasses = "character", check.names = FALSE)
require_columns(xw, c("zip", "zip_type", "zcta", "zip_join_type"), "UDS Mapper crosswalk")
xw$zip <- normalize_zip(xw$zip)
xw$zcta <- normalize_zip(xw$zcta)

current <- xw[match(z$zip_current, xw$zip), , drop = FALSE]
child <- xw[match(z$zip_child, xw$zip), , drop = FALSE]
out <- data.frame(
  study_id = z$study_id,
  zip_current = z$zip_current,
  zcta_current = current$zcta,
  zip_type_current = current$zip_type,
  zip_join_type_current = current$zip_join_type,
  zip_child = z$zip_child,
  zcta_child = child$zcta,
  zip_type_child = child$zip_type,
  zip_join_type_child = child$zip_join_type,
  stringsAsFactors = FALSE
)
write_context_csv(out, "zip-zcta-linkage-private.csv")

valid_current <- !is.na(z$zip_current)
valid_child <- !is.na(z$zip_child)
lines <- c(
  "# Private ZIP-to-ZCTA linkage audit",
  "",
  "- Source: archived UDS Mapper 2022 ZIP Code to ZCTA Crosswalk (normalized public mirror; ICPSR/NaNDA documents the same archived resource).",
  paste0("- Valid current ZIP N: ", sum(valid_current)),
  paste0("- Current ZIP to ZCTA matched N: ", sum(valid_current & !is.na(out$zcta_current)), " (", round(100 * mean(!is.na(out$zcta_current[valid_current])), 1), "%)"),
  paste0("- Current valid ZIP unmatched N: ", sum(valid_current & is.na(out$zcta_current))),
  paste0("- Current PO box/non-area ZIP N: ", sum(grepl("PO|large volume|Post Office", out$zip_type_current, ignore.case = TRUE), na.rm = TRUE)),
  paste0("- Valid childhood ZIP N: ", sum(valid_child)),
  paste0("- Childhood ZIP to ZCTA matched N: ", sum(valid_child & !is.na(out$zcta_child)), " (", round(100 * mean(!is.na(out$zcta_child[valid_child])), 1), "%)"),
  "- Childhood linkage is feasibility-only; contemporary context values are not interpreted as historical childhood exposure."
)
writeLines(lines, context_file("zip-zcta-linkage-audit.md"))
message("Linked ZIP to ZCTA.")
