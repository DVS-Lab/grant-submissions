# 2025 R03 SDOH

This public project contains the reproducible code, documentation, preserved
aggregate exploratory references, and older aggregate figures for the SDOH
grant analysis. Participant-level inputs and all new N=709 outputs remain
private and untracked.

## Current workflow

The reviewed `QualtricsData_SDOH_DEIDENTIFIED.xlsx` workbook is the
authoritative 709-participant source. From the repository root, run:

```bash
bash 2025_R03-SDOH/scripts/run-private-pipeline.sh
```

The command validates the source and privacy boundary; completes weighted
OAFEM, PROMIS-29 v2.0, CTB, fraud, and other core scoring; downloads and links
public ZIP/ZCTA context sources; builds a geography-free private analysis
master; runs 216 fixed grant specifications and 11 draft figures; creates the
private Melanie review packet; and runs the public-file privacy guard.

See [`docs/melanie-start-here.md`](docs/melanie-start-here.md) for the analyst
handoff, [`docs/measure-map.md`](docs/measure-map.md) for complete construct and
scoring status, [`docs/context-exposure-map.md`](docs/context-exposure-map.md)
for exposure definitions, and [`code/pipeline/README.md`](code/pipeline/README.md)
for implementation details.

## Publication boundary

Public artifacts are limited to code, documentation, the three verified
aggregate historical model-screen CSVs, and already-public aggregate figures.
The N=709 workbook, crosswalk, current/childhood ZIPs, row-level scores,
analysis master, current results, and current figures belong under ignored
`private-data/` only.

Any future participant-level release requires separate scientific and
disclosure-risk review. See [`docs/privacy-protections.md`](docs/privacy-protections.md).
