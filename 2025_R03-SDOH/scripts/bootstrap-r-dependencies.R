#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) stop("Usage: bootstrap-r-dependencies.R PROJECT_ROOT LIBRARY LOCKFILE")
project <- normalizePath(args[[1]], mustWork = TRUE)
library <- args[[2]]
lockfile <- normalizePath(args[[3]], mustWork = TRUE)
dir.create(library, recursive = TRUE, showWarnings = FALSE)
library <- normalizePath(library, mustWork = TRUE)
bootstrap <- file.path(project, "private-data", "reference", ".r-bootstrap")
cache <- file.path(project, "private-data", "reference", ".renv-cache")
dir.create(bootstrap, recursive = TRUE, showWarnings = FALSE)
dir.create(cache, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(bootstrap, library, .libPaths()))
Sys.setenv(RENV_PATHS_CACHE = cache)

renv_version <- "1.2.4"
renv_url <- "https://github.com/rstudio/renv/archive/refs/tags/v1.2.4.tar.gz"
renv_sha <- "28989155097d2cbf3022b39744d67c278db6a2977a8d763ddf87fbe98c82669b"
sha256 <- function(path) {
  out <- system2("shasum", c("-a", "256", shQuote(path)), stdout = TRUE)
  sub("[[:space:]].*$", "", out[[1]])
}
if (!requireNamespace("renv", quietly = TRUE) || as.character(utils::packageVersion("renv")) != renv_version) {
  archive <- tempfile(fileext = ".tar.gz")
  on.exit(unlink(archive), add = TRUE)
  ok <- FALSE
  for (attempt in 1:3) {
    status <- try(utils::download.file(renv_url, archive, mode = "wb", quiet = TRUE, timeout = 300), silent = TRUE)
    if (!inherits(status, "try-error") && identical(sha256(archive), renv_sha)) { ok <- TRUE; break }
  }
  if (!ok) stop("Could not download and verify renv ", renv_version, ".")
  utils::install.packages(archive, repos = NULL, type = "source", lib = bootstrap, quiet = TRUE)
}

if (as.character(utils::packageVersion("renv")) != renv_version) stop("Unexpected renv version.")
lock <- renv::lockfile_read(lockfile)
locked <- vapply(lock$Packages, function(x) x$Version, character(1))
installed_local <- vapply(names(locked), function(package) {
  description <- suppressWarnings(tryCatch(utils::packageDescription(package, lib.loc = library), error = function(e) NA))
  if (length(description) < 1L || all(is.na(description)) || !("Version" %in% names(description))) NA_character_
  else unname(description[["Version"]])
}, character(1))
normalize_version <- function(x) gsub("-", ".", x, fixed = TRUE)
needed <- names(locked)[is.na(installed_local) | normalize_version(installed_local) != normalize_version(locked)]
if (length(needed)) {
  message("Restoring ", length(needed), " exact package(s) into the isolated R library")
  specs <- paste0(needed, "@", locked[needed])
  renv::install(specs, library = library, prompt = FALSE)
} else message("Isolated R library already matches renv.lock")

required <- c(readxl = "1.4.5", jsonlite = "2.0.0", ggplot2 = "4.0.1", MASS = "7.3-65")
for (package in names(required)) {
  if (!requireNamespace(package, quietly = TRUE)) stop("Missing R package after restore: ", package)
  if (normalize_version(as.character(utils::packageVersion(package))) != normalize_version(required[[package]])) {
    stop("R package version mismatch for ", package, ".")
  }
}
