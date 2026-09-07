# SDOH analysis status

## Complete / validated

- The authoritative private workbook is structurally validated at 709 rows and
  300 columns; `study_id` is complete and unique.
- The retained sample passes the documented attention check and `gc == 1`; the
  pipeline applies no new exclusion.
- A modular one-command pipeline builds a private analysis master without ZIPs.
- FEVS, eCog, 7 Up 7 Down/SUSD, UCLA loneliness, MSPSS, and Need to Belong have
  explicit response maps, missingness rules, and range checks.
- Two categorical fraud/loss items are recoded into separate loss-band and
  any-loss variables.
- Three identifier-free aggregate historical model-screen references are
  preserved publicly. Their 35 unique formulas (16 FEVS, 19 OAFEM) can be
  classified and rerun automatically when required variables exist.
- A fixed, non-p-value-selected grant model framework and systematic private
  draft figures are generated on every run.

## Implemented but needs scientific review

- OAFEM item responses are recoded, but the generic 30 item names cannot be
  mapped reliably to published severity categories. The pipeline emits only a
  clearly named unweighted complete-case diagnostic; it does not claim a
  verified weighted OAFEM total.
- PROMIS-29 raw domain sums and pain intensity are generated. Confirm the exact
  administered profile/version before applying official T-score conversions.
- The two fraud/loss variables have unambiguous ordered response bands, but
  their distinct question meanings need a codebook/item-text decision.

## Not yet reconstructed

- No contextual score exists in the N=709 source. Historical evidence names
  `ec_zip`, `exposure_grp_mem_zip`, `gini`, and `geo_f`, plus an address-to-Census
  block-group/Neighborhood Atlas ADI and PM2.5 workflow. The exact ADI release,
  PM2.5 provider/version, rurality source, and acceptability of substituting a
  current-ZIP linkage are unresolved. No source or vintage was guessed.
- Consequently, context-dependent historical and candidate models remain
  automatically classified as not runnable until a reviewed private linkage is
  supplied.

Private validation, comparison, candidate-result, linkage-audit, and figure
outputs are regenerated under `private-data/derived/`; they must not be
committed.
