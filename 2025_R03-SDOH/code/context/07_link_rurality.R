source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "context", "_context_helpers.R"))
link <- read_context_csv("zip-zcta-linkage-private.csv")
ruca <- utils::read.csv(file.path(reference_dir(), "2020-ruca-zip.csv"), colClasses = "character", check.names = FALSE)
require_columns(ruca, c("ZIPCode", "ZIPCodeType", "PrimaryRUCA", "SecondaryRUCA"), "USDA RUCA ZIP file")
ruca$ZIPCode <- normalize_zip(ruca$ZIPCode)
primary <- suppressWarnings(as.numeric(ruca$PrimaryRUCA[match(link$zip_current, ruca$ZIPCode)]))
category <- ifelse(primary %in% 1:3, "Metropolitan",
                   ifelse(primary %in% 4:6, "Micropolitan",
                          ifelse(primary %in% 7:9, "Small town",
                                 ifelse(primary == 10, "Rural", NA_character_))))
out <- data.frame(study_id = link$study_id, ruca_primary = primary, ruca_category = category)
write_context_csv(out, "context-rurality.csv")
message("Linked official USDA 2020 ZIP-level RUCA codes.")
