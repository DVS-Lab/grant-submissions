source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"), "code", "pipeline", "_helpers.R"))
d <- read_source()

fevs_items <- paste0("fevs_", 1:9)
ecog_items <- paste0("ecog_", 1:12)
susd_items <- paste0("susd_matrix_", 1:14)
ucla_items <- paste0("uclal_", 1:3)
mspss_items <- paste0("mspss_adult_", 1:12)
ntb_items <- paste0("ntb_", 1:10)
oafem_items <- paste0("oafem_adult_", 1:30)
promis_items <- paste0("promis_adult_", 1:29)
ctb_items <- paste0("cbt_adult_", 1:24)
require_columns(d, c("study_id", fevs_items, ecog_items, susd_items, ucla_items,
                     mspss_items, ntb_items, oafem_items, promis_items,
                     ctb_items, "fraud_adult_1", "fraud_adult_2"))

fevs_maps <- list(
  c("not at all worried"=0,"somewhat worried"=1,"very worried"=2),
  c("satisfied"=0,"neither"=1,"dissatisfied"=2),
  c("satisfied"=0,"neither"=1,"dissatisfied"=2),
  c("confident"=0,"unsure"=1,"not confident"=2),
  c("never"=0,"sometimes"=1,"often"=2),
  c("never or rarely"=0,"some of the time"=1,"most of the time"=2),
  c("never or rarely"=0,"some of the time"=1,"a lot of the time"=2),
  c("never or rarely"=0,"sometimes"=1,"often"=2),
  c("none of the time"=0,"some of the time"=1,"most of the time"=2)
)
fevs <- as.data.frame(Map(function(v, m) map_item(d[[v]], m, v), fevs_items, fevs_maps))
names(fevs) <- fevs_items

ecog_map <- c("better or no change"=1,"a little worse sometimes"=2,
              "a little worse all the time"=3,"much worse"=4)
ecog <- as.data.frame(lapply(ecog_items, function(v) map_item(d[[v]], ecog_map, v)))
names(ecog) <- ecog_items

susd_map <- c("never or hardly ever"=0,"sometimes"=1,"often"=2,
              "very often or almost constantly"=3)
susd <- as.data.frame(lapply(susd_items, function(v) map_item(d[[v]], susd_map, v)))
names(susd) <- susd_items

ucla_map <- c("hardly ever"=1,"hardly every"=1,"some of the time"=2,"often"=3)
ucla <- as.data.frame(lapply(ucla_items, function(v) map_item(d[[v]], ucla_map, v)))
names(ucla) <- ucla_items

agreement5 <- c("strongly disagree"=1,"moderately disagree"=2,
                "neither agree nor disagree"=3,"moderately agree"=4,"strongly agree"=5)
agreement7 <- c("very strongly disagree"=1,"strongly disagree"=2,"moderately disagree"=3,
                "neither agree nor disagree"=4,"moderately agree"=5,"strongly agree"=6,
                "very strongly agree"=7)
mspss <- as.data.frame(lapply(mspss_items, function(v) map_item(d[[v]], agreement7, v)))
names(mspss) <- mspss_items
ntb <- as.data.frame(lapply(ntb_items, function(v) map_item(d[[v]], agreement5, v)))
names(ntb) <- ntb_items
ntb[c(1, 3, 7)] <- lapply(ntb[c(1, 3, 7)], function(x) 6 - x)

oafem_map <- c("no"=0,"suspected"=1,"yes"=2,"unknown or n/a"=NA_real_)
oafem <- as.data.frame(lapply(oafem_items, function(v) map_item(d[[v]], oafem_map, v)))
names(oafem) <- oafem_items
oafem_weights <- c(1,3,1,1,2,3,2,3,3,2,2,3,3,3,3,3,1,1,2,3,3,1,3,1,2,1,1,1,3,1)
if (length(oafem_weights) != 30L || sum(oafem_weights == 1) != 11L ||
    sum(oafem_weights == 2) != 6L || sum(oafem_weights == 3) != 13L) {
  stop("OAFEM severity map integrity check failed.")
}
oafem_weighted <- rowSums(sweep(as.matrix(oafem), 2, oafem_weights, `*`), na.rm = TRUE)
oafem_weighted[rowSums(!is.na(oafem)) == 0L] <- NA_real_

