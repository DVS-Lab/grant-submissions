# SDOH measure and variable map

This metadata-only map describes the reviewed 709-row private source. It does
not contain participant values. “Verified” means the response mapping and score
definition are supported by the source structure, project evidence, and an
identified measure source; it does not mean a scientific interpretation has
been approved.

## Core grant-relevant constructs

| Construct | Raw variables / items present | Existing source score | Current pipeline output | Status | Current relevance and notes |
|---|---:|---:|---|---|---|
| FEVS short form | `fevs_1`–`fevs_9` (9) | None | `fevs_total`, 0–18 | **Verified** | CORE. Item-specific three-level risk mappings; complete-case sum. The legacy script accidentally summed only items 2–9 because of positional indexing and is not reused. |
| OAFEM | `oafem_adult_1`–`oafem_adult_30` (30) | None | `oafem_weighted_total`; `oafem_items_rated`; unweighted diagnostic | **Verified** | CORE. All exact stems map uniquely in `oafem-item-map.csv`; No/Suspected/Yes = 0/1/2 and explicit severity weights = 1/2/3. The weighted sum uses rated items and is missing only when zero items are rated. Because participants can have different numbers rated, retain `oafem_items_rated` for independent sensitivity review. |
| Everyday Cognition (eCog-12) | `ecog_1`–`ecog_12` (12) | None | `ecog_total`; `ecog_items_answered` | **Verified** | CORE. Responses 1–4; mean of answered items, matching the published mean-of-completed-items rule. |
| 7 Up 7 Down / SUSD | `susd_matrix_1`–`susd_matrix_14` (14) | None | `susd_depression`, `susd_mania` | **Verified** | CORE. Seven items per subscale, 0–3, complete-case sums. The item sets match legacy code; misleading copied comments/renumbering are not reused. |
| UCLA 3-item loneliness | `uclal_1`–`uclal_3` (3) | None | `uclal_total`, 3–9 | **Verified** | CORE. A source typo, “Hardly Every,” is normalized to “Hardly Ever”; complete-case sum. Legacy `na.rm=TRUE` behavior is not retained. |
| MSPSS | `mspss_adult_1`–`mspss_adult_12` (12) | None | total mean plus significant-other, family, and friends means | **Verified** | CORE. Standard 1–7 response mapping and four-item subscales. |
| Need to Belong | `ntb_1`–`ntb_10` (10) | None | `ntb_total`, `ntb_mean` | **Verified** | CORE/POSSIBLY RELEVANT moderator. Standard 1–5 mapping; items 1, 3, and 7 reverse-scored. No legacy block exists. |
| PROMIS-29 Profile v2.0 | `promis_adult_1`–`promis_adult_29` (29) | None | seven raw domains, seven official T scores, pain intensity | **Verified** | CORE health outcomes. Refreshing sleep and four social-role trouble items are direction-corrected. Higher physical/social-role T = better function; higher symptom T = more burden. No global PROMIS total. |
| Actual fraud/loss | `fraud_adult_1`, `fraud_adult_2` | None | `fraud_lifetime_band/any`; `fraud_12mo_band/any` | **Verified** | CORE outcomes. Private item text proves lifetime versus past-12-month loss. Bands are categorical, not exact dollars. |
| Age | `demo_yrs` | None | `demo_yrs` | **Checked field** | CORE covariate. |
| Gender / sex assigned at birth | `demo_gender`, `demo_sab` | None | unchanged private categorical fields | **Checked fields** | CORE covariates; keep constructs distinct. |
| Race / ethnicity | `demo_race`, `demo_eth` | None | unchanged private categorical fields | **Checked fields** | CORE covariates. A legacy numeric White/non-White recode is not applied to the current text-labelled source. |
| Education | `ses_edu`, `ses_yoe` | None | unchanged private fields | **Checked fields** | CORE SES. |
| Household/personal income | `ses_thi`, `ses_tpi` | None | unchanged private categorical fields | **Checked fields** | CORE SES. |
| Home ownership / household resources | `ses_rentown`, `ses_hhr` | None | unchanged private fields | **Checked fields** | CORE SES. |
| Urban/suburban/rural | `demo_quota` | None | unchanged private survey category | **Checked survey field** | CORE/POSSIBLY RELEVANT. This is the survey Urban/Suburban/Rural classification/quota, distinct from broad `region` and GIS-derived RUCA. |
| Current ZIP | `demo_zip_prim` | None | excluded | **Private linkage input** | CORE linkage priority; never written to the general analysis master. |
| Childhood ZIP | `demo_zip_child` | None | excluded | **Private linkage input** | Secondary linkage input. |
| Residence duration | `demo_zip_prim_yr` | None | unchanged private field | **Checked field** | CORE/POSSIBLY RELEVANT. Despite its name, this is duration rather than ZIP. |

