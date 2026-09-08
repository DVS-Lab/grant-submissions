# 2025 R03 SDOH

This public project contains the reproducible code, documentation, preserved
aggregate exploratory references, and older aggregate figures for the SDOH
grant analysis. Participant-level inputs and all new N=709 outputs remain
private and untracked.

## Canonical analyst workflow

On a Mac, clone the repository and download the single controlled handoff file
as `~/Downloads/QualtricsData_SDOH_DEIDENTIFIED.xlsx`. Then run from the
repository root:

```bash
bash 2025_R03-SDOH/scripts/setup-macos.sh
```

The setup command creates the ignored private folders, safely copies the
workbook from Downloads, checks its Git protection, installs/selects reference R
4.5.2 and Python 3.12 when needed, and then runs the complete pipeline. If
Homebrew itself is absent, it stops with step-by-step installation instructions.
No raw export, ResponseId crosswalk, pre-existing cache, or manually prepared
R/Python package library is required. The workflow validates the source and
privacy boundary; completes weighted
OAFEM, PROMIS-29 v2.0, CTB, fraud, and other core scoring; downloads and links
public context sources using direct ZIP linkage or ZCTA linkage as appropriate;
builds a geography-free private analysis
master; runs 216 fixed grant specifications and 11 draft figures; creates the
private Melanie review packet; verifies the public reproduction contract; writes
private run provenance; and runs the public-file privacy guard. Open
`2025_R03-SDOH/private-data/derived/reproduction-check.md` and then
`melanie-review-packet.md`.

This is a reproducible N=709 working pipeline pending independent scientific
validation. See [`docs/README.md`](docs/README.md) for the canonical documentation
index, [`docs/melanie-start-here.md`](docs/melanie-start-here.md) for the analyst
handoff, [`docs/measure-map.md`](docs/measure-map.md) for complete construct and
scoring status, [`docs/context-exposure-map.md`](docs/context-exposure-map.md)
for exposure definitions, and [`code/pipeline/README.md`](code/pipeline/README.md)
for implementation details, and [`docs/reproducibility.md`](docs/reproducibility.md)
for clean-clone setup, cache cleanup, and troubleshooting.

## Publication boundary

Public artifacts are limited to code, documentation, the three verified
aggregate historical model-screen CSVs, and already-public aggregate figures.
The N=709 workbook, crosswalk, current/childhood ZIPs, row-level scores,
analysis master, current results, and current figures belong under ignored
`private-data/` only.

Any future participant-level release requires separate scientific and
disclosure-risk review. See [`docs/privacy-protections.md`](docs/privacy-protections.md).
