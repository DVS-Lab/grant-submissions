source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "pipeline", "_helpers.R"))
d <- read_source()
s <- read_private_csv("core-scores.csv")
if (nrow(s) != 709L || anyDuplicated(s$study_id) || any(is.na(s$study_id))) stop("Score file key validation failed.")

spec <- data.frame(
  construct = c("FEVS","eCog","SUSD depression","SUSD mania","UCLA loneliness","MSPSS total",
                "MSPSS significant other","MSPSS family","MSPSS friends","Need to Belong",
                "OAFEM unweighted diagnostic","PROMIS physical function","PROMIS anxiety",
                "PROMIS depression","PROMIS fatigue","PROMIS sleep disturbance",
                "PROMIS social roles","PROMIS pain interference","PROMIS pain intensity"),
  recomputed_score_variable = c("fevs_total","ecog_total","susd_depression","susd_mania","uclal_total","mspss_total",
                                "mspss_significant_other","mspss_family","mspss_friends","ntb_total",
                                "oafem_unweighted_complete","promis_physical_function_raw","promis_anxiety_raw",
                                "promis_depression_raw","promis_fatigue_raw","promis_sleep_disturbance_raw",
                                "promis_social_roles_raw","promis_pain_interference_raw","promis_pain_intensity"),
  lower = c(0,1,0,0,3,1,1,1,1,10,0,4,4,4,4,4,4,4,0),
  upper = c(18,4,21,21,9,7,7,7,7,50,60,20,20,20,20,20,20,20,10),
  scoring_status = c(
    "VERIFIED","VERIFIED","VERIFIED","VERIFIED","VERIFIED","VERIFIED","VERIFIED","VERIFIED","VERIFIED","VERIFIED",
    "NEEDS SCIENTIFIC REVIEW","IMPLEMENTED BUT NEEDS SCIENTIFIC REVIEW","IMPLEMENTED BUT NEEDS SCIENTIFIC REVIEW",
    "IMPLEMENTED BUT NEEDS SCIENTIFIC REVIEW","IMPLEMENTED BUT NEEDS SCIENTIFIC REVIEW","IMPLEMENTED BUT NEEDS SCIENTIFIC REVIEW",
    "IMPLEMENTED BUT NEEDS SCIENTIFIC REVIEW","IMPLEMENTED BUT NEEDS SCIENTIFIC REVIEW","VERIFIED"
  ),
  stringsAsFactors = FALSE
)

validation <- do.call(rbind, lapply(seq_len(nrow(spec)), function(i) {
  v <- spec$recomputed_score_variable[i]
  x <- s[[v]]
  if (any(x < spec$lower[i] | x > spec$upper[i], na.rm = TRUE)) stop(v, " has an impossible value.")
  existing <- if (v %in% names(d)) v else ""
  if (nzchar(existing)) {
    old <- suppressWarnings(as.numeric(d[[existing]]))
    keep <- !is.na(old) & !is.na(x)
    diff <- abs(old[keep] - x[keep])
    n_compared <- sum(keep)
    exact <- sum(diff <= 1e-8)
    agreement <- if (n_compared) exact / n_compared else NA_real_
    max_diff <- if (n_compared) max(diff) else NA_real_
    missing_old <- sum(is.na(old))
  } else {
    n_compared <- exact <- 0L; agreement <- max_diff <- NA_real_; missing_old <- NA_integer_
  }
  data.frame(
    construct = spec$construct[i], existing_score_variable = existing,
    recomputed_score_variable = v, n_compared = n_compared, exact_match_n = exact,
    agreement_rate = agreement, max_absolute_difference = max_diff,
    missingness_existing = missing_old, missingness_recomputed = sum(is.na(x)),
    observed_min = if (any(!is.na(x))) min(x, na.rm = TRUE) else NA_real_,
    observed_max = if (any(!is.na(x))) max(x, na.rm = TRUE) else NA_real_,
    expected_min = spec$lower[i], expected_max = spec$upper[i],
    scoring_status = spec$scoring_status[i],
    discrepancy_notes = if (!nzchar(existing)) "No derived score exists in the source workbook; agreement cannot be tested."
      else if (!is.na(agreement) && agreement == 1) "Exact/tolerance match." else "Existing and recomputed values differ; review required.",
    check.names = FALSE
  )
}))
write_private_csv(validation, "score-validation.csv")

verified <- validation$construct[validation$scoring_status == "VERIFIED"]
review <- validation$construct[grepl("REVIEW", validation$scoring_status)]
lines <- c(
  "# Private score validation",
  "",
  paste0("- Records validated: ", nrow(s)),
  paste0("- Scores with verified item/response rules: ", paste(verified, collapse = "; ")),
  paste0("- Scores requiring scientific review: ", paste(review, collapse = "; ")),
  "- Existing derived scores in the source: none detected; agreement fields are therefore not applicable.",
  "- OAFEM: responses are recoded, but the 30 generic column names cannot be aligned reliably to the published severity weights; only a complete-case unweighted diagnostic is emitted.",
  "- PROMIS: seven complete-case raw domain sums and pain intensity are emitted. T-scores are withheld until the exact PROMIS profile/version and official scoring table/service are confirmed.",
  "- Missing items are not silently replaced with zero. eCog alone follows its documented mean-of-answered-items rule and records the number answered.",
  "",
  "See `score-validation.csv` for ranges and missingness."
)
writeLines(lines, file.path(derived_dir(), "score-validation.md"))
cat("Validated ", nrow(validation), " score definitions/ranges.\n", sep = "")
