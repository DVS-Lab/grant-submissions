source(file.path(Sys.getenv("SDOH_PROJECT_ROOT"),"code","pipeline","_helpers.R"))
d <- read_private_csv("analysis-master.csv")
r <- read_private_csv("grant-candidate-results.csv")
spec <- read_private_csv("grant-model-specifications.csv")
context <- read_private_csv("context-validation.csv")
score <- read_private_csv("score-validation.csv")
history <- read_private_csv("model-screen-rerun.csv")

main_effect <- function(id,term=NULL) {
  x <- r[r$model_id==id,,drop=FALSE]
  if(is.null(term)) {
    exposure <- unique(x$exposure)[1]
    x <- x[x$term==exposure,,drop=FALSE]
  } else x <- x[x$term==term,,drop=FALSE]
  if(nrow(x)!=1L) stop("Could not identify one requested result for ",id," / ",term)
  x
}
beta_text <- function(x,digits=2) paste0("β=",sprintf(paste0("%.",digits,"f"),x$estimate),
  " (95% CI ",sprintf(paste0("%.",digits,"f"),x$CI_low)," to ",sprintf(paste0("%.",digits,"f"),x$CI_high),
  "; N=",x$N,")")
or_text <- function(x) paste0("OR=",sprintf("%.2f",x$effect_ratio)," (95% CI ",sprintf("%.2f",x$ratio_CI_low),
  " to ",sprintf("%.2f",x$ratio_CI_high),"; N=",x$N,")")

sdi_ctb <- main_effect("C_SDI_CTB_ADJ"); ec_ctb <- main_effect("C_EC_CTB_ADJ"); pm_ctb <- main_effect("C_PM25_CTB_ADJ")
sdi_oafem <- main_effect("A_SDI_OAFEM_ADJ"); sdi_oafem_ge6 <- main_effect("G_SDI_oafem_weighted_total_resident_ge6")
sdi_fraud <- main_effect("A_SDI_FRAUD_LIFE_ADJ"); gini_fraud <- main_effect("A_GINI_FRAUD_LIFE_ADJ"); ec_fraud <- main_effect("A_EC_FRAUD_LIFE_ADJ")
ecog_fevs <- main_effect("E_ECOG_fevs_total","ecog_c"); ecog_oafem <- main_effect("E_ECOG_oafem_weighted_total","ecog_c")
ecog_fl <- main_effect("E_ECOG_fraud_lifetime_any","ecog_c"); ecog_f12 <- main_effect("E_ECOG_fraud_12mo_any","ecog_c")
sdi_age <- main_effect("D_SDI_fevs_total","z_sdi:age_c"); gini_age <- main_effect("D_GINI_fevs_total","z_gini:age_c")
sdi_support_dep <- main_effect("F_MSPSS_SDI_susd_depression","z_sdi:mspss_c")

family_counts <- aggregate(model_id~family,spec,function(x)length(unique(x)))
family_n <- aggregate(N~family,r[r$status=="RUN",],function(x)paste0(min(x),"–",max(x)))
family_table <- merge(family_counts,family_n,by="family",all.x=TRUE)

audit <- c("# Fixed grant results audit","",
  "This audit covers the complete fixed, grant-driven analysis framework. It is not a significance-filtered list. Coefficients for continuous core exposures use one-SD exposure increments unless a model is explicitly labeled raw-unit.","",
  paste0("- Model specifications: ",nrow(spec),"; successfully fitted: ",length(unique(r$model_id[r$status=="RUN"])),"."),
  paste0("- Coefficient rows: ",nrow(r),"."),
  "- Common adjustment: centered age, gender, household-income category, and education category.",
  "- Fraud any-loss models use logistic regression and report odds ratios; loss bands also have proportional-odds sensitivity models.",
  "- Weighted OAFEM uses linear primary models plus log1p and quasi-Poisson sensitivities because its bounded distribution is right-skewed.",
  "- Logistic fits emitted numerical-boundary warnings in some adjusted models; exposure estimates remained finite, but inference should be reviewed before publication.","",
  "## Coverage by family","")
