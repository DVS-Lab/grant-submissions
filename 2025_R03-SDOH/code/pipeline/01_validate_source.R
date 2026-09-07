source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "pipeline", "_helpers.R"))

d <- read_source()
expected_n <- as.integer(Sys.getenv("SDOH_EXPECTED_N", unset = "709"))
if (nrow(d) != expected_n) stop("Expected N=", expected_n, "; found N=", nrow(d), ".")
require_columns(d, c("study_id", "attention_check", "gc"))
if (any(is.na(d$study_id) | trimws(as.character(d$study_id)) == "")) stop("study_id is missing.")
if (anyDuplicated(d$study_id)) stop("study_id is not unique.")

prohibited <- c(
  "responseid", "startdate", "enddate", "recordeddate", "ipaddress",
  "recipientemail", "recipientfirstname", "recipientlastname", "externalreference",
  "qpmid", "survey_id", "transaction_id", "svid", "cintid", "risn", "rid", "demo_dob"
)
present_prohibited <- names(d)[tolower(names(d)) %in% prohibited]
if (length(present_prohibited)) {
  stop("Prohibited direct/platform identifier columns are present: ", paste(present_prohibited, collapse = ", "))
}

likely_domain <- function(v) {
  prefix <- sub("_.*$", "", v)
  known <- c(
    demo = "demographics", ses = "socioeconomic status", fevs = "financial vulnerability",
    oafem = "financial exploitation", ecog = "subjective cognition", susd = "mood",
    uclal = "loneliness", mspss = "social support", ntb = "need to belong",
    promis = "health", fraud = "fraud/loss", sogs = "gambling", bbgs = "gambling",
    audit = "alcohol", dudit = "drug use", caregiver = "caregiving", cbt = "temporal choice",
    opr = "occupation"
  )
  if (prefix %in% names(known)) unname(known[prefix]) else "survey/QC/other"
}

schema <- do.call(rbind, lapply(names(d), function(v) {
  x <- d[[v]]
  suppress_range <- v %in% c("study_id", "demo_zip_prim", "demo_zip_child")
  numeric_x <- is.numeric(x) && !suppress_range
  data.frame(
    variable = v,
    class = paste(class(x), collapse = "/"),
    nonmissing_n = sum(!is.na(x)),
    missing_n = sum(is.na(x)),
    unique_n = length(unique(x[!is.na(x)])),
    numeric_min = if (numeric_x && any(!is.na(x))) min(x, na.rm = TRUE) else NA_real_,
    numeric_max = if (numeric_x && any(!is.na(x))) max(x, na.rm = TRUE) else NA_real_,
    likely_domain = likely_domain(v),
    notes = if (v %in% c("demo_zip_prim", "demo_zip_child")) "Private geographic linkage field; exclude from general-purpose derivatives." else "",
    check.names = FALSE
  )
}))
write_private_csv(schema, "source-schema.csv")

att <- table(d$attention_check, useNA = "ifany")
gc <- table(d$gc, useNA = "ifany")
att_ok <- length(att) == 1L && names(att)[1] == "Apple" && unname(att[1]) == expected_n
gc_ok <- length(gc) == 1L && suppressWarnings(as.numeric(names(gc)[1])) == 1 && unname(gc[1]) == expected_n
duplicate_rows <- sum(duplicated(d))
blank_cols <- names(d)[vapply(d, function(x) all(is.na(x)), logical(1))]
missing_cols <- sum(vapply(d, anyNA, logical(1)))

lines <- c(
  "# Private source QC",
  "",
  paste0("- Source rows: ", nrow(d)),
  paste0("- Source columns: ", ncol(d)),
  paste0("- `study_id`: complete and unique (", length(unique(d$study_id)), " unique)"),
  paste0("- Duplicate entire rows: ", duplicate_rows),
  paste0("- Columns with any missingness: ", missing_cols),
  paste0("- Entirely blank columns: ", length(blank_cols), if (length(blank_cols)) paste0(" (", paste(blank_cols, collapse = ", "), ")") else ""),
  paste0("- Prohibited direct/platform identifiers: absent"),
  paste0("- Attention check: ", if (att_ok) paste0("all ", expected_n, " retained rows are `Apple`") else "unexpected distribution; review required"),
  paste0("- `gc`: ", if (gc_ok) paste0("all ", expected_n, " retained rows equal 1") else "unexpected distribution; review required"),
  "",
  "No exclusion was applied. Categorical participant values and row-level records are intentionally omitted from this report."
)
atomic_write_lines(lines, file.path(derived_dir(), "source-qc.md"))
if (!att_ok || !gc_ok) stop("Attention-check or gc validation did not match the documented retained-sample expectation.")
cat("Checked private source structure: N=", nrow(d), ", columns=", ncol(d), ".\n", sep = "")
