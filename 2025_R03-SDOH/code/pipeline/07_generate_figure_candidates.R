source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "pipeline", "_helpers.R"))
if (!requireNamespace("ggplot2", quietly = TRUE)) stop("Package 'ggplot2' is required.")
d <- read_private_csv("analysis-master.csv")
fig_dir <- file.path(derived_dir(), "figures")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
index <- list()

save_main_effect <- function(outcome, y_label, filename, question, caveat) {
  keep <- stats::complete.cases(d[c("ecog_total", outcome)])
  n <- sum(keep)
  if (n < 20L) return(invisible(FALSE))
  p <- ggplot2::ggplot(d[keep, ], ggplot2::aes(x = .data$ecog_total, y = .data[[outcome]])) +
    ggplot2::geom_point(alpha = 0.25, size = 1.4, color = "#3C6E71") +
    ggplot2::geom_smooth(method = "lm", se = TRUE, color = "#8B1E3F", fill = "#DDB7C0") +
    ggplot2::labs(x = "eCog mean score", y = y_label, title = question, subtitle = paste0("Fixed candidate analysis; N = ", n)) +
    ggplot2::theme_minimal(base_size = 12)
  ggplot2::ggsave(file.path(fig_dir, filename), p, width = 7, height = 5, dpi = 300)
  index[[length(index) + 1L]] <<- list(filename=filename, question=question,
    model=paste0(outcome, " ~ ecog_total"), N=n, kind="new fixed candidate question", caveat=caveat)
  invisible(TRUE)
}

save_interaction <- function(outcome, y_label, filename, question, caveat) {
  keep <- stats::complete.cases(d[c("ecog_total", "mspss_total", outcome)])
  dat <- d[keep, ]
  n <- nrow(dat)
  if (n < 20L) return(invisible(FALSE))
  fit <- stats::lm(stats::as.formula(paste0(outcome, " ~ ecog_total * mspss_total")), data = dat)
  support <- mean(dat$mspss_total) + c(-1, 0, 1) * stats::sd(dat$mspss_total)
  grid <- expand.grid(ecog_total = seq(min(dat$ecog_total), max(dat$ecog_total), length.out = 80), mspss_total = support)
  pred <- stats::predict(fit, newdata = grid, interval = "confidence")
  grid$fit <- pred[,"fit"]; grid$lwr <- pred[,"lwr"]; grid$upr <- pred[,"upr"]
  grid$support_level <- factor(rep(c("Lower support","Mean support","Higher support"), each=80),
                               levels=c("Lower support","Mean support","Higher support"))
  p <- ggplot2::ggplot(grid, ggplot2::aes(x=.data$ecog_total, y=.data$fit, color=.data$support_level, fill=.data$support_level)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin=.data$lwr, ymax=.data$upr), alpha=.12, color=NA) +
    ggplot2::geom_line(linewidth=1) +
    ggplot2::labs(x="eCog mean score", y=y_label, color="MSPSS", fill="MSPSS", title=question,
                  subtitle=paste0("Predicted values at mean and ±1 SD support; N = ", n)) +
    ggplot2::theme_minimal(base_size=12)
  ggplot2::ggsave(file.path(fig_dir, filename), p, width=7, height=5, dpi=300)
  index[[length(index) + 1L]] <<- list(filename=filename, question=question,
    model=paste0(outcome, " ~ ecog_total * mspss_total"), N=n, kind="new fixed candidate question", caveat=caveat)
  invisible(TRUE)
}

save_main_effect("fevs_total", "FEVS total (0–18)", "ecog-fevs.png", "Subjective cognition and financial vulnerability", "Cross-sectional association; no causal interpretation.")
save_main_effect("oafem_unweighted_complete", "OAFEM unweighted complete-case diagnostic", "ecog-oafem-provisional.png", "Subjective cognition and exploitation indicators", "OAFEM severity weights are unresolved; this figure is provisional.")
save_interaction("fevs_total", "Predicted FEVS total", "ecog-mspss-fevs.png", "Cognition × social support and financial vulnerability", "Cross-sectional interaction; fixed in advance of result inspection.")
save_interaction("oafem_unweighted_complete", "Predicted OAFEM unweighted diagnostic", "ecog-mspss-oafem-provisional.png", "Cognition × social support and exploitation indicators", "OAFEM severity weights are unresolved; this figure is provisional.")

lines <- c("# Private draft figure index", "", "Figures were generated systematically for every currently runnable high-priority eCog model family; none were selected by p-value.", "")
for (x in index) {
  lines <- c(lines, paste0("## `", x$filename, "`"), "",
    paste0("- Scientific question: ", x$question), paste0("- Variables/model: `", x$model, "`"),
    paste0("- N: ", x$N), paste0("- Classification: ", x$kind), paste0("- Caveat: ", x$caveat), "")
}
context_note <- if (!nzchar(Sys.getenv("SDOH_CONTEXT_VARIABLE", unset=""))) "Context figures were not generated because no verified contextual linkage variable is available." else "Context figures require a separately reviewed plotting specification."
lines <- c(lines, "## Context-dependent figures", "", context_note)
writeLines(lines, file.path(derived_dir(), "figure-index.md"))
cat("Generated ", length(index), " private draft figures.\n", sep = "")
