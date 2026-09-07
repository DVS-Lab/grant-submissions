source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "pipeline", "_helpers.R"))
d <- read_private_csv("analysis-master.csv")
context_var <- Sys.getenv("SDOH_CONTEXT_VARIABLE", unset = "")
if (!nzchar(context_var)) {
  known <- c("adi_national_rank", "adi_state_rank", "context_disadvantage", "ec_zip", "gini")
  found <- intersect(known, names(d))
  if (length(found)) context_var <- found[[1]]
}

specs <- data.frame(
  model_id = c(
    "CTX_FEVS","CTX_OAFEM","CTX_ECOG","ECOG_FEVS","ECOG_OAFEM",
    "CTXxECOG_FEVS","CTXxECOG_OAFEM","CTXxAGE_FEVS","CTXxAGE_OAFEM",
    "CTXxMSPSS_FEVS","CTXxMSPSS_OAFEM","CTXxUCLA_FEVS","CTXxUCLA_OAFEM",
    "CTXxSUSD_FEVS","CTXxSUSD_OAFEM","ECOGxMSPSS_FEVS","ECOGxMSPSS_OAFEM",
    "ECOG_FEVS_ADJ","ECOG_OAFEM_ADJ","ECOG_FRAUD1","ECOG_FRAUD2"
  ),
  scientific_question = c(
    "Contextual disadvantage and financial vulnerability","Contextual disadvantage and exploitation indicators",
    "Contextual disadvantage and subjective cognitive difficulty","Subjective cognitive difficulty and financial vulnerability",
    "Subjective cognitive difficulty and exploitation indicators","Context-by-cognition association with financial vulnerability",
    "Context-by-cognition association with exploitation indicators","Context-by-age association with financial vulnerability",
    "Context-by-age association with exploitation indicators","Context-by-social-support association with financial vulnerability",
    "Context-by-social-support association with exploitation indicators","Context-by-loneliness association with financial vulnerability",
    "Context-by-loneliness association with exploitation indicators","Context-by-depression association with financial vulnerability",
    "Context-by-depression association with exploitation indicators","Cognition-by-social-support association with financial vulnerability",
    "Cognition-by-social-support association with exploitation indicators","Adjusted cognition association with financial vulnerability",
    "Adjusted cognition association with exploitation indicators","Subjective cognitive difficulty and first reported loss indicator",
    "Subjective cognitive difficulty and second reported loss indicator"
  ),
  formula_template = c(
    "fevs_total ~ CONTEXT","oafem_unweighted_complete ~ CONTEXT","ecog_total ~ CONTEXT",
    "fevs_total ~ ecog_total","oafem_unweighted_complete ~ ecog_total",
    "fevs_total ~ CONTEXT * ecog_total","oafem_unweighted_complete ~ CONTEXT * ecog_total",
    "fevs_total ~ CONTEXT * demo_yrs","oafem_unweighted_complete ~ CONTEXT * demo_yrs",
    "fevs_total ~ CONTEXT * mspss_total","oafem_unweighted_complete ~ CONTEXT * mspss_total",
    "fevs_total ~ CONTEXT * uclal_total","oafem_unweighted_complete ~ CONTEXT * uclal_total",
    "fevs_total ~ CONTEXT * susd_depression","oafem_unweighted_complete ~ CONTEXT * susd_depression",
    "fevs_total ~ ecog_total * mspss_total","oafem_unweighted_complete ~ ecog_total * mspss_total",
    "fevs_total ~ ecog_total + demo_yrs + demo_gender + ses_thi",
    "oafem_unweighted_complete ~ ecog_total + demo_yrs + demo_gender + ses_thi",
    "fraud_adult_1_any_loss ~ ecog_total + demo_yrs + demo_gender + ses_thi",
    "fraud_adult_2_any_loss ~ ecog_total + demo_yrs + demo_gender + ses_thi"
  ),
  family = c(rep("gaussian", 19), "binomial", "binomial"),
  stringsAsFactors = FALSE
)

results <- list()
for (i in seq_len(nrow(specs))) {
  template <- specs$formula_template[i]
  formula_text <- if (grepl("CONTEXT", template, fixed = TRUE) && nzchar(context_var)) {
    gsub("CONTEXT", context_var, template, fixed = TRUE)
  } else template
  vars <- safe_formula_variables(formula_text)
  missing <- setdiff(vars, names(d))
  if (grepl("CONTEXT", formula_text, fixed = TRUE)) missing <- unique(c(missing, "context variable/linkage"))
  outcome <- sub("\\s*~.*$", "", formula_text)
  if (length(missing)) {
    results[[length(results) + 1L]] <- data.frame(
      model_id = specs$model_id[i], scientific_question = specs$scientific_question[i], outcome = outcome,
      formula = formula_text, N = NA_integer_, term = "", estimate = NA_real_, SE = NA_real_,
      CI_low = NA_real_, CI_high = NA_real_, p = NA_real_,
      status = paste0("NOT RUNNABLE — missing: ", paste(missing, collapse = "; ")), check.names = FALSE
    )
    next
  }
  fit <- tryCatch({
    if (specs$family[i] == "binomial") stats::glm(stats::as.formula(formula_text), data = d, family = stats::binomial(), na.action = stats::na.omit)
    else stats::lm(stats::as.formula(formula_text), data = d, na.action = stats::na.omit)
  }, error = identity)
  if (inherits(fit, "error")) {
    results[[length(results) + 1L]] <- data.frame(
      model_id = specs$model_id[i], scientific_question = specs$scientific_question[i], outcome = outcome,
      formula = formula_text, N = NA_integer_, term = "", estimate = NA_real_, SE = NA_real_,
      CI_low = NA_real_, CI_high = NA_real_, p = NA_real_, status = "FIT FAILED — inspect model/data", check.names = FALSE
    )
    next
  }
  terms <- model_terms(fit)
  caveat <- if (identical(outcome, "oafem_unweighted_complete")) "RUN — OAFEM OUTCOME PROVISIONAL" else "RUN"
  results[[length(results) + 1L]] <- data.frame(
    model_id = specs$model_id[i], scientific_question = specs$scientific_question[i], outcome = outcome,
    formula = formula_text, N = stats::nobs(fit), terms, status = caveat, check.names = FALSE
  )
}
results <- do.call(rbind, results)
write_private_csv(results, "grant-candidate-results.csv")
cat("Evaluated ", nrow(specs), " fixed candidate model specifications; results remain private.\n", sep = "")