score_ctb_item <- function(x, variable) {
  y <- normalized_label(x)
  captured <- sub("^.*/[^$]*\\$([0-9]+(?:\\.[0-9]+)?).*$", "\\1", y)
  later_amount <- suppressWarnings(as.numeric(captured))
  valid_amounts <- c(0, 4, 8, 12, 16, 20)
  bad <- !is.na(y) & (is.na(later_amount) | !(later_amount %in% valid_amounts))
  if (any(bad)) stop(variable, " has ", sum(bad), " CTB response(s) that do not map uniquely.")
  ifelse(is.na(y), NA_real_, later_amount / 4 + 1)
}
ctb <- as.data.frame(lapply(ctb_items, function(v) score_ctb_item(d[[v]], v)))
names(ctb) <- ctb_items

promis <- data.frame(row.names = seq_len(nrow(d)))
pf_map <- c("without any difficulty"=5,"with little difficulty"=4,"with some difficulty"=3,
            "with much difficulty"=2,"unable to do"=1)
freq_map <- c("never"=1,"rarely"=2,"sometimes"=3,"often"=4,"usually"=4,"always"=5)
severity_map <- c("not at all"=1,"a little bit"=2,"somewhat"=3,"quite a bit"=4,"very much"=5)
severity_reverse_map <- c("not at all"=5,"a little bit"=4,"somewhat"=3,"quite a bit"=2,"very much"=1)
sleep_quality_map <- c("very good"=1,"good"=2,"fair"=3,"poor"=4,"very poor"=5)
social_reverse_map <- c("never"=5,"rarely"=4,"sometimes"=3,"usually"=2,"always"=1)
for (i in 1:4) promis[[promis_items[i]]] <- map_item(d[[promis_items[i]]], pf_map, promis_items[i])
for (i in 5:12) promis[[promis_items[i]]] <- map_item(d[[promis_items[i]]], freq_map, promis_items[i])
for (i in 13:16) promis[[promis_items[i]]] <- map_item(d[[promis_items[i]]], severity_map, promis_items[i])
promis[[promis_items[17]]] <- map_item(d[[promis_items[17]]], sleep_quality_map, promis_items[17])
promis[[promis_items[18]]] <- map_item(d[[promis_items[18]]], severity_reverse_map, promis_items[18])
for (i in 19:20) promis[[promis_items[i]]] <- map_item(d[[promis_items[i]]], severity_map, promis_items[i])
for (i in 21:24) promis[[promis_items[i]]] <- map_item(d[[promis_items[i]]], social_reverse_map, promis_items[i])
for (i in 25:28) promis[[promis_items[i]]] <- map_item(d[[promis_items[i]]], severity_map, promis_items[i])
pain_text <- normalized_label(d[[promis_items[29]]])
pain <- suppressWarnings(as.numeric(sub("^([0-9]+).*$", "\\1", pain_text)))
if (any(!is.na(pain_text) & (is.na(pain) | pain < 0 | pain > 10))) stop("PROMIS pain intensity has unmapped values.")

loss_map <- c("$0"=0,"$1 - $100"=1,"$101 - $1,000"=2,"$1,001 - $10,000"=3,
              "$10,001 - $100,000"=4,"more than $100,000"=5)
fraud1 <- map_item(d$fraud_adult_1, loss_map, "fraud_adult_1")
fraud2 <- map_item(d$fraud_adult_2, loss_map, "fraud_adult_2")

promis_lookup <- function(raw, values, domain) {
  if (length(values) != 17L) stop(domain, " PROMIS conversion table must cover raw scores 4:20.")
  out <- unname(stats::setNames(values, 4:20)[as.character(raw)])
  if (any(!is.na(raw) & is.na(out))) stop(domain, " has a raw score outside its official conversion table.")
  as.numeric(out)
}
pf_raw <- complete_sum(promis[promis_items[1:4]])
anxiety_raw <- complete_sum(promis[promis_items[5:8]])
depression_raw <- complete_sum(promis[promis_items[9:12]])
fatigue_raw <- complete_sum(promis[promis_items[13:16]])
sleep_raw <- complete_sum(promis[promis_items[17:20]])
social_raw <- complete_sum(promis[promis_items[21:24]])
pain_interference_raw <- complete_sum(promis[promis_items[25:28]])

