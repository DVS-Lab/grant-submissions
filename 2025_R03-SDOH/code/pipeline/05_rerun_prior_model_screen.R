source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "pipeline", "_helpers.R"))
master <- read_private_csv("analysis-master.csv")
ref_dir <- file.path(project_root(), "derivatives", "model-screening")
ref_files <- file.path(ref_dir, c("all-models.csv", "chetty-models.csv", "non-chetty-models.csv"))
if (!all(file.exists(ref_files))) stop("The three aggregate model-screen reference files are required in ", ref_dir)

refs <- lapply(ref_files, function(f) utils::read.csv(f, check.names = FALSE))
names(refs) <- basename(ref_files)
required_ref_cols <- c("outcome","interaction_type","term","estimate","std_error","t_value","p_value","model_formula")
expected_rows <- c("all-models.csv"=143L, "chetty-models.csv"=79L, "non-chetty-models.csv"=64L)
expected_formulas <- c("all-models.csv"=35L, "chetty-models.csv"=22L, "non-chetty-models.csv"=16L)
for (nm in names(refs)) {
  require_columns(refs[[nm]], required_ref_cols, nm)
  if (any(grepl("study_id|(^|_)zip($|_)|email|address|responseid|participant|contact", names(refs[[nm]]), ignore.case = TRUE))) {
    stop(nm, " contains a prohibited participant-level field.")
  }
  if (nrow(refs[[nm]]) != expected_rows[[nm]] || length(unique(refs[[nm]]$model_formula)) != expected_formulas[[nm]]) {
    stop(nm, " no longer matches its verified aggregate row/formula counts.")
  }
}
old <- refs[["all-models.csv"]]
formulas <- unique(old$model_formula)
formula_union_equal <- setequal(
  unique(old$model_formula),
  unique(c(refs[["chetty-models.csv"]]$model_formula, refs[["non-chetty-models.csv"]]$model_formula))
)
if (!formula_union_equal) stop("all-models formula set is not the Chetty/non-Chetty formula union.")
row_key <- function(x) apply(x[required_ref_cols], 1, paste, collapse = "\034")
exact_row_union <- setequal(
  unique(row_key(old)),
  unique(row_key(rbind(refs[["chetty-models.csv"]], refs[["non-chetty-models.csv"]])))
)
outcome_counts <- table(unique(old[c("outcome", "model_formula")])$outcome)
if (!identical(as.integer(outcome_counts[c("fevs_total", "oafem_adult_total")]), c(16L, 19L))) {
  stop("Unexpected FEVS/OAFEM formula counts in all-models.csv.")
}
atomic_write_lines(c(
  "# Private model-screen reference audit", "",
  "- `all-models.csv`: 143 coefficient rows; 35 formulas (16 FEVS, 19 OAFEM).",
  "- `chetty-models.csv`: 79 coefficient rows; 22 formulas.",
  "- `non-chetty-models.csv`: 64 coefficient rows; 16 formulas.",
  paste0("- Formula-set union equality: ", formula_union_equal, "."),
  paste0("- Exact coefficient-row union equality: ", exact_row_union, "."),
  "- The exact row union is false because overlapping formula/term records have different historical numeric estimates; the files are intentionally preserved separately.",
  "- Participant/direct-identifier columns: absent."
), file.path(derived_dir(), "model-screen-reference-audit.md"))

rerun <- list()
for (ftext in formulas) {
  vars <- safe_formula_variables(ftext)
  missing <- setdiff(vars, names(master))
  outcome <- vars[1]
  if (length(missing)) {
    rerun[[length(rerun) + 1L]] <- data.frame(
      outcome = outcome, model_formula = ftext, term = "", N = NA_integer_,
      estimate = NA_real_, std_error = NA_real_, t_value = NA_real_, p_value = NA_real_,
      status = "NOT RUNNABLE", missing_variables = paste(missing, collapse = ";"), check.names = FALSE
    )
    next
  }
  fit <- tryCatch(stats::lm(stats::as.formula(ftext), data = master, na.action = stats::na.omit), error = identity)
  if (inherits(fit, "error")) {
    rerun[[length(rerun) + 1L]] <- data.frame(
      outcome = outcome, model_formula = ftext, term = "", N = NA_integer_,
      estimate = NA_real_, std_error = NA_real_, t_value = NA_real_, p_value = NA_real_,
      status = "NOT RUNNABLE", missing_variables = "model fit failed", check.names = FALSE
    )
  } else {
    co <- summary(fit)$coefficients
    rerun[[length(rerun) + 1L]] <- data.frame(
      outcome = outcome, model_formula = ftext, term = rownames(co), N = stats::nobs(fit),
      estimate = co[,1], std_error = co[,2], t_value = co[,3], p_value = co[,4],
      status = "RERUN", missing_variables = "", row.names = NULL, check.names = FALSE
    )
  }
}
rerun <- do.call(rbind, rerun)
write_private_csv(rerun, "model-screen-rerun.csv")

new_terms <- rerun[rerun$status == "RERUN", c("model_formula","term","estimate","p_value")]
names(new_terms)[3:4] <- c("new_estimate","new_p")
comparison <- merge(old, new_terms, by = c("model_formula","term"), all.x = TRUE, sort = FALSE)
missing_by_formula <- setNames(rerun$missing_variables[rerun$status == "NOT RUNNABLE"], rerun$model_formula[rerun$status == "NOT RUNNABLE"])
comparison$status <- ifelse(
  is.na(comparison$new_estimate),
  ifelse(comparison$model_formula %in% names(missing_by_formula), "NOT RUNNABLE", "TERM NOT COMPARABLE"),
  ifelse(sign(comparison$estimate) == sign(comparison$new_estimate), "DIRECTION CONSISTENT", "DIRECTION CHANGED")
)
comparison$missing_variables <- unname(missing_by_formula[comparison$model_formula])
comparison$same_direction <- ifelse(is.na(comparison$new_estimate), NA, sign(comparison$estimate) == sign(comparison$new_estimate))
comparison <- comparison[c("outcome","model_formula","term","estimate","new_estimate","p_value","new_p","same_direction","status","missing_variables")]
names(comparison)[names(comparison) == "estimate"] <- "old_estimate"
names(comparison)[names(comparison) == "p_value"] <- "old_p"
write_private_csv(comparison, "model-screen-comparison.csv")
formula_status <- aggregate(status ~ model_formula, rerun, function(x) if (any(x == "RERUN")) "RERUN" else "NOT RUNNABLE")
cat("Classified ", length(formulas), " prior formulas: ", sum(formula_status$status == "RERUN"), " runnable; ", sum(formula_status$status == "NOT RUNNABLE"), " not runnable.\n", sep = "")
