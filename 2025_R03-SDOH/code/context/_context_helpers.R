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
  atomic_write_csv(d, context_file(name))
  invisible(context_file(name))
}

sha256 <- function(path) {
  line <- system2("shasum", c("-a", "256", shQuote(path)), stdout = TRUE, stderr = TRUE)
  if (!length(line) || !grepl("^[0-9a-fA-F]{64}[[:space:]]", line[[1]])) {
    stop("Could not calculate SHA256 for ", path)
  }
  sub("[[:space:]].*$", "", line[[1]])
}

source_manifest <- function() {
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Package 'jsonlite' is required.")
  path <- file.path(project_root(), "config", "reproducibility-sources.json")
  jsonlite::fromJSON(path, simplifyVector = FALSE)$sources
}

source_entry <- function(id) {
  entries <- source_manifest()
  hits <- vapply(entries, function(x) identical(x$id, id), logical(1))
  if (sum(hits) != 1L) stop("Expected exactly one source-manifest entry for ", id, ".")
  entries[[which(hits)]]
}

cache_event <- function(id, filename, action) {
  path <- Sys.getenv("SDOH_CACHE_LOG", unset = "")
  if (!nzchar(path)) return(invisible(NULL))
  line <- paste(id, filename, action, sep = "\t")
  cat(line, "\n", file = path, append = TRUE, sep = "")
  invisible(NULL)
}

download_verified <- function(entry, destination = file.path(reference_dir(), entry$local_filename)) {
  expected_bytes <- as.numeric(entry$bytes)
  valid <- file.exists(destination) &&
    identical(unname(file.info(destination)$size), expected_bytes) &&
    identical(tolower(sha256(destination)), tolower(entry$sha256))
  if (valid) {
    cache_event(entry$id, entry$local_filename, "reused")
    validate_tabular_source(entry, destination)
    return(invisible(destination))
  }
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  temporary <- paste0(destination, ".part")
  on.exit(unlink(temporary), add = TRUE)
  fallback_urls <- if (is.null(entry$fallback_urls)) character() else unlist(entry$fallback_urls)
  download_urls <- c(entry$url, fallback_urls)
  installed <- FALSE
  for (download_url in download_urls) {
    unlink(temporary)
    status <- system2("curl", c(
      "--fail", "--location", "--compressed", "--retry", "3", "--retry-all-errors",
      "--connect-timeout", "30", "--max-time", "900",
      "--output", shQuote(temporary), shQuote(download_url)
    ))
    if (!identical(status, 0L) || !file.exists(temporary)) next
    actual_bytes <- unname(file.info(temporary)$size)
    actual_sha <- sha256(temporary)
    if (identical(actual_bytes, expected_bytes) &&
        identical(tolower(actual_sha), tolower(entry$sha256))) {
      installed <- TRUE
      break
    }
    warning("Checksum or byte-size mismatch from one configured URL for public source ", entry$id, "; trying the next configured URL.")
  }
  if (!installed) stop("No configured HTTPS URL returned the checksum-pinned bytes for public source ", entry$id, ".")
  if (!file.rename(temporary, destination)) stop("Could not install downloaded source ", entry$id, ".")
  cache_event(entry$id, entry$local_filename, "downloaded")
  validate_tabular_source(entry, destination)
  invisible(destination)
}

validate_tabular_source <- function(entry, path) {
  extension <- tolower(tools::file_ext(path))
  if (!(extension %in% c("csv", "dat")) || is.null(entry$expected_columns)) return(invisible(TRUE))
  data <- if (extension == "dat") utils::read.delim(path, sep = "|", quote = "", colClasses = "character", check.names = FALSE)
          else utils::read.csv(path, nrows = if (is.null(entry$expected_rows)) -1L else as.integer(entry$expected_rows) + 1L,
                               check.names = FALSE, colClasses = "character")
  missing <- setdiff(unlist(entry$expected_columns), names(data))
  if (length(missing)) stop("Public source ", entry$id, " is missing expected column(s): ", paste(missing, collapse = ", "))
  if (!is.null(entry$expected_rows) && nrow(data) != as.integer(entry$expected_rows)) {
    stop("Public source ", entry$id, " has ", nrow(data), " rows; expected ", entry$expected_rows, ".")
  }
  invisible(TRUE)
}

zscore <- function(x) {
  if (sum(!is.na(x)) < 2L || stats::sd(x, na.rm = TRUE) == 0) return(rep(NA_real_, length(x)))
  as.numeric(scale(x))
}
