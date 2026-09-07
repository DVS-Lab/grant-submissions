source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "context", "_context_helpers.R"))
for (id in c("uds_zip_zcta_2022", "rgc_sdi_2015_2019", "social_capital_atlas_zip_2022",
             "acs_gini_2024", "ruca_zip_2020")) {
  download_verified(source_entry(id))
}

message("Context reference cache is ready.")