for(i in seq_len(nrow(family_table))) audit <- c(audit,paste0("- ",family_table$family[i],": ",family_table$model_id[i]," specifications; coefficient-level N range ",family_table$N[i],"."))
audit <- c(audit,"",
  "## Family A — environment to financial vulnerability","",
  paste0("- SDI was not clearly associated with FEVS after adjustment, but was positively associated with weighted OAFEM: ",beta_text(sdi_oafem),"."),
  paste0("- Lifetime any-loss odds increased with SDI (",or_text(sdi_fraud),") and Gini (",or_text(gini_fraud),") and decreased with economic connectedness (",or_text(ec_fraud),")."),
  "- Most main-effect estimates for FEVS were small with intervals spanning zero. Twelve-month fraud estimates were less coherent than lifetime loss.","",
  "## Family B — cognition, mood, and health","",
  "- Context-to-eCog, SUSD, and concept-prioritized PROMIS estimates were mostly small or uncertain after common adjustment.",
  "- No context-health result should be elevated simply because one domain produces a small p-value; the domain set was deliberately constrained but remains multiple correlated outcomes.","",
  "## Family C — decision process","",
  paste0("- Higher SDI corresponded to lower CTB (more sooner allocation): ",beta_text(sdi_ctb),"."),
  paste0("- Higher economic connectedness corresponded to higher CTB: ",beta_text(ec_ctb),"."),
  paste0("- PM2.5 did not reproduce the prior-study CTB direction with useful precision: ",beta_text(pm_ctb),"."),"",
  "## Family D — age vulnerability","",
  paste0("- Age modified the SDI–FEVS estimate: ",beta_text(sdi_age)," per one-SD SDI × one year."),
  paste0("- The Gini–FEVS age interaction had similar direction: ",beta_text(gini_age),"."),
  "- These cross-sectional interactions need substantive inspection and plots before grant language; they are not causal aging effects.","",
  "## Family E — cognitive vulnerability","",
  paste0("- eCog was strongly associated with FEVS (",beta_text(ecog_fevs),") and weighted OAFEM (",beta_text(ecog_oafem),")."),
  paste0("- eCog was also associated with lifetime loss (",or_text(ecog_fl),") and 12-month loss (",or_text(ecog_f12),")."),
  "- Selected context × eCog interactions were mixed; SDI × eCog for OAFEM did not have a clearly bounded-away-from-zero interval.","",
  "## Family F — social-resource buffering","",
  paste0("- Fixed MSPSS interactions did not yield a simple uniform buffering story. The SDI × MSPSS estimate for SUSD depression was positive (",beta_text(sdi_support_dep),") and requires interpretation rather than a protective label."),
  "- Selected loneliness and Need-to-Belong interactions were retained as secondary diagnostics and should not displace the MSPSS total analysis.","",
  "## Family G — residence-duration validity","",
  paste0("- SDI–OAFEM remained positive among residents of at least six years: ",beta_text(sdi_oafem_ge6),"."),
  "- PM2.5–CTB remained imprecise in both ≥6-year and >10-year subsets. Restricted-sample p-values are not treated as replication tests.","",
  "## Major caveats","",
  "- All associations are cross-sectional and current ZIP is an imperfect proxy for individual long-term exposure.",
  "- Economic connectedness and high-SES exposure are highly correlated, and SDI is strongly inversely related to economic connectedness.",
  "- ADI and crime/disorder are absent for defensible access/geography reasons; the exploratory burden composite therefore uses four available domains.",
  "- These preliminary models estimate associations, not causal environmental effects.")
atomic_write_lines(audit,file.path(derived_dir(),"grant-results-audit.md"))

