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
| OAFEM | `oafem_adult_1`–`oafem_adult_30` (30) | None | `oafem_unweighted_complete`; `oafem_items_rated` | **Needs scientific review** | CORE. No/Suspected/Yes is recoded 0/1/2; Unknown/N/A remains missing. Published scoring requires item-specific severity weights, but generic workbook names cannot be aligned to those weights. No weighted `oafem_adult_total` is asserted. |
| Everyday Cognition (eCog-12) | `ecog_1`–`ecog_12` (12) | None | `ecog_total`; `ecog_items_answered` | **Verified** | CORE. Responses 1–4; mean of answered items, matching the published mean-of-completed-items rule. |
| 7 Up 7 Down / SUSD | `susd_matrix_1`–`susd_matrix_14` (14) | None | `susd_depression`, `susd_mania` | **Verified** | CORE. Seven items per subscale, 0–3, complete-case sums. The item sets match legacy code; misleading copied comments/renumbering are not reused. |
| UCLA 3-item loneliness | `uclal_1`–`uclal_3` (3) | None | `uclal_total`, 3–9 | **Verified** | CORE. A source typo, “Hardly Every,” is normalized to “Hardly Ever”; complete-case sum. Legacy `na.rm=TRUE` behavior is not retained. |
| MSPSS | `mspss_adult_1`–`mspss_adult_12` (12) | None | total mean plus significant-other, family, and friends means | **Verified** | CORE. Standard 1–7 response mapping and four-item subscales. |
| Need to Belong | `ntb_1`–`ntb_10` (10) | None | `ntb_total`, `ntb_mean` | **Verified** | CORE/POSSIBLY RELEVANT moderator. Standard 1–5 mapping; items 1, 3, and 7 reverse-scored. No legacy block exists. |
| PROMIS-29 profile | `promis_adult_1`–`promis_adult_29` (29) | None | seven four-item raw domain sums plus pain intensity | **Implemented but needs scientific review** | CORE health covariates. The 29-column structure matches seven domains plus 0–10 pain intensity. T-scores are withheld until the exact administered PROMIS version and scoring table/service are confirmed. There is no defensible single PROMIS total. |
| Actual fraud/loss | `fraud_adult_1`, `fraud_adult_2` | None | ordered loss-band codes and any-loss indicators for each item | **Verified recode; construct labels need review** | CORE outcome candidates. The bands are categorical, not exact dollar loss. The semantic distinction between the two questions is not recoverable from column names alone. |
| Age | `demo_yrs` | None | `demo_yrs` | **Validated field** | CORE covariate. |
| Gender / sex assigned at birth | `demo_gender`, `demo_sab` | None | unchanged private categorical fields | **Validated fields** | CORE covariates; keep constructs distinct. |
| Race / ethnicity | `demo_race`, `demo_eth` | None | unchanged private categorical fields | **Validated fields** | CORE covariates. A legacy numeric White/non-White recode is not applied to the current text-labelled source. |
| Education | `ses_edu`, `ses_yoe` | None | unchanged private fields | **Validated fields** | CORE SES. |
| Household/personal income | `ses_thi`, `ses_tpi` | None | unchanged private categorical fields | **Validated fields** | CORE SES. |
| Home ownership / household resources | `ses_rentown`, `ses_hhr` | None | unchanged private fields | **Validated fields** | CORE SES. |
| Urban/suburban/rural | `demo_quota` | None | unchanged private category | **Validated survey field** | CORE/POSSIBLY RELEVANT. This is not a reproduced geographic rurality lookup. |
| Current ZIP | `demo_zip_prim` | None | excluded | **Private linkage input** | CORE linkage priority; never written to the general analysis master. |
| Childhood ZIP | `demo_zip_child` | None | excluded | **Private linkage input** | Secondary linkage input. |
| Residence duration | `demo_zip_prim_yr` | None | unchanged private field | **Validated field** | CORE/POSSIBLY RELEVANT. Despite its name, this is duration rather than ZIP. |

## Other measures and batteries

| Domain | Variables present | Classification | Status / decision |
|---|---|---|---|
| Brief Biosocial Gambling Screen | `bbgs_1`–`bbgs_3` | LEGACY / NOT CURRENTLY NEEDED | A legacy scoring block exists; not carried into the grant master. |
| South Oaks Gambling Screen | `sogs_yn`, 37 numbered items (no `sogs_27`) | LEGACY / NOT CURRENTLY NEEDED | Conditional-response battery and legacy scorer exist; not rerun for this handoff. |
| AUDIT / DUDIT | `audit_adult_1`–`audit_adult_10`, `dudit_adult_1`–`dudit_adult_11`, gate | LEGACY / NOT CURRENTLY NEEDED | Raw items present; no current grant score. |
| USI depression/suicidality screen | `usidep_1`–`usidep_8` | POSSIBLY RELEVANT | Legacy count/classification exists, but construct naming and scoring source need scientific confirmation; SUSD depression is the current depression score. |
| Caregiving | `caregiver_yn`, `caregiver_1`–`caregiver_10` | POSSIBLY RELEVANT | Conditional battery; not scored for the fixed grant framework. |
| CBT/temporal-choice battery | `cbt_adult_1`–`cbt_adult_24` | UNKNOWN — NEEDS SCIENTIFIC DECISION | The items appear to be intertemporal choices. The historical “CTB” note may be a transposition, but that cannot be proved from generic names. Not assumed grant-relevant. |
| OPR occupation | `opr_category` plus occupation indicator fields | POSSIBLY RELEVANT | These fields appear occupational, not evidence of an “OP” psychometric scale. The historical “OP” item remains unresolved. One source header has trailing nonbreaking whitespace; the current reader normalizes it without modifying the workbook. |
| Payment preferences/barriers | `payment_*`, `email_yn` | POSSIBLY RELEVANT | Administrative/payment constructs; not core-scored. `email_yn` is a yes/no item, not an email address. |
| BIS/BAS, DOSPERT, GSAS, Planfulness | no corresponding raw items | LEGACY / NOT CURRENTLY NEEDED | Blocks exist in the cross-study legacy scorer but the N=709 source lacks their fields. |
| Planfulness attention-check assumption | no `Q341_*`; no `Q341_24` | LEGACY / STALE | `Q341_24` is absent and cannot be this study's attention check. The actual retained-sample check is `attention_check`, with all 709 rows verified as “Apple.” |

## Geographic/context variables

No derived ADI, deprivation, disadvantage, social capital, economic
connectedness, PM2.5, Gini, or geographic rurality variable exists in the
authoritative workbook. Prior aggregate formulas refer to `ec_zip`,
`exposure_grp_mem_zip`, `gini`, and `geo_f`; their source/coding is not present
in the current data. The private `context-linkage-audit.md` records the exact
historical evidence and unresolved inputs.

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
