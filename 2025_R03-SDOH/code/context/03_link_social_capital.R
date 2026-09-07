source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "context", "_context_helpers.R"))
link <- read_context_csv("zip-zcta-linkage-private.csv")
path <- file.path(reference_dir(), "social_capital_zip.csv")
sc <- utils::read.csv(path, colClasses = "character", check.names = FALSE)
vars <- c("zip", "ec_zip", "exposure_grp_mem_zip", "bias_grp_mem_zip", "clustering_zip",
          "support_ratio_zip", "volunteering_rate_zip", "civic_organizations_zip")
require_columns(sc, vars, "Social Capital Atlas ZIP file")
sc$zcta <- normalize_zip(sc$zip)
hit <- sc[match(link$zcta_current, sc$zcta), vars[-1], drop = FALSE]
hit <- numeric_columns(hit, names(hit))
out <- data.frame(
  study_id = link$study_id,
  ec_zip = hit$ec_zip,
  exposure_grp_mem_zip = hit$exposure_grp_mem_zip,
  socialcap_economic_connectedness = hit$ec_zip,
  socialcap_high_ses_exposure = hit$exposure_grp_mem_zip,
  socialcap_friending_bias = hit$bias_grp_mem_zip,
  socialcap_cohesiveness = hit$clustering_zip,
  socialcap_support_ratio = hit$support_ratio_zip,
  socialcap_volunteering = hit$volunteering_rate_zip,
  socialcap_civic_organizations = hit$civic_organizations_zip,
  check.names = FALSE
)
write_context_csv(out, "context-social-capital.csv")
message("Linked Social Capital Atlas ZIP/ZCTA measures.")
