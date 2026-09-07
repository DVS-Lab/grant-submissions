source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "context", "_context_helpers.R"))

inputs <- c(
  "context-deprivation.csv", "context-pm25.csv", "context-social-capital.csv",
  "context-income-inequality.csv", "context-rurality.csv"
)
parts <- lapply(inputs, read_context_csv)
for (i in seq_along(parts)) {
  require_columns(parts[[i]], "study_id", inputs[[i]])
  if (anyDuplicated(parts[[i]]$study_id)) stop(inputs[[i]], " has duplicate study_id values.")
}
context <- Reduce(function(x, y) merge(x, y, by = "study_id", all = TRUE, sort = FALSE), parts)
numeric_vars <- setdiff(names(context), c("study_id", "ruca_category"))
context <- numeric_columns(context, numeric_vars)

standardize <- c(
  sdi_zcta = "z_sdi",
  pm25_2012_2022_zcta = "z_pm25",
  pm25_recent_mean = "z_pm25_recent",
  pm25_variability = "z_pm25_variability",
  gini_zcta = "z_gini",
  socialcap_economic_connectedness = "z_economic_connectedness",
  socialcap_high_ses_exposure = "z_high_ses_exposure",
  socialcap_friending_bias = "z_friending_bias",
  socialcap_cohesiveness = "z_cohesiveness",
  socialcap_support_ratio = "z_support_ratio",
  socialcap_volunteering = "z_volunteering",
  socialcap_civic_organizations = "z_civic_organizations"
)
for (raw in names(standardize)) context[[standardize[[raw]]]] <- zscore(context[[raw]])
context$z_ruca <- zscore(context$ruca_primary)
context$risk_low_social_capital <- -context$z_economic_connectedness

burden_components <- c("z_sdi", "z_pm25", "z_gini", "risk_low_social_capital")
burden <- as.matrix(context[burden_components])
n_available <- rowSums(!is.na(burden))
context$env_burden_components_available <- n_available
context$env_burden_simple <- rowMeans(burden, na.rm = TRUE)
context$env_burden_simple[n_available < 3L] <- NA_real_

write_context_csv(context, "current-zip-context.csv")

corr_vars <- c(
  "sdi_zcta", "pm25_2012_2022_zcta", "gini_zcta",
  "socialcap_economic_connectedness", "socialcap_high_ses_exposure",
  "socialcap_friending_bias", "socialcap_cohesiveness", "socialcap_support_ratio",
  "socialcap_volunteering", "socialcap_civic_organizations", "ruca_primary"
)
corr <- stats::cor(context[corr_vars], use = "pairwise.complete.obs")
atomic_write_csv(corr, context_file("context-correlation.csv"), row.names = TRUE)
correlation_png <- tempfile(pattern = ".context-correlation-", tmpdir = derived_dir(), fileext = ".png.part")
png(correlation_png, width = 1900, height = 1700, res = 220)
par(mar = c(12, 12, 3, 2))
image(seq_len(ncol(corr)), seq_len(nrow(corr)), t(corr[nrow(corr):1, ]),
      col = grDevices::colorRampPalette(c("#8b1e3f", "white", "#216869"))(101),
      zlim = c(-1, 1), axes = FALSE, xlab = "", ylab = "",
      main = "Participant-weighted correlations among current-ZIP context measures")
axis(1, at = seq_len(ncol(corr)), labels = colnames(corr), las = 2, cex.axis = .65)
axis(2, at = seq_len(nrow(corr)), labels = rev(rownames(corr)), las = 2, cex.axis = .65)
for (i in seq_len(nrow(corr))) for (j in seq_len(ncol(corr))) {
  value <- corr[nrow(corr) - i + 1L, j]
  text(j, i, ifelse(is.na(value), "NA", sprintf("%.2f", value)), cex = .54)
}
box()
dev.off()
if (!file.rename(correlation_png, context_file("context-correlation.png"))) stop("Could not install correlation figure.")

pair_index <- which(upper.tri(corr) & abs(corr) >= .70, arr.ind = TRUE)
flagged <- if (nrow(pair_index)) data.frame(
  variable_1 = rownames(corr)[pair_index[, 1]],
  variable_2 = colnames(corr)[pair_index[, 2]],
  r = corr[pair_index],
  threshold = ifelse(abs(corr[pair_index]) >= .85, "|r| >= .85", "|r| >= .70"),
  row.names = NULL
) else data.frame(variable_1=character(), variable_2=character(), r=numeric(), threshold=character())
write_context_csv(flagged, "context-correlation-flags.csv")
message("Built private context master and exposure-redundancy audit.")