findings <- c("# Grant candidate findings","",
  "These candidates were selected for grant alignment, interpretability, precision, and consistency across planned variants—not merely by smallest p-value.","",
  "## STRONG CANDIDATE","",
  paste0("1. **Neighborhood disadvantage and delayed-reward preference.** Higher SDI related to lower CTB (",beta_text(sdi_ctb),"), while higher economic connectedness related to higher CTB (",beta_text(ec_ctb),"). The convergent directions are conceptually useful, though cross-sectional."),
  paste0("2. **Context and lifetime fraud loss.** Higher SDI and Gini corresponded to higher lifetime any-loss odds (",or_text(sdi_fraud),"; ",or_text(gini_fraud),"), while economic connectedness was protective in direction (",or_text(ec_fraud),"). This triangulation is stronger than any one exposure alone."),
  paste0("3. **Subjective cognitive vulnerability.** eCog related to FEVS (",beta_text(ecog_fevs),"), weighted OAFEM (",beta_text(ecog_oafem),"), lifetime loss (",or_text(ecog_fl),"), and 12-month loss (",or_text(ecog_f12),"). This supports the individual-susceptibility portion of the conceptual model."),"",
  "## INTERESTING BUT NEEDS REVIEW","",
  paste0("4. **SDI and exploitation indicators.** Adjusted SDI–OAFEM was positive but modest (",beta_text(sdi_oafem),") and remained positive among ≥6-year residents (",beta_text(sdi_oafem_ge6),"). Review distribution-sensitive estimates and the partial-missing OAFEM rule before foregrounding."),
  paste0("5. **Age vulnerability.** SDI and Gini associations with FEVS became more adverse with age (",beta_text(sdi_age),"; ",beta_text(gini_age),"). The interaction scale and predicted-value figures need scientific review."),
  paste0("6. **Social support is not a simple buffer.** The SDI × MSPSS result for depression was positive (",beta_text(sdi_support_dep),"). This may reflect scale/context complexity and should not be narrated as protection without follow-up."),"",
  "## INFORMATIVE NULL","",
  paste0("7. **PM2.5 and CTB.** The adjusted full-sample estimate was ",beta_text(pm_ctb),", and long-residence estimates were also uncertain. The N=709 ZIP-based analysis does not provide a clear extension of the prior lab finding."),
  "8. **Environmental context and FEVS/eCog/mood.** Most adjusted main effects were small with intervals spanning zero. This constrains a broad claim that every contextual burden maps onto every vulnerability domain.","",
  "## NOT WORTH PURSUING","",
  "- Exhaustively crossing all Social Capital Atlas columns with all PROMIS domains, mining alternative PM2.5 windows, or elevating gambling outcomes solely because they are available. Those paths would dilute the grant story.")
atomic_write_lines(findings,file.path(derived_dir(),"grant-candidate-findings.md"))

inventory <- c("# Context candidate inventory","",
  "## CORE","",
  "- ZCTA-linked: SDI (ACS 2015–2019 deprivation), ACAG PM2.5 (2012–2022), and ACS 2024 five-year Gini. Direct current-ZIP: Opportunity Insights economic connectedness and USDA 2020 RUCA. Survey classification: urban/suburban/rural.",
  "- Crime/disorder remains conceptually core but unlinked because no consistent national ZIP/ZCTA product was found.","",
  "## USEFUL SECONDARY","",
  "- Social Capital Atlas high-SES exposure, friending bias, clustering/cohesiveness, support ratio, volunteering, and civic organizations.",
  "- PM2.5 recent mean (2018–2022) and interannual variability, for targeted sensitivity only.",
  "- `env_burden_simple`, an exploratory equal-weight mean of standardized SDI, PM2.5, Gini, and low economic connectedness, requiring at least three components.",
  "- An explicitly labeled population-weighted `adi_zcta_proxy` only if credentialed block-group ADI and defensible block-group-to-ZCTA population weights become available.","",
  "## NOT CURRENTLY WORTH ADDING","",
  "- Additional pollution windows, centroid-only exposures, opaque commercial neighborhood scores, locally restricted crime indices, or broad transportation/health-access screens without a specific grant hypothesis.")
atomic_write_lines(inventory,file.path(derived_dir(),"context-candidate-inventory.md"))

unused <- c("# Unused-measures opportunity review","",
  "## ADD TO CORE ANALYSES","",
  "- CTB: directly extends the lab's PM2.5 decision-process work.",
  "- PROMIS depression, anxiety, physical function, pain interference, sleep disturbance, and social roles: concept-prioritized Family B outcomes.",
  "- Residence duration: required validity sensitivity for all current-ZIP exposures.",
  "- MSPSS total, UCLA loneliness, and Need to Belong: documented social-resource/susceptibility moderators.","",
  "## SECONDARY / SENSITIVITY","",
  "- MSPSS subscales: inspect only with an a priori relational-source hypothesis or after a total-score result warrants decomposition.",
  "- Home ownership, household composition, caregiving, and occupational status: plausible susceptibility/context descriptors, but adding them to the compact adjustment set risks construct overcontrol or sparse categories.",
  "- Personal income: secondary because household income is the common adjustment and neighborhood Gini answers a distinct question.",
  "- PROMIS fatigue and pain intensity: useful descriptive/targeted health outcomes, not the first grant tests.","",
  "## NOT USEFUL FOR THIS GRANT","",
  "- Gambling screens, substance screens, administrative payment preferences, and platform fields. They do not materially strengthen the five specified grant stories in this pass.",
  "- Historical measures absent from the N=709 instrument (BIS/BAS, DOSPERT, GSAS, Planfulness) cannot be analyzed and should not drive new data archaeology.")
