source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "pipeline", "_helpers.R"))
d <- read_private_csv("analysis-master.csv")
if (nrow(d) != 709L || anyDuplicated(d$study_id)) stop("Analysis master must contain 709 unique participants.")
if (any(vapply(d, function(x) is.character(x) && any(trimws(x) == "", na.rm=TRUE), logical(1)))) stop("Blank pseudo-levels remain after private data import.")

for (v in c("demo_gender", "ses_thi", "ses_edu", "demo_quota", "ruca_category")) d[[v]] <- factor(d[[v]])
d$age_c <- d$demo_yrs - mean(d$demo_yrs, na.rm=TRUE)
d$ecog_c <- d$ecog_total - mean(d$ecog_total, na.rm=TRUE)
d$mspss_c <- d$mspss_total - mean(d$mspss_total, na.rm=TRUE)
d$uclal_c <- d$uclal_total - mean(d$uclal_total, na.rm=TRUE)
d$ntb_c <- d$ntb_mean - mean(d$ntb_mean, na.rm=TRUE)
d$residence_duration_ordered <- ordered(d$demo_zip_prim_yr,
  levels=c("Less than one year","1-5 years","6-10 years","More than 10 years"))
d$resident_ge6 <- ifelse(is.na(d$demo_zip_prim_yr), NA_integer_, as.integer(d$demo_zip_prim_yr %in% c("6-10 years","More than 10 years")))
d$resident_gt10 <- ifelse(is.na(d$demo_zip_prim_yr), NA_integer_, as.integer(d$demo_zip_prim_yr == "More than 10 years"))
d$log1p_oafem <- log1p(d$oafem_weighted_total)

exposures <- data.frame(
  key=c("SDI","PM25","GINI","EC","RUCA"),
  z=c("z_sdi","z_pm25","z_gini","z_economic_connectedness","z_ruca"),
  raw=c("sdi_zcta","pm25_2012_2022_zcta","gini_zcta","socialcap_economic_connectedness","ruca_primary"),
  label=c("social deprivation","2012–2022 PM2.5","income inequality","economic connectedness","rurality"),
  stringsAsFactors=FALSE)
require_columns(d, unique(c(exposures$z, exposures$raw)))
covars <- "age_c + demo_gender + ses_thi + ses_edu"
specs <- list()
add_spec <- function(id, family, question, formula, fit="lm", subset="full", exposure="", scale="standardized") {
  specs[[length(specs)+1L]] <<- data.frame(model_id=id, family=family, scientific_question=question,
    formula=formula, fit=fit, analytic_subset=subset, exposure=exposure, exposure_scale=scale,
    stringsAsFactors=FALSE)
}

# Family A: each available core domain against the four financial outcomes.
a_outcomes <- data.frame(key=c("FEVS","OAFEM","FRAUD_LIFE","FRAUD_12MO"),
  var=c("fevs_total","oafem_weighted_total","fraud_lifetime_any","fraud_12mo_any"),
  fit=c("lm","lm","binomial","binomial"), stringsAsFactors=FALSE)
for (i in seq_len(nrow(exposures))) for (j in seq_len(nrow(a_outcomes))) {
  e <- exposures[i,]; o <- a_outcomes[j,]; q <- paste(e$label,"and",o$key,"financial vulnerability")
  add_spec(paste("A",e$key,o$key,"UNADJ",sep="_"), "A — environment to financial vulnerability", q,
    paste(o$var,"~",e$z), o$fit, exposure=e$z)
  add_spec(paste("A",e$key,o$key,"ADJ",sep="_"), "A — environment to financial vulnerability", q,
    paste(o$var,"~",e$z,"+",covars), o$fit, exposure=e$z)
}
for (i in seq_len(nrow(exposures))) for (outcome in c("fevs_total","oafem_weighted_total","ctb_mean")) {
  e <- exposures[i,]
  add_spec(paste("A_RAW",e$key,toupper(sub("_.*$","",outcome)),sep="_"), "A/C — raw-unit effect sensitivity",
    paste("Raw-unit",e$label,"effect"), paste(outcome,"~",e$raw,"+",covars), "lm", exposure=e$raw, scale="raw")
}
for (i in seq_len(nrow(exposures))) {
  e <- exposures[i,]
  for (outcome in c("fraud_lifetime_band","fraud_12mo_band")) add_spec(
    paste("A_ORD",e$key,outcome,sep="_"), "A — ordinal fraud sensitivity", paste("Ordinal loss band and",e$label),
    paste("ordered(",outcome,") ~ ",e$z," + ",covars), "ordinal", exposure=e$z)
  add_spec(paste("A_OAFEM_QP",e$key,sep="_"), "A — OAFEM distribution sensitivity", paste("Quasi-Poisson OAFEM and",e$label),
    paste("oafem_weighted_total ~",e$z,"+",covars), "quasipoisson", exposure=e$z)
  add_spec(paste("A_OAFEM_LOG",e$key,sep="_"), "A — OAFEM distribution sensitivity", paste("log1p OAFEM and",e$label),
    paste("log1p_oafem ~",e$z,"+",covars), "lm", exposure=e$z)
}

