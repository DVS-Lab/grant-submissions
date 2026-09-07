source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "context", "_context_helpers.R"))
python <- Sys.getenv(
  "SDOH_CONTEXT_PYTHON",
  unset = file.path(reference_dir(), ".venv-context", "bin", "python")
)
if (!file.exists(python)) {
  stop(
    "PM2.5 spatial environment is missing. Create private-data/reference/.venv-context ",
    "and install geopandas, rasterio, xarray, netCDF4, exactextract, pandas, and numpy."
  )
}
script <- file.path(project_root(), "code", "context", "aggregate_pm25_zcta.py")
status <- system2(python, c(
  shQuote(script), "--reference-dir", shQuote(reference_dir()),
  "--derived-dir", shQuote(derived_dir()),
  "--manifest", shQuote(file.path(project_root(), "config", "reproducibility-sources.json"))
))
if (!identical(status, 0L)) stop("PM2.5 spatial aggregation failed with status ", status, ".")
message("Linked ACAG V5.NA.05 annual PM2.5, 2012–2022, using area-weighted 2020 ZCTA polygons.")
