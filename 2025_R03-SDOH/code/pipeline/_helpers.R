options(stringsAsFactors = FALSE)

project_root <- function() {
  value <- Sys.getenv("SDOH_PROJECT_ROOT", unset = "")
  if (!nzchar(value)) stop("SDOH_PROJECT_ROOT is not set.")
  normalizePath(value, mustWork = TRUE)
}

source_path <- function() {
  value <- Sys.getenv("SDOH_SOURCE_DATA", unset = "")
  if (!nzchar(value)) stop("SDOH_SOURCE_DATA is not set.")
  normalizePath(value, mustWork = TRUE)
}

derived_dir <- function() {
  value <- Sys.getenv("SDOH_PRIVATE_DERIVATIVES_DIR", unset = "")
  if (!nzchar(value)) stop("SDOH_PRIVATE_DERIVATIVES_DIR is not set.")
  dir.create(value, recursive = TRUE, showWarnings = FALSE)
  normalizePath(value, mustWork = TRUE)
}

clean_names <- function(x) {
  x <- gsub("\u00a0", " ", x, fixed = TRUE)
  trimws(x)
}

read_source <- function() {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop("Package 'readxl' is required.")
  }
  sheets <- readxl::excel_sheets(source_path())
  if (length(sheets) != 1L) {
    stop("Expected one worksheet in the authoritative source; found ", length(sheets), ".")
  }
  d <- as.data.frame(readxl::read_excel(source_path(), sheet = sheets[[1]], guess_max = 10000))
  names(d) <- clean_names(names(d))
  if (anyDuplicated(names(d))) stop("Column names are duplicated after whitespace normalization.")
  d[] <- lapply(d, function(x) {
    if (!is.character(x)) return(x)
    y <- trimws(gsub("\u00a0", " ", x, fixed = TRUE))
    y[tolower(y) %in% c("", "na", "n/a")] <- NA_character_
    y
  })
  d
}

require_columns <- function(d, columns, label = "source") {
  missing <- setdiff(columns, names(d))
  if (length(missing)) stop(label, " is missing required columns: ", paste(missing, collapse = ", "))
  invisible(TRUE)
}

normalized_label <- function(x) {
  y <- tolower(trimws(as.character(x)))
  y[y %in% c("", "na", "n/a")] <- NA_character_
  y
}

map_item <- function(x, mapping, variable) {
  y <- normalized_label(x)
  out <- unname(mapping[y])
  unexpected <- !is.na(y) & !(y %in% names(mapping))
  if (any(unexpected)) {
    stop(variable, " contains ", sum(unexpected), " response(s) outside its documented response map.")
  }
  as.numeric(out)
}

complete_sum <- function(d) {
  m <- as.matrix(d)
  out <- rowSums(m, na.rm = FALSE)
  out[rowSums(!is.na(m)) != ncol(m)] <- NA_real_
  out
}

complete_mean <- function(d) complete_sum(d) / ncol(d)

available_mean <- function(d) {
  m <- as.matrix(d)
  n <- rowSums(!is.na(m))
  out <- rowSums(m, na.rm = TRUE) / n
  out[n == 0] <- NA_real_
  out
}

write_private_csv <- function(x, filename) {
  path <- file.path(derived_dir(), filename)
  utils::write.csv(x, path, row.names = FALSE, na = "")
  invisible(path)
}

read_private_csv <- function(filename) {
  path <- file.path(derived_dir(), filename)
  if (!file.exists(path)) stop("Required private pipeline output is missing: ", path)
  d <- utils::read.csv(path, check.names = FALSE, na.strings = c("", "NA", "N/A"))
  d[] <- lapply(d, function(x) {
    if (!is.character(x)) return(x)
    y <- trimws(gsub("\u00a0", " ", x, fixed = TRUE))
    y[tolower(y) %in% c("", "na", "n/a")] <- NA_character_
    y
  })
  d
}

model_terms <- function(fit) {
  sm <- summary(fit)$coefficients
  data.frame(
    term = rownames(sm),
    estimate = sm[, 1],
    SE = sm[, 2],
    CI_low = sm[, 1] - 1.96 * sm[, 2],
    CI_high = sm[, 1] + 1.96 * sm[, 2],
    p = sm[, 4],
    row.names = NULL,
    check.names = FALSE
  )
}

safe_formula_variables <- function(text) {
  tryCatch(all.vars(stats::as.formula(text)), error = function(e) character())
}