atomic_write_lines(unused,file.path(derived_dir(),"unused-measures-review.md"))

context_lines <- vapply(seq_len(nrow(context)),function(i) paste0("- `",context$variable[i],"`: ",context$N_matched[i],"/709 matched (",context$percent_matched[i],"%); range ",context$minimum[i],"–",context$maximum[i],"."),character(1))
history_formula <- aggregate(status~model_formula,history,function(x)if(any(x=="RERUN"))"RERUN" else "NOT RUNNABLE")
packet <- c("# Melanie review packet","",
  "This is the private analysis handoff—not the final two-page report. It contains no participant rows, ZIP codes, or direct identifiers.","",
  "## 1. Dataset and scoring status","",
  paste0("- Analysis master: ",nrow(d)," rows × ",ncol(d)," columns; `study_id` unique; current/childhood ZIP excluded."),
  "- OAFEM: all 30 stems uniquely mapped to the published short form; 0/1/2 responses and explicit 1/2/3 severity weights; sum of rated items; item count retained.",
  "- PROMIS: Profile v2.0 implementation checked by automated contracts; reverse directions handled for refreshing sleep and social-role trouble items; official raw-sum T scores for seven domains.",
  "- CTB: 24/24 option strings mapped to 1–6 for all 709 participants; higher means more delayed allocation.",
  "- Fraud: lifetime and past-12-month bands plus any-loss indicators; categories are not dollars.",
  "- Blank/whitespace/NA-text categorical values are normalized before modeling.","",
  "### Score coverage and interpretation","",
  "- Weighted OAFEM is available for 702 participants and spans 0–124. Seven people selected Unknown/N/A for all items; partial ratings are not converted to zero, and the number rated travels with the score.",
  "- CTB and all PROMIS T-score domains are available for all 709 participants. CTB spans 1–6; the four delay-pair subscales remain descriptive rather than competing primary outcomes.",
  "- FEVS is a higher-risk score; eCog is higher subjective cognitive difficulty; SUSD is higher mood burden; MSPSS is higher perceived support. Direction must be stated whenever effects are summarized.",
  "- PROMIS physical-function and social-role scores run in a favorable direction, whereas anxiety, depression, fatigue, sleep disturbance, and pain interference run in a burden direction. They must not be described as if all PROMIS coefficients have a common interpretation.",
  "- OAFEM linear estimates are retained for interpretability, but log1p and quasi-Poisson results are available for distribution sensitivity. Fraud any-loss is the primary regression outcome; ordinal bands remain sensitivity analyses.","",
  "## 2. Contextual exposures and provenance","",
  "- SDI: Robert Graham Center, ACS 2015–2019, ZCTA; higher is more deprivation.",
  "- PM2.5: ACAG V5.NA.05 annual 0.01° North America grids, 2012–2022, latitude-adjusted area-weighted to 2020 ZCTA polygons; µg/m³.",
  "- Social capital: 2022 Opportunity Insights ZIP data linked directly to participant current ZIP, without ZCTA substitution or fallback. Economic connectedness is twice the share of high-SES friends among low-SES users; high-SES exposure is twice the high-SES share in low-SES users' groups; friending bias is one minus connectedness/exposure; clustering, support ratio, volunteering, and civic organizations are retained secondaries.",
  "- Gini: ACS 2024 five-year B19083 at ZCTA.",
  "- Rurality: USDA ERS 2020 ZIP RUCA, with standard primary-code groups (metropolitan 1–3, micropolitan 4–6, small town 7–9, rural 10), alongside self-report.",
  "- ADI: not generated because Neighborhood Atlas validates block groups, requires credentialed data, and no defensible population-weighted ZCTA aggregation was available.",
  "- Crime/disorder: audited; no national consistent ZCTA source was forced into the analysis.","",
  "## 3. Geographic match rates","",context_lines,
  "- Childhood ZIP is prepared for future feasibility linkage only. Contemporary measures must not be described as childhood-era exposures.","",
  "## 4. Exposure correlations","",
  "- SDI and economic connectedness: r = −0.757 (|r|≥.70).",
  "- Economic connectedness and high-SES exposure: r = 0.928 (|r|≥.85).",
  "- See `context-correlation.csv`, `context-correlation-flags.csv`, and `context-correlation.png`. Do not automatically combine these measures.","",
  "## 5. Fixed-analysis overview","",
  paste0("- ",nrow(spec)," fixed, grant-driven specifications ran successfully across Families A–G plus labeled sensitivities; no p-value-driven model selection."),
  "- Continuous outcomes: linear primary models. Fraud any loss: logistic models with ORs/CIs. Fraud bands: proportional-odds sensitivities. OAFEM: linear plus log1p and quasi-Poisson sensitivities.",
  "- Exposures are standardized for comparable core effects; raw-unit adjusted models are retained. Interactions use centered continuous moderators.",
  paste0("- Historical screen: ",sum(history_formula$status=="RERUN"),"/35 formulas now run. The other ",sum(history_formula$status!="RERUN")," require the unknown `minority` recode; it was not invented."),"",
  "### What each model family answers","",
  "- **Family A** asks whether each available core place exposure relates to FEVS, weighted OAFEM, lifetime fraud loss, or 12-month fraud loss. Both unadjusted and compactly adjusted models are retained.",
  "- **Family B** asks whether place relates to eCog, SUSD depression, or a concept-prioritized PROMIS domain. PROMIS combinations were selected by plausible construct relevance rather than crossing every domain blindly.",
  "- **Family C** asks whether place relates to CTB. The adjusted PM2.5 specification mirrors the prior paper's age, gender, household-income, and education adjustment as closely as the online sample allows.",
  "- **Family D** asks whether age changes the exposure association for only five priority outcomes: FEVS, OAFEM, eCog, depression, and CTB.",
  "- **Family E** first quantifies eCog as an individual vulnerability marker, then asks whether selected environmental relationships differ across eCog levels.",
  "- **Family F** tests MSPSS as the primary buffering measure, with narrower loneliness and Need-to-Belong diagnostics. MSPSS subscales are not automatically multiplied into another testing grid.",
  "- **Family G** repeats five priority associations among ≥6-year and >10-year residents and fits residence interactions. These analyses evaluate exposure-proxy coherence; they are not independent replications.",
  "- **Secondary sensitivities** cover high-SES exposure and the simple environmental-burden composite. They are clearly separated from core source variables.","",
  "## 6. Candidate findings","",
  paste0("- SDI–CTB: ",beta_text(sdi_ctb),"; economic connectedness–CTB: ",beta_text(ec_ctb),"."),
  paste0("- Lifetime any-loss: SDI ",or_text(sdi_fraud),"; Gini ",or_text(gini_fraud),"; economic connectedness ",or_text(ec_fraud),"."),
  paste0("- eCog: FEVS ",beta_text(ecog_fevs),"; OAFEM ",beta_text(ecog_oafem),"; lifetime loss ",or_text(ecog_fl),"; 12-month loss ",or_text(ecog_f12),"."),
  paste0("- SDI–OAFEM: adjusted ",beta_text(sdi_oafem),"; ≥6-year residents ",beta_text(sdi_oafem_ge6),"."),
  "- Full interpretation and classifications: `grant-candidate-findings.md`.","",
  "## 7. Important nulls","",
  paste0("- PM2.5–CTB: ",beta_text(pm_ctb),"; no clear full-sample or long-residence extension of the prior lab result."),
  "- Most adjusted context main effects for FEVS, eCog, SUSD depression, and concept-prioritized PROMIS domains were small/uncertain.",
  "- Social support did not show a uniform protective interaction across contexts/outcomes.","",
  "## 8. Figure menu","",
  "- `01-pm25-ctb.png`: direct prior-study extension and an important null.",
  "- `02-sdi-fevs.png` and `03-sdi-oafem.png`: two financial-vulnerability outcomes for deprivation.",
  "- `04-economic-connectedness-fevs.png` and `05-economic-connectedness-oafem.png`: resource-oriented counterparts to SDI.",
  "- `06-gini-fevs.png`: neighborhood inequality and financial vulnerability.",
  "- `07-pm25-ecog.png`: air pollution and subjective cognition.",
  "- `08-sdi-depression.png`: deprivation and mood burden.",
  "- `09-sdi-age-fevs.png`: predicted age-vulnerability pattern.",
  "- `10-sdi-ecog-oafem.png`: predicted cognitive-vulnerability pattern.",
  "- `11-economic-connectedness-mspss-fevs.png`: community and individual social resources together.",
  "- Select 2–4 for the grant based on conceptual priority and honest uncertainty, then refine labels/layout—not statistical significance.","",
  "## 9. Exact unresolved scientific choices","",
  "1. Decide whether latitude-corrected area-weighted PM2.5 is adequate or whether population weighting warrants a sensitivity analysis.",
  "2. Decide whether a credentialed, explicitly population-weighted block-group ADI-to-ZCTA proxy is worth adding despite Neighborhood Atlas's ZIP warning.",
  "3. Decide whether crime/disorder justifies a coarser county UCR measure or a tract-level academic product with geographic/coverage tradeoffs.",
  "4. Choose which Social Capital constructs best instantiate cohesion; avoid carrying both economic connectedness and high-SES exposure as interchangeable predictors because r=.928.",
  "5. Decide whether ACS/context vintages are acceptable for the survey timing and whether any targeted alternate-vintage sensitivity is needed.","",
  "## 10. Questions for the final two-page report","",
  "- Which two context domains best express the grant's central environmental-burden story?",
  "- Should the balanced narrative foreground the convergent SDI/economic-connectedness CTB pattern, the lifetime-fraud triangulation, or cognitive susceptibility?",
  "- How should the PM2.5 null constrain the extension of the prior lab finding?",
  "- Are age interactions mature enough for a preliminary-data claim, or should they remain a planned hypothesis?",
  "- Which 2–4 figures communicate effect sizes and uncertainty most efficiently?",
  "- What narrowly motivated follow-ups would resolve a scientific ambiguity rather than add an exploratory grid?")
