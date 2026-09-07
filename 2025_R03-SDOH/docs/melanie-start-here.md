# Melanie: start here

## What is done

- Source cleaning, schema/QC, attention-check validation, and privacy guards.
- Verified scoring for FEVS, weighted OAFEM, eCog, SUSD, UCLA loneliness,
  MSPSS, Need to Belong, PROMIS-29 v2.0 T scores, the Convex Time Budget task,
  and lifetime/past-12-month fraud outcomes.
- A 709-row private analysis master containing individual measures and derived
  context but no current/childhood ZIP, ZCTA, response ID, contact field, or
  platform identifier.
- Current ZIP validation and reproducible ZIP→ZCTA linkage, with childhood ZIP
  feasibility counts kept separate.
- Primary context measures: ZCTA SDI, 2012–2022 area-weighted PM2.5, ACS Gini,
  Opportunity Insights economic connectedness, and USDA RUCA; selected Social
  Capital variables and an exploratory burden composite are secondary.
- A focused ADI feasibility decision and crime/disorder source audit. Neither
  was converted into a misleading ZIP score.
- A fixed 216-specification grant framework; 17/35 historical formulas rerun;
  11 private draft figures; balanced results, candidate-findings, unused-measure,
  and context-candidate audits.

## Run and open

From the repository root:

```bash
bash 2025_R03-SDOH/scripts/run-private-pipeline.sh
```

Open `2025_R03-SDOH/private-data/derived/melanie-review-packet.md` first. Then
use `grant-results-audit.md`, `grant-candidate-findings.md`,
`context-linkage-audit.md`, `context-correlation.png`, and `figure-index.md`.
All are private.

## What may still need GIS/scientific judgment

1. Whether latitude-corrected area-weighted ZCTA PM2.5 is sufficient or a
   population-weighted sensitivity is worth the added GIS work.
2. Whether an explicitly labeled population-weighted block-group→ZCTA ADI
   proxy is worth pursuing after obtaining a credentialed Neighborhood Atlas
   vintage; ZIP ADI is not validated by Neighborhood Atlas.
3. Whether crime/disorder warrants a coarser county UCR sensitivity or a
   tract-level academic product despite coverage/geography tradeoffs.
4. Which Social Capital indicators best operationalize “social cohesion.” Do
   not treat economic connectedness and high-SES exposure as independent
   substitutes without considering their high correlation.
5. Whether the chosen SDI, ACS, Social Capital, RUCA, and boundary vintages are
   acceptable for preliminary grant use, or whether one narrowly targeted
   alternate-vintage check is justified.

## What Melanie should actually do

1. Audit and approve the substantive exposure choices and caveats.
2. Review all fixed results, including the PM2.5/CTB and broad context-health
   nulls, and decide which statements the preliminary data genuinely support.
3. Request or run only a small number of scientifically motivated follow-ups
   that resolve a stated ambiguity.
4. Select and refine 2–4 grant figures from the private 11-figure menu.
5. Write the final two-page findings report using effect sizes, uncertainty,
   cross-sectional language, and the approved GIS interpretation.

She does not need to identify instruments, reconstruct scoring, find routine
public ZIP data, rebuild old formulas, perform basic cleaning/linkage, or
generate the initial figure menu.
