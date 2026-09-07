source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "pipeline", "_helpers.R"))
d <- read_source()
s <- read_private_csv("core-scores.csv")
if (nrow(d) != nrow(s) || anyDuplicated(s$study_id) || !setequal(d$study_id, s$study_id)) {
  stop("Source and score keys do not form a one-to-one match.")
}

demographic_fields <- c(
  "study_id", "demo_yrs", "demo_gender", "demo_sab", "demo_race", "demo_eth",
  "demo_quota", "region", "demo_zip_prim_yr", "ses_edu", "ses_yoe", "ses_thi",
  "ses_tpi", "ses_rentown", "ses_hhr"
)
require_columns(d, demographic_fields)
master <- merge(d[demographic_fields], s, by = "study_id", all = FALSE, sort = FALSE)
master <- master[match(d$study_id, master$study_id), , drop = FALSE]
master$demo_yrs <- suppressWarnings(as.numeric(master$demo_yrs))

# A separately generated private linkage may be joined without changing this script.
context_path <- Sys.getenv(
  "SDOH_CONTEXT_DATA",
  unset = file.path(derived_dir(), "current-zip-context.csv")
)
if (file.exists(context_path)) {
  context <- utils::read.csv(context_path, check.names = FALSE)
  require_columns(context, "study_id", "context linkage")
  if (anyDuplicated(context$study_id)) stop("Context linkage has duplicate study_id values.")
  prohibited_geo <- grep("zip|address|latitude|longitude|(^|_)lat($|_)|(^|_)lon($|_)", names(context), ignore.case = TRUE, value = TRUE)
  keep <- setdiff(names(context), c("study_id", prohibited_geo))
  master <- merge(master, context[c("study_id", keep)], by = "study_id", all.x = TRUE, sort = FALSE)
  master <- master[match(d$study_id, master$study_id), , drop = FALSE]
}

if (nrow(master) != nrow(d) || anyDuplicated(master$study_id)) stop("Analysis master lost or duplicated records.")
prohibited_geo_names <- c("demo_zip_prim", "demo_zip_child")
if (any(names(master) %in% prohibited_geo_names) || any(grepl("address", names(master), ignore.case = TRUE))) {
  stop("ZIP/address field leaked into the general analysis master.")
}
write_private_csv(master, "analysis-master.csv")
cat("Built private analysis master: N=", nrow(master), ", columns=", ncol(master), ".\n", sep = "")
