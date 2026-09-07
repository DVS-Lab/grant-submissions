source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "pipeline", "_helpers.R"))
d <- read_source()
context_pattern <- "ec_zip|exposure_grp_mem_zip|gini|geo_f|adi|depriv|disadvant|social.?capital|economic.?connect|pm2|rural|urban|neighbo"
present <- grep(context_pattern, names(d), ignore.case = TRUE, value = TRUE)
present <- setdiff(present, "demo_quota")

ref <- utils::read.csv(file.path(project_root(), "derivatives", "model-screening", "all-models.csv"), check.names = FALSE)
formula_vars <- unique(unlist(lapply(unique(ref$model_formula), safe_formula_variables)))
historical <- intersect(formula_vars, c("ec_zip","exposure_grp_mem_zip","gini","geo_f"))

lines <- c(
  "# Private contextual-linkage audit",
  "",
  "## Authoritative N=709 workbook",
  "",
  paste0("- Contextual variables already present: ", if (length(present)) paste(present, collapse = ", ") else "none"),
  "- Current ZIP and childhood ZIP fields are present, remain private, and are excluded from the general analysis master.",
  "- `demo_quota` supplies a self-/sample-classification of urban, suburban, or rural residence; it is not a reconstructed geographic lookup.",
  "",
  "## Historical evidence",
  "",
  paste0("- Variables appearing in prior aggregate formulas but not in N=709: ", paste(historical, collapse = ", "), "."),
  "- Git commit `f120e48` added a historical address/GIS notebook. It used the Census Geocoder endpoint `https://geocoding.geo.census.gov/geocoder/geographies/onelineaddress` with `Public_AR_Current` / `Current_Current`, then joined Census block-group FIPS to local Neighborhood Atlas ADI files.",
  "- The notebook also expected local NetCDF PM2.5 files and extracted 2021, 2022, and 2023 values before averaging them. It did not identify the PM2.5 data provider or a download URL.",
  "- No original prior model-screen generator was found in reachable Git history; the current pipeline reconstructs a formula-driven runner from the aggregate reference.",
  "",
  "## Reproduction status",
  "",
  "Current-ZIP linkage was not reconstructed. A ZIP-only substitution would not reproduce the historical address-to-block-group workflow, and the evidence does not establish a defensible ADI release year, PM2.5 provider/file version, or rurality source.",
  "",
  "Exact missing inputs:",
  "",
  "1. the intended contextual construct(s) and direction/coding for `ec_zip`, `exposure_grp_mem_zip`, `gini`, and `geo_f`;",
  "2. the Neighborhood Atlas ADI release/vintage and corresponding block-group lookup files;",
  "3. the PM2.5 dataset provider, product/version, spatial resolution, and exact NetCDF files;",
  "4. the source/vintage and coding rule for any geographic rurality variable;",
  "5. confirmation that a new ZIP-level linkage is scientifically acceptable in place of the historical address-level geocode.",
  "",
  "Once a reviewed private linkage keyed by `study_id` is written as `current-zip-context.csv` (or supplied through `SDOH_CONTEXT_DATA`), the analysis-master builder will join non-ZIP/non-coordinate context variables automatically. Set `SDOH_CONTEXT_VARIABLE` to the primary reviewed exposure for context models."
)
writeLines(lines, file.path(derived_dir(), "context-linkage-audit.md"))
cat("Wrote private contextual-linkage audit; no unverified linkage was performed.\n")
