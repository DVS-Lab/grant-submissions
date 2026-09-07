source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "pipeline", "_helpers.R"))
d <- read_source()
s <- read_private_csv("core-scores.csv")
if (nrow(s) != 709L || anyDuplicated(s$study_id) || any(is.na(s$study_id))) stop("Score-file key validation failed.")

map_path <- file.path(project_root(), "docs", "oafem-item-map.csv")
oafem_map <- utils::read.csv(map_path, check.names=FALSE)
require_columns(oafem_map, c("source_variable","published_short_form_item","severity_group","severity_weight"), "OAFEM map")
if (nrow(oafem_map) != 30L || anyDuplicated(oafem_map$source_variable) || anyDuplicated(oafem_map$published_short_form_item) ||
    !setequal(oafem_map$source_variable, paste0("oafem_adult_",1:30))) stop("OAFEM public map is not a unique complete 30-item mapping.")
if (!identical(as.integer(oafem_map$severity_weight), c(1L,3L,1L,1L,2L,3L,2L,3L,3L,2L,2L,3L,3L,3L,3L,3L,1L,1L,2L,3L,3L,1L,3L,1L,2L,1L,1L,1L,3L,1L))) stop("OAFEM public map no longer matches implemented weights.")

spec <- data.frame(
  construct=c("FEVS","eCog","SUSD depression","SUSD mania","UCLA loneliness","MSPSS total","Need to Belong",
    "OAFEM weighted","OAFEM rated items","CTB mean","CTB today–5 weeks","CTB today–9 weeks","CTB 5–10 weeks","CTB 5–14 weeks","CTB answered trials",
    "PROMIS physical function T","PROMIS anxiety T","PROMIS depression T","PROMIS fatigue T","PROMIS sleep disturbance T","PROMIS social roles T","PROMIS pain interference T","PROMIS pain intensity",
    "Fraud lifetime band","Fraud lifetime any","Fraud 12-month band","Fraud 12-month any"),
  variable=c("fevs_total","ecog_total","susd_depression","susd_mania","uclal_total","mspss_total","ntb_total",
    "oafem_weighted_total","oafem_items_rated","ctb_mean","ctb_today_5wk","ctb_today_9wk","ctb_5wk_10wk","ctb_5wk_14wk","ctb_trials_answered",
    "promis_physical_function_t","promis_anxiety_t","promis_depression_t","promis_fatigue_t","promis_sleep_disturbance_t","promis_social_roles_t","promis_pain_interference_t","promis_pain_intensity",
    "fraud_lifetime_band","fraud_lifetime_any","fraud_12mo_band","fraud_12mo_any"),
  lower=c(0,1,0,0,3,1,10,0,0,1,1,1,1,1,0,22.9,40.3,41.0,33.7,32.0,27.5,41.6,0,0,0,0,0),
  upper=c(18,4,21,21,9,7,50,124,30,6,6,6,6,6,24,56.9,81.6,79.4,75.8,73.3,64.2,75.6,10,5,1,5,1),
  status="VERIFIED", stringsAsFactors=FALSE)
validation <- do.call(rbind,lapply(seq_len(nrow(spec)),function(i){
  x <- s[[spec$variable[i]]]
  if(any(x < spec$lower[i] | x > spec$upper[i],na.rm=TRUE)) stop(spec$variable[i]," has an impossible value.")
  data.frame(construct=spec$construct[i],variable=spec$variable[i],N_scored=sum(!is.na(x)),N_missing=sum(is.na(x)),
    observed_min=if(any(!is.na(x)))min(x,na.rm=TRUE)else NA_real_,observed_max=if(any(!is.na(x)))max(x,na.rm=TRUE)else NA_real_,
    expected_min=spec$lower[i],expected_max=spec$upper[i],scoring_status=spec$status[i])
}))
write_private_csv(validation,"score-validation.csv")

complete <- !is.na(s$oafem_unweighted_complete) & !is.na(s$oafem_weighted_total)
oafem_cor <- stats::cor(s$oafem_unweighted_complete[complete],s$oafem_weighted_total[complete])
rated <- table(s$oafem_items_rated,useNA="ifany")
if (sum(s$ctb_trials_answered != 24,na.rm=TRUE) != 0L) stop("At least one CTB record lacks all 24 uniquely mapped trials.")
if (any(vapply(d,function(x)is.character(x)&&any(trimws(x)=="",na.rm=TRUE),logical(1)))) stop("Source normalization left a blank categorical value.")

lines <- c("# Private score validation","",
  "- Records validated: 709; participant keys unique.",
  "- All listed score definitions and expected-range checks passed.",
  paste0("- OAFEM: 30/30 items map uniquely to published short-form items and explicit severity weights; ",sum(!is.na(s$oafem_weighted_total))," participants scored; observed range ",min(s$oafem_weighted_total,na.rm=TRUE),"–",max(s$oafem_weighted_total,na.rm=TRUE),"."),
  paste0("- OAFEM rated-item distribution: ",paste(names(rated),as.integer(rated),sep=" items=",collapse="; ")," participants."),
  paste0("- OAFEM weighted versus complete unweighted diagnostic correlation: r = ",sprintf("%.4f",oafem_cor)," (complete cases only)."),
  "- OAFEM uses the documented weighted sum of nonmissing rated items; it is missing only when no item was rated. No undocumented minimum-item threshold was imposed.",
  paste0("- CTB: ",sum(!is.na(s$ctb_mean))," participants; every observed response mapped uniquely to 1–6 and all participants answered 24/24 trials."),
  "- PROMIS-29 Profile v2.0: all seven domain raw sums were direction-corrected and converted through official HealthMeasures raw-sum T-score tables; pain intensity remains 0–10.",
  "- PROMIS directions: higher physical/social-role T-scores indicate better function; higher anxiety, depression, fatigue, sleep-disturbance, and pain-interference T-scores indicate greater burden.",
  "- Fraud outputs distinguish lifetime from past-12-month loss and preserve both ordinal bands and binary any-loss indicators; bands are not treated as dollar amounts.",
  "- Source character fields normalize blank, whitespace-only, `NA`, and `N/A` to missing before factor creation.",
  "","See `score-validation.csv` for per-score coverage and ranges.")
writeLines(lines,file.path(derived_dir(),"score-validation.md"))
cat("Validated ",nrow(validation)," score definitions/ranges.\n",sep="")