## Other measures and batteries

| Domain | Variables present | Classification | Status / decision |
|---|---|---|---|
| Brief Biosocial Gambling Screen | `bbgs_1`–`bbgs_3` | LEGACY / NOT CURRENTLY NEEDED | A legacy scoring block exists; not carried into the grant master. |
| South Oaks Gambling Screen | `sogs_yn`, 37 numbered items (no `sogs_27`) | LEGACY / NOT CURRENTLY NEEDED | Conditional-response battery and legacy scorer exist; not rerun for this handoff. |
| AUDIT / DUDIT | `audit_adult_1`–`audit_adult_10`, `dudit_adult_1`–`dudit_adult_11`, gate | LEGACY / NOT CURRENTLY NEEDED | Raw items present; no current grant score. |
| USI depression/suicidality screen | `usidep_1`–`usidep_8` | POSSIBLY RELEVANT | Legacy count/classification exists, but construct naming and scoring source need scientific confirmation; SUSD depression is the current depression score. |
| Caregiving | `caregiver_yn`, `caregiver_1`–`caregiver_10` | POSSIBLY RELEVANT | Conditional battery; not scored for the fixed grant framework. |
| Convex Time Budget (CTB) | `cbt_adult_1`–`cbt_adult_24` | CORE | Exact choice strings identify four delay pairs with six allocations each. Outputs are `ctb_mean` and four descriptive subscales; 1 = all sooner, 6 = all later. |
| OPR occupation | `opr_category` plus occupation indicator fields | POSSIBLY RELEVANT | These fields appear occupational, not evidence of an “OP” psychometric scale. The historical “OP” item remains unresolved. One source header has trailing nonbreaking whitespace; the current reader normalizes it without modifying the workbook. |
| Payment preferences/barriers | `payment_*`, `email_yn` | POSSIBLY RELEVANT | Administrative/payment constructs; not core-scored. `email_yn` is a yes/no item, not an email address. |
| BIS/BAS, DOSPERT, GSAS, Planfulness | no corresponding raw items | LEGACY / NOT CURRENTLY NEEDED | Blocks exist in the cross-study legacy scorer but the N=709 source lacks their fields. |
| Planfulness attention-check assumption | no `Q341_*`; no `Q341_24` | LEGACY / STALE | `Q341_24` is absent and cannot be this study's attention check. The actual retained-sample check is `attention_check`, with all 709 rows verified as “Apple.” |

## Geographic/context variables

The source workbook contains no derived context. The private pipeline now links
current ZIP directly to ZIP-native Opportunity Insights Social Capital Atlas
and USDA RUCA. It separately crosswalks current ZIP to ZCTA for SDI, ACAG
PM2.5, and ACS B19083 Gini, then removes ZIP/ZCTA before the analysis master is
written. Historical aliases `ec_zip`,
`exposure_grp_mem_zip`, `gini`, and the supported `geo_f` survey-category
compatibility reconstruction from `demo_quota` are private only. Historical
coefficient labels are consistent with, but do not prove, this reconstruction.
See `context-exposure-map.md` for exact provenance. ADI and crime remain
deliberately unavailable for documented geographic/access reasons rather than
being approximated silently.

## Scoring references

- FEVS-SF: Campbell & Lichtenberg short-form description and subsequent
  cross-validation literature (nine scored items; higher summed score indicates
  vulnerability).
- OAFEM: Conrad et al. (2010) item hierarchy and later published implementation
  using 0/1/2 response coding with 1/2/3 severity weights.
- eCog-12: Farias et al. brief Everyday Cognition form, scored as the average
  across completed items.
- 7 Up 7 Down: Youngstrom et al. item split and 0–3 response scoring.
- UCLA loneliness: three-item version, 1–3 responses and summed score.
- MSPSS: Zimet et al. 12-item total and three four-item subscales.
- Need to Belong: Leary et al. 10-item scale; reverse items 1, 3, and 7.
- PROMIS: official HealthMeasures adult profile scoring guidance.
