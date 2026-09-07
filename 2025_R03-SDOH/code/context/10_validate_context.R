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
  describe("env_burden_simple", "Project exploratory composite", "current pipeline", "participant current ZIP/ZCTA", "mean of >=3 aligned z scores")
))
if (any(context$sdi_zcta < 0 | context$sdi_zcta > 100, na.rm = TRUE)) stop("SDI outside 0–100.")
if (any(context$pm25_2012_2022_zcta <= 0 | context$pm25_2012_2022_zcta > 40, na.rm = TRUE)) stop("PM2.5 outside prespecified plausibility range.")
if (any(context$gini_zcta < 0 | context$gini_zcta > 1, na.rm = TRUE)) stop("Gini outside 0–1.")
if (any(!(context$ruca_primary %in% 1:10) & !is.na(context$ruca_primary))) stop("RUCA outside 1–10.")
utils::write.csv(validation, context_file("context-validation.csv"), row.names = FALSE, na = "")

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
  "- No ADI value was generated: ZIP-level ADI is not a validated Neighborhood Atlas use, and credentialed block-group data plus defensible population weights are required.",
  "- No crime/disorder value was forced into the data because no consistent national ZCTA source was identified.")
writeLines(lines, context_file("context-linkage-audit.md"))

ref <- reference_dir()
retrieved <- as.character(Sys.Date())
entries <- list(
  c("Health Resources and Services Administration / UDS Mapper", "UDS ZIP-to-ZCTA crosswalk (archived 2022 mirror)", "https://raw.githubusercontent.com/chris-prener/uds-mapper/main/data/uds_crosswalk_2022.csv", "2022", "ZIP and ZCTA", "Public crosswalk; archived reproducibility mirror", "uds_crosswalk_2022.csv"),
  c("Robert Graham Center", "Social Deprivation Index", "https://www.aafp.org/assets/raw/upload/v1779124857/asset_rgc_sdi_2015_through_2019_zcta.csv", "ACS 2015–2019", "ZCTA", "Public research download; retain source attribution", "rgcsdi-2015-2019-zcta.csv"),
  c("Opportunity Insights", "Social Capital Atlas ZIP data", "https://data.humdata.org/dataset/85ee8e10-0c66-4635-b997-79b6fad44c71/resource/ab878625-279b-4bef-a2b3-c132168d536e/download/social_capital_zip.csv", "2022 release", "ZIP", "Public research download; review source terms for reuse", "social_capital_zip.csv"),
  c("U.S. Census Bureau via Census Reporter", "ACS 2024 five-year B19083 Gini", "https://api.censusreporter.org/1.0/data/show/latest?table_ids=B19083&geo_ids=860%7C04000USXX", "2024 five-year", "ZCTA", "U.S. government statistical data", "censusreporter-acs2024-b19083-national.csv"),
  c("USDA Economic Research Service", "2020 RUCA codes by ZIP", "https://www.ers.usda.gov/media/5444/2020-rural-urban-commuting-area-codes-zip-codes.csv?v=49164", "2020; released 2025", "ZIP", "U.S. government data", "2020-ruca-zip.csv"),
  c("U.S. Census Bureau", "2020 ZCTA cartographic boundaries 1:500,000", "https://www2.census.gov/geo/tiger/GENZ2020/shp/cb_2020_us_zcta520_500k.zip", "2020", "ZCTA", "U.S. government geographic data", "cb_2020_us_zcta520_500k.zip")
)
pm_files <- sort(list.files(file.path(ref, "pm25"), pattern = "\\.nc$", full.names = FALSE))
for (filename in pm_files) entries[[length(entries) + 1L]] <- c(
  "Washington University Atmospheric Composition Analysis Group", "V5.NA.05 Hybrid annual PM2.5",
  "https://wustl.box.com/s/c3lmvqrvbjcrfpqoxb68nwl9tqhkl81g", sub(".*NorthAmerica\\.([0-9]{4}).*", "\\1", filename),
  "0.01-degree North America grid", "CC BY 4.0", file.path("pm25", filename)
)
manifest <- do.call(rbind, lapply(entries, function(x) {
  path <- file.path(ref, x[[7]])
  data.frame(source_organization=x[[1]], source_title=x[[2]], download_url=x[[3]],
             version_year=x[[4]], date_retrieved=retrieved, geographic_unit=x[[5]],
             license_use_note=x[[6]], local_filename=x[[7]],
             sha256=if (file.exists(path)) sha256(path) else NA_character_, stringsAsFactors=FALSE)
}))
utils::write.csv(manifest, file.path(ref, "source-manifest.csv"), row.names = FALSE, na = "")
message("Validated context linkage and wrote private source manifest.")
