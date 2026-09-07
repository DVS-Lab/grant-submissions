# Melanie: start here

## What is already done?

The private N=709 workbook is the authoritative source. Its structure, key,
privacy fields, attention check, and `gc` have been validated. Existing code
and Git history have been inventoried; reusable scoring logic was reconciled;
a current modular pipeline, historical-formula runner, fixed candidate model
set, score checks, and private figure generator now exist. Do not reconstruct
the old repository history or rerun unrelated gambling analyses.

## What command do I run?

From the repository root:

```bash
bash 2025_R03-SDOH/scripts/run-private-pipeline.sh
```

## Where are the outputs?

Everything current is private under `2025_R03-SDOH/private-data/derived/`.
Start with `source-qc.md`, `score-validation.md`, `context-linkage-audit.md`,
`analysis-master.csv`, `model-screen-comparison.csv`,
`grant-candidate-results.csv`, and `figure-index.md`.

## What should I not redo?

Do not rebuild path setup, source/schema QC, the measure inventory, verified
FEVS/eCog/SUSD/UCLA/MSPSS/NTB scoring, raw PROMIS domains, fraud-band recodes,
the 35-formula historical runner, or the initial fixed models/figures.

## What actually requires my judgment?

1. Confirm OAFEM item order/severity weights from an item-labelled instrument
   or codebook; then approve replacing the provisional unweighted diagnostic.
2. Confirm the administered PROMIS-29 version and approve official domain
   T-score conversion.
3. Supply/approve the intended contextual construct and source vintage (ADI,
   PM2.5, rurality, etc.), including whether ZIP-level linkage is acceptable.
4. Identify the semantic distinction between `fraud_adult_1` and
   `fraud_adult_2`, and decide whether historical “CTB” or “OP” labels matter to
   this grant.
5. Review the fixed private results for scientific defensibility and grant
   relevance, request only targeted follow-ups, select/refine 2–4 private draft
   figures, and write the final two-page findings narrative without causal
   claims.
