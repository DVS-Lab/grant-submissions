#!/usr/bin/env Rscript

source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "pipeline", "_helpers.R"))
if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Package 'jsonlite' is required.")
contract <- jsonlite::fromJSON(file.path(project_root(), "config", "reproduction-contract.json"), simplifyVector = TRUE)
checks <- list()
add <- function(label, actual, expected, severity = "FAIL") {
  ok <- identical(as.character(actual), as.character(expected))
  checks[[length(checks) + 1L]] <<- data.frame(status = if (ok) "PASS" else severity,
    check = label, actual = paste(actual, collapse = "; "), expected = paste(expected, collapse = "; "),
    stringsAsFactors = FALSE)
}

source_data <- read_source()
add("Source workbook rows", nrow(source_data), contract$source_workbook$rows)
add("Source workbook columns", ncol(source_data), contract$source_workbook$columns)
master <- read_private_csv("analysis-master.csv")
add("Analysis master rows", nrow(master), contract$analysis_master$rows)
add("Analysis master columns", ncol(master), contract$analysis_master$columns)

dictionary <- utils::read.csv(file.path(project_root(), "docs", "analysis-master-dictionary.csv"), check.names = FALSE)
add("Analysis dictionary variables", nrow(dictionary), ncol(master))
add("Dictionary/master ordered names", identical(dictionary$variable, names(master)), TRUE)

scores <- read_private_csv("score-validation.csv")
for (variable in names(contract$scores)) {
  actual <- scores$N_scored[match(variable, scores$variable)]
  add(paste("Scored N", variable), actual, contract$scores[[variable]])
}
link <- utils::read.csv(file.path(derived_dir(), "zip-zcta-linkage-private.csv"), colClasses = "character",
                        na.strings = c("", "NA", "N/A"), check.names = FALSE)
add("Valid current ZIP", sum(grepl("^[0-9]{5}$", link$zip_current)), contract$geography$valid_current_zip)
add("Matched current ZCTA", sum(!is.na(link$zcta_current)), contract$geography$matched_current_zcta)

context <- read_private_csv("context-validation.csv")
for (variable in names(contract$exposures)) {
  actual <- context$N_matched[match(variable, context$variable)]
  add(paste("Exposure coverage", variable), actual, contract$exposures[[variable]])
}

historical <- read_private_csv("model-screen-rerun.csv")
formula_status <- split(historical$status, historical$model_formula)
add("Historical formulas", length(formula_status), contract$historical_models$total_formulas)
add("Runnable historical formulas", sum(vapply(formula_status, function(x) any(x == "RERUN"), logical(1))),
    contract$historical_models$runnable_formulas)
specs <- read_private_csv("grant-model-specifications.csv")
add("Fixed grant-driven model specifications", nrow(specs), contract$grant_framework$model_specifications)
results <- read_private_csv("grant-candidate-results.csv")
model_status <- tapply(results$status, results$model_id, function(x) unique(x))
add("Grant models represented", length(model_status), contract$grant_framework$model_specifications)
add("Grant model statuses", paste(sort(unique(unlist(model_status))), collapse = ","), contract$grant_framework$required_status)
figure_count <- length(list.files(file.path(derived_dir(), "figures"), pattern = "\\.png$", ignore.case = TRUE))
add("Figure PNG files", figure_count, contract$figures$png_files)
for (filename in contract$required_private_outputs) add(paste("Required output", filename), file.exists(file.path(derived_dir(), filename)), TRUE)

table <- do.call(rbind, checks)
lines <- c("# Private reproduction check", "", paste0("Generated: ", format(Sys.time(), tz = "UTC", usetz = TRUE)), "",
           "| Status | Check | Actual | Expected |", "|---|---|---:|---:|",
           apply(table, 1, function(x) paste0("| ", paste(gsub("\\|", "/", x), collapse = " | "), " |")), "")
if (any(table$status == "FAIL")) {
  lines <- c(lines, "**Overall: FAIL.** One or more reproduction-contract checks failed.")
} else if (any(table$status == "WARNING")) {
  lines <- c(lines, "**Overall: WARNING.** Required checks passed with warnings.")
} else {
  lines <- c(lines, "**Overall: PASS.** Every required reproduction-contract check passed.")
}
atomic_write_lines(lines, file.path(derived_dir(), "reproduction-check.md"))
if (any(table$status == "FAIL")) stop("Reproduction contract failed; see private reproduction-check.md.")
message("Reproduction contract PASS.")