# Family B: cognition/mood for all core exposures; PROMIS domains are concept-mapped.
for (i in seq_len(nrow(exposures))) for (outcome in c("ecog_total","susd_depression")) {
  e <- exposures[i,]
  add_spec(paste("B",e$key,outcome,"UNADJ",sep="_"), "B — cognition, mood, and health", paste(e$label,"and",outcome),
    paste(outcome,"~",e$z), "lm", exposure=e$z)
  add_spec(paste("B",e$key,outcome,"ADJ",sep="_"), "B — cognition, mood, and health", paste(e$label,"and",outcome),
    paste(outcome,"~",e$z,"+",covars), "lm", exposure=e$z)
}
promis_map <- list(
  SDI=c("promis_depression_t","promis_anxiety_t","promis_physical_function_t","promis_pain_interference_t","promis_sleep_disturbance_t","promis_social_roles_t"),
  PM25=c("promis_depression_t","promis_physical_function_t","promis_pain_interference_t","promis_sleep_disturbance_t"),
  GINI=c("promis_depression_t","promis_anxiety_t","promis_social_roles_t"),
  EC=c("promis_depression_t","promis_anxiety_t","promis_social_roles_t"),
  RUCA=c("promis_physical_function_t","promis_sleep_disturbance_t","promis_social_roles_t"))
for (i in seq_len(nrow(exposures))) for (outcome in promis_map[[exposures$key[i]]]) {
  e <- exposures[i,]
  add_spec(paste("B_PROMIS",e$key,outcome,sep="_"), "B — concept-prioritized PROMIS", paste(e$label,"and",outcome),
    paste(outcome,"~",e$z,"+",covars), "lm", exposure=e$z)
}

# Family C: CTB, including the PM2.5 model aligned with the prior lab paper.
for (i in seq_len(nrow(exposures))) {
  e <- exposures[i,]
  add_spec(paste("C",e$key,"CTB_UNADJ",sep="_"), "C — decision process", paste(e$label,"and CTB"),
    paste("ctb_mean ~",e$z), "lm", exposure=e$z)
  add_spec(paste("C",e$key,"CTB_ADJ",sep="_"), "C — decision process", paste(e$label,"and CTB"),
    paste("ctb_mean ~",e$z,"+",covars), "lm", exposure=e$z)
}

# Family D: age moderation on five grant-priority outcomes only.
for (i in seq_len(nrow(exposures))) for (outcome in c("fevs_total","oafem_weighted_total","ecog_total","susd_depression","ctb_mean")) {
  e <- exposures[i,]
  add_spec(paste("D",e$key,outcome,sep="_"), "D — age as vulnerability moderator", paste("Age moderation of",e$label,"for",outcome),
    paste(outcome,"~",e$z,"* age_c + demo_gender + ses_thi + ses_edu"), "lm", exposure=e$z)
}

# Family E: cognitive vulnerability main effects and context moderation.
for (outcome in c("fevs_total","oafem_weighted_total","fraud_lifetime_any","fraud_12mo_any")) {
  fit <- if (grepl("fraud",outcome)) "binomial" else "lm"
  add_spec(paste("E_ECOG",outcome,sep="_"), "E — cognitive vulnerability", paste("eCog and",outcome),
    paste(outcome,"~ ecog_c +",covars), fit, exposure="ecog_c")
}
for (i in seq_len(nrow(exposures))) for (outcome in c("fevs_total","oafem_weighted_total")) {
  e <- exposures[i,]
  add_spec(paste("E",e$key,outcome,sep="_"), "E — context by cognitive vulnerability", paste(e$label,"by eCog for",outcome),
    paste(outcome,"~",e$z,"* ecog_c +",covars), "lm", exposure=e$z)
}

# Family F: primary MSPSS buffering and narrower loneliness/Need-to-Belong tests.
for (i in seq_len(nrow(exposures))) for (outcome in c("fevs_total","oafem_weighted_total","susd_depression","ecog_total")) {
  e <- exposures[i,]
  add_spec(paste("F_MSPSS",e$key,outcome,sep="_"), "F — social-resource buffering", paste(e$label,"by MSPSS for",outcome),
    paste(outcome,"~",e$z,"* mspss_c +",covars), "lm", exposure=e$z)
}
for (key in c("SDI","PM25","EC")) for (moderator in c("uclal_c","ntb_c")) for (outcome in c("fevs_total","oafem_weighted_total")) {
  e <- exposures[exposures$key==key,]
  add_spec(paste("F",moderator,key,outcome,sep="_"), "F — selected psychosocial moderation", paste(e$label,"by",moderator,"for",outcome),
    paste(outcome,"~",e$z,"*",moderator,"+",covars), "lm", exposure=e$z)
}

