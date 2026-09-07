source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "context", "_context_helpers.R"))
if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Package 'jsonlite' is required.")

downloads <- data.frame(
  filename = c("rgcsdi-2015-2019-zcta.csv", "social_capital_zip.csv", "2020-ruca-zip.csv"),
  url = c(
    "https://www.aafp.org/assets/raw/upload/v1779124857/asset_rgc_sdi_2015_through_2019_zcta.csv",
    "https://data.humdata.org/dataset/85ee8e10-0c66-4635-b997-79b6fad44c71/resource/ab878625-279b-4bef-a2b3-c132168d536e/download/social_capital_zip.csv",
    "https://www.ers.usda.gov/media/5444/2020-rural-urban-commuting-area-codes-zip-codes.csv?v=49164"
  ), stringsAsFactors = FALSE
)
for (i in seq_len(nrow(downloads))) {
  target <- file.path(reference_dir(), downloads$filename[i])
  if (!file.exists(target)) {
    message("Downloading ", downloads$filename[i])
    utils::download.file(downloads$url[i], target, mode = "wb", quiet = TRUE)
  }
}

crosswalk_path <- file.path(reference_dir(), "uds_crosswalk_2022.csv")
if (!file.exists(crosswalk_path)) {
  url <- "https://raw.githubusercontent.com/chris-prener/uds-mapper/main/data/uds_crosswalk_2022.csv"
  utils::download.file(url, crosswalk_path, mode = "wb", quiet = TRUE)
}

message("Context reference cache is ready.")
