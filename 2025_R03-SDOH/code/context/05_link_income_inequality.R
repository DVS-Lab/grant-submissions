source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "context", "_context_helpers.R"))
link <- read_context_csv("zip-zcta-linkage-private.csv")
entry <- source_entry("acs_gini_2024")
cache <- download_verified(entry)
raw <- utils::read.delim(cache, sep = "|", quote = "", colClasses = "character", check.names = FALSE)
require_columns(raw, c("GEO_ID", "B19083_E001"), "ACS B19083 table")
keep <- grepl("^860Z200US[0-9]{5}$", raw$GEO_ID)
gini <- data.frame(
  zcta = sub("^860Z200US", "", raw$GEO_ID[keep]),
  gini_zcta = suppressWarnings(as.numeric(raw$B19083_E001[keep])),
  stringsAsFactors = FALSE
)
gini$gini_zcta[gini$gini_zcta < 0 | gini$gini_zcta > 1] <- NA_real_
if (nrow(gini) < 30000L || anyDuplicated(gini$zcta)) stop("Fixed ACS B19083 file has an unexpected ZCTA slice.")
out <- data.frame(study_id = link$study_id, gini_zcta = gini$gini_zcta[match(link$zcta_current, gini$zcta)])
out$gini <- out$gini_zcta
write_context_csv(out, "context-income-inequality.csv")
message("Linked fixed ACS 2024 five-year B19083 Gini estimates at ZCTA geography.")
