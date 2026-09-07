source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "pipeline", "_helpers.R"))

reference_dir <- function() {
  path <- file.path(project_root(), "private-data", "reference")
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  normalizePath(path, mustWork = TRUE)
}

context_file <- function(name) file.path(derived_dir(), name)

normalize_zip <- function(x) {
  y <- trimws(as.character(x))
  y[y %in% c("", "NA", "N/A")] <- NA_character_
  numeric_like <- grepl("^[0-9]{1,5}(\\.0+)?$", y)
  y[numeric_like] <- sprintf("%05d", as.integer(sub("\\.0+$", "", y[numeric_like])))
  y[!grepl("^[0-9]{5}$", y)] <- NA_character_
  y
}

read_context_csv <- function(name) {
  path <- context_file(name)
  if (!file.exists(path)) stop("Missing private context output: ", path)
  d <- utils::read.csv(path, check.names = FALSE, colClasses = "character", na.strings = c("", "NA", "N/A"))
  d[] <- lapply(d, function(x) {
    y <- trimws(as.character(x))
    y[tolower(y) %in% c("", "na", "n/a")] <- NA_character_
    y
  })
  d
}

numeric_columns <- function(d, columns) {
  for (v in intersect(columns, names(d))) d[[v]] <- suppressWarnings(as.numeric(d[[v]]))
  d
}

write_context_csv <- function(d, name) {
  utils::write.csv(d, context_file(name), row.names = FALSE, na = "")
  invisible(context_file(name))
}

sha256 <- function(path) {
  line <- system2("shasum", c("-a", "256", shQuote(path)), stdout = TRUE, stderr = TRUE)
  if (!length(line) || !grepl("^[0-9a-fA-F]{64}[[:space:]]", line[[1]])) {
    stop("Could not calculate SHA256 for ", path)
  }
  sub("[[:space:]].*$", "", line[[1]])
}

zscore <- function(x) {
  if (sum(!is.na(x)) < 2L || stats::sd(x, na.rm = TRUE) == 0) return(rep(NA_real_, length(x)))
  as.numeric(scale(x))
}
