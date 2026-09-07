source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "context", "_context_helpers.R"))
d <- read_source()
require_columns(d, c("study_id", "demo_zip_prim", "demo_zip_child"))

raw_current <- trimws(as.character(d$demo_zip_prim))
raw_child <- trimws(as.character(d$demo_zip_child))
zip_current <- normalize_zip(raw_current)
zip_child <- normalize_zip(raw_child)
out <- data.frame(
  study_id = d$study_id,
  zip_current = zip_current,
  zip_current_valid = !is.na(zip_current),
  zip_child = zip_child,
  zip_child_valid = !is.na(zip_child),
  stringsAsFactors = FALSE
)
write_context_csv(out, "zip-validation-private.csv")
lines <- c(
  "# Private ZIP validation",
  "",
  paste0("- Records: ", nrow(out)),
  paste0("- Valid current five-digit ZIP: ", sum(out$zip_current_valid), " (", round(100 * mean(out$zip_current_valid), 1), "%)"),
  paste0("- Invalid/missing current ZIP: ", sum(!out$zip_current_valid)),
  paste0("- Valid childhood five-digit ZIP: ", sum(out$zip_child_valid), " (", round(100 * mean(out$zip_child_valid), 1), "%)"),
  paste0("- Invalid/missing childhood ZIP: ", sum(!out$zip_child_valid)),
  "- Participant ZIP values are retained only in ignored private linkage files."
)
atomic_write_lines(lines, context_file("zip-validation-audit.md"))
message("Checked current and childhood ZIP fields.")