packet <- c(packet,"",
  "## 11. Reading and reporting guardrails","",
  "- Treat every effect as an association in a cross-sectional online sample. Do not use causal verbs such as caused, protected, or led to.",
  "- Report one-SD exposure coefficients with their 95% intervals and N. If a raw-unit effect is more intuitive, verify it against the corresponding standardized model rather than switching scales opportunistically.",
  "- Do not call p>.05 proof of no association. For nulls, describe the estimate and interval, and say whether the interval rules out effects of practical importance.",
  "- Do not use restricted-residence p-values as a replication criterion. Compare direction and magnitude with the full sample and acknowledge smaller N.",
  "- Do not combine SDI and economic connectedness casually: they overlap substantially but encode adversity versus cross-SES network resources. High-SES exposure overlaps even more strongly with economic connectedness.",
  "- The simple burden composite is transparent but incomplete because ADI and crime are absent. It should never replace the source-specific results in the preliminary-data narrative.",
  "- Adjusted fraud models are stable at the exposure-term level but emitted numerical-boundary warnings in some fits. Review event/category cells or use a penalized sensitivity before publication-level inference.","",
  "## 12. Private deliverable index","",
  "- `analysis-master.csv`: row-level modeling file without geography identifiers.",
  "- `score-validation.md` / `.csv`: measure coverage, range, and scoring checks.",
  "- `context-linkage-audit.md` / `context-validation.csv`: linkage counts, ranges, and caveats.",
  "- `context-correlation.csv`, flags, and PNG: exposure redundancy review.",
  "- `grant-model-specifications.csv` and `grant-candidate-results.csv`: complete fixed model registry and coefficient output.",
  "- `grant-results-audit.md`: balanced family-by-family synthesis, including nulls.",
  "- `grant-candidate-findings.md`: 5–10 grant-facing candidates classified by scientific usefulness.",
  "- `unused-measures-review.md` and `context-candidate-inventory.md`: disciplined opportunity audits.",
  "- `figure-index.md` and `figures/`: 11-model visual menu.",
  "- `crime-source-audit.md` and `adi-proxy-status.md`: exact reasons those constructs remain scientific/access decisions.")
atomic_write_lines(packet,file.path(derived_dir(),"melanie-review-packet.md"))
message("Built private results audit, candidate findings, opportunity audits, and Melanie review packet.")
