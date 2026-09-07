# Melanie: start here

Most foundational work is complete in a reproducible N=709 working pipeline. The analyst's role is to reproduce and independently validate it, then complete a small number of substantive extensions needed for a grant-ready product. The technical run guide is [`reproducibility.md`](reproducibility.md); the file map is [`output-map.md`](output-map.md).

## Deliverable 1 — independent reproduction and validation

- Start in a fresh clone with only `private-data/QualtricsData_SDOH_DEIDENTIFIED.xlsx` and run `bash 2025_R03-SDOH/scripts/run-private-pipeline.sh`.
- Confirm `private-data/derived/reproduction-check.md` reports PASS, then preserve `run-provenance.json` for comparison.
- Complete every applicable item in [`independent-validation-checklist.md`](independent-validation-checklist.md), including score maps, fixed context sources, expected Ns, and selected headline models.
- Document discrepancies with the Git SHA, provenance, expected/actual check, and error text—never participant values or geography.

The main review inputs are `melanie-review-packet.md`, `grant-results-audit.md`, `grant-candidate-findings.md`, `context-linkage-audit.md`, `context-correlation.png`, and `figure-index.md`. All remain private.

## Deliverable 2 — targeted new analyses and draft figures

Use [`planned-analyst-extensions.md`](planned-analyst-extensions.md) to conduct the reserved neighborhood-change/trajectory analysis, PM2.5 trajectory sensitivity, selected moderation follow-ups, optional bounded state-sexism analysis, and at most one scientifically justified GIS sensitivity. Do not simply expand or rerun the complete 216-model grid.

Return a compact results table, approximately 5–7 draft figures, meaningful nulls, and an explicit distinction between primary grant-aligned and secondary analyses.

## Deliverable 3 — two-page findings report

Prepare two pages including 2–4 refined figures, 3–5 key findings, important nulls, ZIP/ZCTA limitations, cross-sectional/noncausal language, a specific recommendation for what belongs in the R03/R21, and implications for longitudinal follow-up.

The pipeline automates data validation, scoring, fixed-vintage context linkage, the 709×91 master, historical formula reruns, the fixed 216-model grant-driven framework, and an initial 11-figure menu. Those automated checks are not a substitute for the independent scientific review above.
