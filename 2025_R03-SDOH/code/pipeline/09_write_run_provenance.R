source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "pipeline", "_helpers.R"))
if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Package 'jsonlite' is required.")

source_file <- source_path()
sheet <- readxl::excel_sheets(source_file)
d <- read_source()
python <- Sys.getenv("SDOH_CONTEXT_PYTHON")
python_version <- system2(python, "--version", stdout = TRUE, stderr = TRUE)
python_packages <- jsonlite::fromJSON(system2(python, c("-m", "pip", "list", "--format=json"), stdout = TRUE))
package_names <- c("readxl", "jsonlite", "ggplot2", "MASS", "renv")
r_packages <- setNames(lapply(package_names, function(x) as.character(utils::packageVersion(x))), package_names)
cache_log <- Sys.getenv("SDOH_CACHE_LOG", unset = "")
cache_events <- if (file.exists(cache_log) && file.info(cache_log)$size > 0) {
  utils::read.delim(cache_log, header = FALSE, col.names = c("source_id", "local_filename", "action"), stringsAsFactors = FALSE)
} else data.frame(source_id = character(), local_filename = character(), action = character())
git_sha <- system2("git", c("-C", shQuote(project_root()), "rev-parse", "HEAD"), stdout = TRUE)
platform <- Sys.info()[c("sysname", "release", "machine")]
record <- list(
  status = "completed",
  completed_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  git_commit = git_sha[[1]],
  authoritative_workbook = list(filename = basename(source_file), sha256 = sha256_file(source_file),
                                worksheet = sheet[[1]], rows = nrow(d), columns = ncol(d)),
  runtime = list(R = R.version.string, platform = as.list(platform), R_packages = r_packages,
                 Python = python_version[[1]], Python_packages = python_packages),
  dependency_environment = list(
    python = Sys.getenv("SDOH_PYTHON_ENV_ACTION", unset = "unknown"),
    R = Sys.getenv("SDOH_R_ENV_ACTION", unset = "unknown"),
    custom_python = nzchar(Sys.getenv("SDOH_CUSTOM_PYTHON", unset = ""))
  ),
  configuration = list(source_manifest = "config/reproducibility-sources.json",
                       reproduction_contract = "config/reproduction-contract.json",
                       python_lock = "code/context/requirements-lock.txt", R_lock = "renv.lock"),
  public_source_cache = cache_events
)
path <- file.path(derived_dir(), "run-provenance.json")
atomic_path(path, function(temporary) jsonlite::write_json(record, temporary, pretty = TRUE, auto_unbox = TRUE, na = "null"))
message("Wrote private completed run provenance.")
