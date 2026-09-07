source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "context", "_context_helpers.R"))

context <- read_context_csv("current-zip-context.csv")
context <- numeric_columns(context, setdiff(names(context), c("study_id", "ruca_category")))
link <- read_context_csv("zip-zcta-linkage-private.csv")
if (nrow(context) != 709L || anyDuplicated(context$study_id)) stop("Context master must have 709 unique participants.")
if (!setequal(context$study_id, link$study_id)) stop("Context and ZIP linkage participant keys differ.")

describe <- function(variable, source, vintage, geography, expected) {
  x <- context[[variable]]
  data.frame(
    variable = variable, source = source, vintage = vintage, geography = geography,
    N_matched = sum(!is.na(x)), N_missing = sum(is.na(x)),
    percent_matched = round(100 * mean(!is.na(x)), 2),
    minimum = if (all(is.na(x))) NA_real_ else min(x, na.rm = TRUE),
    maximum = if (all(is.na(x))) NA_real_ else max(x, na.rm = TRUE),
    expected_check = expected, stringsAsFactors = FALSE
  )
}
validation <- do.call(rbind, list(
  describe("sdi_zcta", "Robert Graham Center SDI", "ACS 2015–2019", "ZCTA", "0–100; higher is greater deprivation"),
  describe("pm25_2012_2022_zcta", "ACAG V5.NA.05", "annual 2012–2022", "0.01-degree grid to 2020 ZCTA", "plausible annual mean µg/m3; positive"),
  describe("socialcap_economic_connectedness", "Opportunity Insights Social Capital Atlas", "2022 release", "ZIP", "nonnegative"),
  describe("socialcap_high_ses_exposure", "Opportunity Insights Social Capital Atlas", "2022 release", "ZIP", "nonnegative"),
  describe("gini_zcta", "ACS 2024 five-year B19083", "2024", "ZCTA", "0–1"),
  describe("ruca_primary", "USDA ERS RUCA", "2020 codes", "ZIP", "integer 1–10"),
  describe("env_burden_simple", "Project exploratory composite", "current pipeline", "mixed direct-ZIP and ZCTA-linked components", "mean of >=3 aligned z scores")
))
if (any(context$sdi_zcta < 0 | context$sdi_zcta > 100, na.rm = TRUE)) stop("SDI outside 0–100.")
if (any(context$pm25_2012_2022_zcta <= 0 | context$pm25_2012_2022_zcta > 40, na.rm = TRUE)) stop("PM2.5 outside the documented plausibility range.")
if (any(context$gini_zcta < 0 | context$gini_zcta > 1, na.rm = TRUE)) stop("Gini outside 0–1.")
if (any(!(context$ruca_primary %in% 1:10) & !is.na(context$ruca_primary))) stop("RUCA outside 1–10.")
write_context_csv(validation, "context-validation.csv")

valid_current <- sum(grepl("^[0-9]{5}$", link$zip_current))
valid_child <- sum(grepl("^[0-9]{5}$", link$zip_child))
matched_current <- sum(!is.na(link$zcta_current) & nzchar(link$zcta_current))
matched_child <- sum(!is.na(link$zcta_child) & nzchar(link$zcta_child))
non_area <- sum(!is.na(link$zip_type_current) & !grepl("Zip Code Area", link$zip_type_current, fixed = TRUE))
lines <- c(
  "# Private context validation audit", "",
  paste0("- Participants: ", nrow(context), "."),
  paste0("- Valid current five-digit ZIP: ", valid_current, "."),
  paste0("- Current ZIP to ZCTA matched: ", matched_current, "/", valid_current,
         " (", sprintf("%.2f", 100 * matched_current / valid_current), "%)."),
  paste0("- Identifiable current non-area/special ZIP types: ", non_area, "."),
  paste0("- Valid childhood five-digit ZIP: ", valid_child, "."),
  paste0("- Childhood ZIP to present-day ZCTA potentially matched: ", matched_child, "/", valid_child,
         " (", sprintf("%.2f", 100 * matched_child / valid_child), "%)."),
  "- Childhood linkage is feasibility-only: contemporary context must not be represented as historical childhood exposure.",
  "", "## Exposure coverage", ""
)
for (i in seq_len(nrow(validation))) {
  x <- validation[i, ]
  lines <- c(lines, paste0("- `", x$variable, "`: ", x$N_matched, " matched (", x$percent_matched,
                           "%); range ", signif(x$minimum, 6), " to ", signif(x$maximum, 6), "."))
}
lines <- c(lines, "", "## Required caveats", "",
  "- Current ZIP is a coarse proxy for residential context and is not a street-level geocode.",
  "- PM2.5 is latitude-corrected area-weighted, not population-weighted; Melanie should decide whether a population-weighted sensitivity estimate is worth adding.",
  "- No ADI value was generated: ZIP-level ADI is not an intended Neighborhood Atlas geography, and credentialed block-group data plus defensible population weights are required.",
  "- No crime/disorder value was forced into the data because no consistent national ZCTA source was identified.")
atomic_write_lines(lines, context_file("context-linkage-audit.md"))

ref <- reference_dir()
retrieved <- as.character(Sys.Date())
entries <- source_manifest()
rows <- list()
for (entry in entries) {
  files <- if (is.null(entry$files)) list(entry) else entry$files
  for (item in files) {
    path <- file.path(ref, item$local_filename)
    rows[[length(rows) + 1L]] <- data.frame(
      source_id = entry$id, source_organization = entry$organization, source_title = entry$title,
      version = if (is.null(item$year)) entry$version else paste(entry$version, item$year),
      download_url = item$url, date_retrieved = retrieved, geographic_unit = entry$geography,
      license_use_note = entry$license_use_note, local_filename = item$local_filename,
      expected_sha256 = item$sha256, actual_sha256 = if (file.exists(path)) sha256(path) else NA_character_,
      stringsAsFactors = FALSE
    )
  }
}
atomic_write_csv(do.call(rbind, rows), file.path(ref, "source-manifest.csv"))
message("Checked context linkage and wrote private source manifest.")
