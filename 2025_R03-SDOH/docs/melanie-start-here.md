# Melanie: start here

Most foundational work is complete in a reproducible N=709 working pipeline. The analyst's role is to reproduce and independently validate it, then complete a small number of substantive extensions needed for a grant-ready product. The technical run guide is [`reproducibility.md`](reproducibility.md); the file map is [`output-map.md`](output-map.md).

## Deliverable 1 — independent reproduction and validation

- Download the controlled handoff workbook to
  `~/Downloads/QualtricsData_SDOH_DEIDENTIFIED.xlsx`; do not rename it, and do
  not download or copy a raw export or ResponseId crosswalk.
- For a new clone, open Terminal and run:

  ```bash
  cd "$HOME/Documents"
  git clone https://github.com/DVS-Lab/grant-submissions.git
  cd grant-submissions
  bash 2025_R03-SDOH/scripts/setup-macos.sh
  ```

  If the repository is already cloned, open its `grant-submissions` folder in
  Terminal and run only the final `bash` command. The command creates the protected
  folders, copies the workbook, installs/selects reference R 4.5.2 and a
  compatible Python if needed, builds isolated package libraries, and runs the
  pipeline. If Homebrew is not installed, follow the numbered instructions the
  command prints, then rerun the same command.
- If the workbook is somewhere other than Downloads, run
  `bash 2025_R03-SDOH/scripts/setup-macos.sh --source "/full/path/to/QualtricsData_SDOH_DEIDENTIFIED.xlsx"`.
- Confirm `private-data/derived/reproduction-check.md` reports PASS, then preserve `run-provenance.json` for comparison.
- Confirm Social Capital Atlas coverage reflects direct participant-current-ZIP
  matching with no ZCTA fallback; SDI, Gini, and PM2.5 remain ZCTA-linked.
- Complete every applicable item in [`independent-validation-checklist.md`](independent-validation-checklist.md), including score maps, fixed context sources, expected Ns, and selected headline models.
- Document discrepancies with the Git SHA, provenance, expected/actual check, and error text—never participant values or geography.

The main review inputs are `melanie-review-packet.md`, `grant-results-audit.md`, `grant-candidate-findings.md`, `context-linkage-audit.md`, `context-correlation.png`, and `figure-index.md`. All remain private.

## Deliverable 2 — targeted new analyses and draft figures

Use [`planned-analyst-extensions.md`](planned-analyst-extensions.md) to conduct the reserved neighborhood-change/trajectory analysis, PM2.5 trajectory sensitivity, selected moderation follow-ups, optional bounded state-sexism analysis, and at most one scientifically justified GIS sensitivity. Do not simply expand or rerun the complete 216-model grid.

Return a compact results table, approximately 5–7 draft figures, meaningful nulls, and an explicit distinction between primary grant-aligned and secondary analyses.

## Deliverable 3 — two-page findings report

Prepare two pages including 2–4 refined figures, 3–5 key findings, important nulls, ZIP/ZCTA limitations, cross-sectional/noncausal language, a specific recommendation for what belongs in the R03/R21, and implications for longitudinal follow-up.

The pipeline automates data validation, scoring, fixed-vintage context linkage, the 709×91 master, historical formula reruns, the fixed 216-model grant-driven framework, and an initial 11-figure menu. Those automated checks are not a substitute for the independent scientific review above.
