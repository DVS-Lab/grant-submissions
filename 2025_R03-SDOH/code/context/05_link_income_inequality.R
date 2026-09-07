source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "context", "_context_helpers.R"))
if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Package 'jsonlite' is required.")
link <- read_context_csv("zip-zcta-linkage-private.csv")
cache <- file.path(reference_dir(), "censusreporter-acs2024-b19083-national.csv")
if (!file.exists(cache)) {
  # Query every state/territory hierarchy. This intentionally downloads a national
  # public reference rather than sending any participant-derived ZCTA list.
  state_fips <- c("01","02","04","05","06","08","09","10","11","12","13","15","16","17","18","19",
                  "20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35",
                  "36","37","38","39","40","41","42","44","45","46","47","48","49","50","51","53",
                  "54","55","56")
  values <- numeric()
  for (fips in state_fips) {
    hierarchy <- paste0("860|04000US", fips)
    url <- paste0("https://api.censusreporter.org/1.0/data/show/latest?table_ids=B19083&geo_ids=", utils::URLencode(hierarchy, reserved = TRUE))
    payload <- jsonlite::fromJSON(url, simplifyVector = FALSE)
    for (geoid in names(payload$data)) {
      value <- payload$data[[geoid]]$B19083$estimate$B19083001
      if (is.null(value) || !length(value)) value <- NA_real_
      values[sub("^86000US", "", geoid)] <- suppressWarnings(as.numeric(value[[1]]))
    }
  }
  gini <- data.frame(zcta = names(values), gini_zcta = unname(values), stringsAsFactors = FALSE)
  if (nrow(gini) < 30000L) stop("National ACS B19083 cache contains unexpectedly few ZCTAs.")
  utils::write.csv(gini, cache, row.names = FALSE, na = "")
} else {
  gini <- utils::read.csv(cache, colClasses = "character")
  gini$gini_zcta <- suppressWarnings(as.numeric(gini$gini_zcta))
}
out <- data.frame(study_id = link$study_id, gini_zcta = gini$gini_zcta[match(link$zcta_current, gini$zcta)])
out$gini <- out$gini_zcta
write_context_csv(out, "context-income-inequality.csv")
message("Linked ACS 2024 five-year B19083 Gini estimates at ZCTA geography.")
