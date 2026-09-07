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
require_columns(d, c("study_id", fevs_items, ecog_items, susd_items, ucla_items,
                     mspss_items, ntb_items, oafem_items, promis_items,
                     "fraud_adult_1", "fraud_adult_2"))

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

promis <- data.frame(row.names = seq_len(nrow(d)))
pf_map <- c("without any difficulty"=5,"with little difficulty"=4,"with some difficulty"=3,
            "with much difficulty"=2,"unable to do"=1)
freq_map <- c("never"=1,"rarely"=2,"sometimes"=3,"often"=4,"usually"=4,"always"=5)
severity_map <- c("not at all"=1,"a little bit"=2,"somewhat"=3,"quite a bit"=4,"very much"=5)
sleep_quality_map <- c("very good"=1,"good"=2,"fair"=3,"poor"=4,"very poor"=5)
for (i in 1:4) promis[[promis_items[i]]] <- map_item(d[[promis_items[i]]], pf_map, promis_items[i])
for (i in 5:12) promis[[promis_items[i]]] <- map_item(d[[promis_items[i]]], freq_map, promis_items[i])
for (i in 13:16) promis[[promis_items[i]]] <- map_item(d[[promis_items[i]]], severity_map, promis_items[i])
promis[[promis_items[17]]] <- map_item(d[[promis_items[17]]], sleep_quality_map, promis_items[17])
for (i in 18:20) promis[[promis_items[i]]] <- map_item(d[[promis_items[i]]], severity_map, promis_items[i])
for (i in 21:24) promis[[promis_items[i]]] <- map_item(d[[promis_items[i]]], freq_map, promis_items[i])
for (i in 25:28) promis[[promis_items[i]]] <- map_item(d[[promis_items[i]]], severity_map, promis_items[i])
pain_text <- normalized_label(d[[promis_items[29]]])
pain <- suppressWarnings(as.numeric(sub("^([0-9]+).*$", "\\1", pain_text)))
if (any(!is.na(pain_text) & (is.na(pain) | pain < 0 | pain > 10))) stop("PROMIS pain intensity has unmapped values.")

loss_map <- c("$0"=0,"$1 - $100"=1,"$101 - $1,000"=2,"$1,001 - $10,000"=3,
              "$10,001 - $100,000"=4,"more than $100,000"=5)
fraud1 <- map_item(d$fraud_adult_1, loss_map, "fraud_adult_1")
fraud2 <- map_item(d$fraud_adult_2, loss_map, "fraud_adult_2")

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
  oafem_unweighted_complete = complete_sum(oafem),
  oafem_items_rated = rowSums(!is.na(oafem)),
  promis_physical_function_raw = complete_sum(promis[promis_items[1:4]]),
  promis_anxiety_raw = complete_sum(promis[promis_items[5:8]]),
  promis_depression_raw = complete_sum(promis[promis_items[9:12]]),
  promis_fatigue_raw = complete_sum(promis[promis_items[13:16]]),
  promis_sleep_disturbance_raw = complete_sum(promis[promis_items[17:20]]),
  promis_social_roles_raw = complete_sum(promis[promis_items[21:24]]),
  promis_pain_interference_raw = complete_sum(promis[promis_items[25:28]]),
  promis_pain_intensity = pain,
  fraud_adult_1_loss_band = fraud1,
  fraud_adult_1_any_loss = ifelse(is.na(fraud1), NA, as.integer(fraud1 > 0)),
  fraud_adult_2_loss_band = fraud2,
  fraud_adult_2_any_loss = ifelse(is.na(fraud2), NA, as.integer(fraud2 > 0)),
  check.names = FALSE
)
write_private_csv(scores, "core-scores.csv")
cat("Scored justified core measures for ", nrow(scores), " private records.\n", sep = "")