# Family G: grant-priority long-residence comparisons and interactions.
g_pairs <- list(c("PM25","ctb_mean"),c("SDI","fevs_total"),c("SDI","oafem_weighted_total"),c("EC","fevs_total"),c("EC","oafem_weighted_total"))
for (pair in g_pairs) {
  e <- exposures[exposures$key==pair[[1]],]; outcome <- pair[[2]]
  for (subset_name in c("resident_ge6","resident_gt10")) add_spec(
    paste("G",pair[[1]],outcome,subset_name,sep="_"), "G — residence-duration sensitivity", paste(e$label,"and",outcome,"among",subset_name),
    paste(outcome,"~",e$z,"+",covars), "lm", subset=subset_name, exposure=e$z)
  add_spec(paste("G_INT",pair[[1]],outcome,sep="_"), "G — residence-duration diagnostic", paste("Residence moderation of",e$label,"for",outcome),
    paste(outcome,"~",e$z,"* resident_ge6 +",covars), "lm", exposure=e$z)
}
for (exposure in c("z_high_ses_exposure","env_burden_simple")) for (outcome in c("fevs_total","oafem_weighted_total","ctb_mean")) add_spec(
  paste("S",exposure,outcome,sep="_"), "S — secondary contextual sensitivity", paste(exposure,"and",outcome),
  paste(outcome,"~",exposure,"+",covars), "lm", exposure=exposure)

specs <- do.call(rbind,specs)
if (anyDuplicated(specs$model_id)) stop("Fixed model IDs are not unique.")
write_private_csv(specs,"grant-model-specifications.csv")

failure_row <- function(spec,status) data.frame(model_id=spec$model_id,family=spec$family,scientific_question=spec$scientific_question,
  formula=spec$formula,fit=spec$fit,analytic_subset=spec$analytic_subset,exposure=spec$exposure,exposure_scale=spec$exposure_scale,
  N=NA_integer_,term="",estimate=NA_real_,SE=NA_real_,CI_low=NA_real_,CI_high=NA_real_,p=NA_real_,
  effect_ratio=NA_real_,ratio_CI_low=NA_real_,ratio_CI_high=NA_real_,status=status,check.names=FALSE)
fit_one <- function(spec) {
  dat <- d
  if (spec$analytic_subset=="resident_ge6") dat <- dat[dat$resident_ge6==1L & !is.na(dat$resident_ge6),]
  if (spec$analytic_subset=="resident_gt10") dat <- dat[dat$resident_gt10==1L & !is.na(dat$resident_gt10),]
  missing <- setdiff(safe_formula_variables(spec$formula),names(dat))
  if (length(missing)) return(failure_row(spec,paste("NOT RUNNABLE:",paste(missing,collapse=";"))))
  fit <- tryCatch({
    f <- stats::as.formula(spec$formula)
    if (spec$fit=="binomial") stats::glm(f,data=dat,family=stats::binomial(),na.action=stats::na.omit)
    else if (spec$fit=="quasipoisson") stats::glm(f,data=dat,family=stats::quasipoisson(link="log"),na.action=stats::na.omit)
    else if (spec$fit=="ordinal") {
      if (!requireNamespace("MASS",quietly=TRUE)) stop("MASS unavailable")
      MASS::polr(f,data=dat,Hess=TRUE,na.action=stats::na.omit,method="logistic")
    } else stats::lm(f,data=dat,na.action=stats::na.omit)
  },error=identity)
  if (inherits(fit,"error")) return(failure_row(spec,paste("FIT FAILED:",conditionMessage(fit))))
  if (spec$fit=="ordinal") {
    co <- coef(summary(fit)); keep <- seq_len(length(stats::coef(fit)))
    terms <- data.frame(term=rownames(co)[keep],estimate=co[keep,"Value"],SE=co[keep,"Std. Error"])
    terms$CI_low <- terms$estimate-1.96*terms$SE; terms$CI_high <- terms$estimate+1.96*terms$SE
    terms$p <- 2*stats::pnorm(abs(terms$estimate/terms$SE),lower.tail=FALSE); n <- stats::nobs(fit)
  } else {terms <- model_terms(fit); n <- stats::nobs(fit)}
  ratio_family <- spec$fit %in% c("binomial","ordinal","quasipoisson")
  terms$effect_ratio <- if(ratio_family) exp(terms$estimate) else NA_real_
  terms$ratio_CI_low <- if(ratio_family) exp(terms$CI_low) else NA_real_
  terms$ratio_CI_high <- if(ratio_family) exp(terms$CI_high) else NA_real_
  cbind(data.frame(model_id=spec$model_id,family=spec$family,scientific_question=spec$scientific_question,
    formula=spec$formula,fit=spec$fit,analytic_subset=spec$analytic_subset,exposure=spec$exposure,
    exposure_scale=spec$exposure_scale,N=n),terms,status="RUN",row.names=NULL)
}
results <- do.call(rbind,lapply(seq_len(nrow(specs)),function(i) fit_one(specs[i,])))
write_private_csv(results,"grant-candidate-results.csv")
status <- aggregate(status~model_id,results,function(x)x[[1]])
cat("Evaluated ",nrow(specs)," fixed grant model specifications: ",sum(status$status=="RUN")," ran; ",sum(status$status!="RUN")," unavailable/failed.\n",sep="")