pf_t <- c(22.9,26.9,29.1,30.7,32.1,33.3,34.4,35.6,36.7,37.9,39.1,40.4,41.8,43.4,45.3,48.0,56.9)
anxiety_t <- c(40.3,48.0,51.2,53.7,55.8,57.7,59.5,61.4,63.4,65.3,67.3,69.3,71.2,73.3,75.4,77.9,81.6)
depression_t <- c(41.0,49.0,51.8,53.9,55.7,57.3,58.9,60.5,62.2,63.9,65.7,67.5,69.4,71.2,73.3,75.7,79.4)
fatigue_t <- c(33.7,39.7,43.1,46.0,48.6,51.0,53.1,55.1,57.0,58.8,60.7,62.7,64.6,66.7,69.0,71.6,75.8)
sleep_t <- c(32.0,37.5,41.1,43.8,46.2,48.4,50.5,52.4,54.3,56.1,57.9,59.8,61.7,63.8,66.0,68.8,73.3)
social_t <- c(27.5,31.8,34.0,35.7,37.3,38.8,40.5,42.3,44.2,46.2,48.1,50.0,51.9,53.7,55.8,58.3,64.2)
pain_interference_t <- c(41.6,49.6,52.0,53.9,55.6,57.1,58.5,59.9,61.2,62.5,63.8,65.2,66.6,68.0,69.7,71.6,75.6)

scores <- data.frame(
  study_id = d$study_id,
  fevs_total = complete_sum(fevs),
  ecog_total = available_mean(ecog),
  ecog_items_answered = rowSums(!is.na(ecog)),
  susd_depression = complete_sum(susd[c(2,5,9,10,11,12,14)]),
  susd_mania = complete_sum(susd[c(1,3,4,6,7,8,13)]),
  uclal_total = complete_sum(ucla),
  mspss_total = complete_mean(mspss),
  mspss_significant_other = complete_mean(mspss[c(1,2,5,10)]),
  mspss_family = complete_mean(mspss[c(3,4,8,11)]),
  mspss_friends = complete_mean(mspss[c(6,7,9,12)]),
  ntb_total = complete_sum(ntb),
  ntb_mean = complete_mean(ntb),
  oafem_weighted_total = oafem_weighted,
  oafem_unweighted_complete = complete_sum(oafem),
  oafem_items_rated = rowSums(!is.na(oafem)),
  ctb_mean = complete_mean(ctb),
  ctb_today_5wk = complete_mean(ctb[1:6]),
  ctb_today_9wk = complete_mean(ctb[7:12]),
  ctb_5wk_10wk = complete_mean(ctb[13:18]),
  ctb_5wk_14wk = complete_mean(ctb[19:24]),
  ctb_trials_answered = rowSums(!is.na(ctb)),
  promis_physical_function_raw = pf_raw,
  promis_anxiety_raw = anxiety_raw,
  promis_depression_raw = depression_raw,
  promis_fatigue_raw = fatigue_raw,
  promis_sleep_disturbance_raw = sleep_raw,
  promis_social_roles_raw = social_raw,
  promis_pain_interference_raw = pain_interference_raw,
  promis_physical_function_t = promis_lookup(pf_raw, pf_t, "Physical Function"),
  promis_anxiety_t = promis_lookup(anxiety_raw, anxiety_t, "Anxiety"),
  promis_depression_t = promis_lookup(depression_raw, depression_t, "Depression"),
  promis_fatigue_t = promis_lookup(fatigue_raw, fatigue_t, "Fatigue"),
  promis_sleep_disturbance_t = promis_lookup(sleep_raw, sleep_t, "Sleep Disturbance"),
  promis_social_roles_t = promis_lookup(social_raw, social_t, "Social Roles"),
  promis_pain_interference_t = promis_lookup(pain_interference_raw, pain_interference_t, "Pain Interference"),
  promis_pain_intensity = pain,
  fraud_lifetime_band = fraud1,
  fraud_lifetime_any = ifelse(is.na(fraud1), NA, as.integer(fraud1 > 0)),
  fraud_12mo_band = fraud2,
  fraud_12mo_any = ifelse(is.na(fraud2), NA, as.integer(fraud2 > 0)),
  check.names = FALSE
)
write_private_csv(scores, "core-scores.csv")
cat("Scored justified core measures for ", nrow(scores), " private records.\n", sep = "")
