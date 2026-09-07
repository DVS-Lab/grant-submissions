# Reproducing the private SDOH pipeline

This is the canonical technical guide. The handoff requires one private file and one command.

## Minimum input

Clone the public repository, then place only:

```text
2025_R03-SDOH/private-data/QualtricsData_SDOH_DEIDENTIFIED.xlsx
```

Do not copy the raw Qualtrics export, a ResponseId crosswalk, another analyst's cache, or old private results.

## Requirements

- Git, `curl`, and internet access for the first run.
- R. The reference run used R 4.5.2 on Apple Silicon macOS; `renv.lock` records exact package versions and the runner restores them into ignored `private-data/reference/.r-library`, never the global library.
- Python 3.11 or newer with `venv` (plus any `python3` 3.9+ executable for the pre-bootstrap public tests). The reference run used Python 3.12.14 on Apple Silicon macOS. Direct requirements are in `requirements.in`; the complete 19-package reference resolution is in `requirements-lock.txt`. Binary availability for geospatial packages can differ by Python version, architecture, and operating system, so a platform without compatible wheels may need compilers/system GIS libraries while retaining the same pins. Set `SDOH_BOOTSTRAP_PYTHON` only when automatic interpreter discovery cannot find the intended 3.11+ interpreter.
- Free disk space. The public Git repository is small; the ignored local cache can reach roughly 0.5–1 GB because it contains Python/R libraries, eleven annual PM2.5 grids, and Census geometry.

Reference reproduction was performed on Apple Silicon macOS. Other Unix-like
platforms should be feasible but have not been independently clean-room tested;
native Windows is not currently a tested configuration.

The first run installs isolated dependencies, downloads checksummed public files, and performs polygon/raster aggregation, so it can take many minutes. Later runs verify and reuse the cache.

## One-command run

From the repository root:

```bash
bash 2025_R03-SDOH/scripts/run-private-pipeline.sh
```

The command (1) checks privacy and participant-free public contracts, (2) creates/repairs isolated Python and R environments, (3) validates and scores the workbook, (4) downloads verified fixed-vintage national context files without transmitting participant geography, (5) links ZIP-native Social Capital Atlas and RUCA directly to current ZIP, uses crosswalked ZCTA for SDI/Gini/PM2.5, and builds the 709×91 geography-free analysis master, (6) reruns 35 historical formulas and the fixed 216-model grant-driven framework, (7) generates 11 private draft figures and review documents, (8) checks the public reproduction contract, and (9) writes private run provenance.

## Expected success

The terminal ends with `Private pipeline complete`. Open these in order:

1. `private-data/derived/reproduction-check.md` — overall PASS and aggregate structural checks.
2. `private-data/derived/melanie-review-packet.md` — scientific review entry point.
3. `private-data/derived/run-provenance.json` — code/source/environment identity for this run.

Expected anchors are N=709, a 91-column analysis master, direct-ZIP Social
Capital coverage of 668 for economic connectedness and 663 for high-SES
exposure, 216 fixed model specifications, 17/35 runnable historical formulas,
and 11 PNG figures. The authoritative public contract is
`config/reproduction-contract.json`.

## Troubleshooting

- **Workbook missing:** confirm the exact filename and default location above.
- **No internet/transient failure:** keep the verified cache and rerun. Downloads use three attempts, timeouts, `.part` files, exact byte sizes, and SHA-256 checks; an interrupted file is not accepted.
- **Python unavailable:** install a Python 3 distribution that includes `venv`. To use an existing compatible environment, set `SDOH_CONTEXT_PYTHON`; the runner verifies it but never modifies it.
- **Pinned Python wheel unavailable:** use Python 3.12 on a supported 64-bit platform or install the platform compiler/GDAL prerequisites. Do not loosen the lock silently; document any necessary alternate resolution.
- **R package build failure:** install the operating-system compiler tools required by R and rerun. The ignored local library can be rebuilt without changing the global R library.
- **External source checksum/schema changed:** do not bypass the check. Compare the provider's fixed release with `config/reproducibility-sources.json`, document the change, and update code/config only after scientific review.
- **Insufficient disk:** use the cache dry run below, then remove the rebuildable cache. Private scientific results are not removed.
- **Discrepancy:** preserve `reproduction-check.md` and `run-provenance.json`; record the failed check, Git SHA, platform, and error text, without participant values or geography.

## Re-running and cache cleanup

Re-run the same command; verified sources and environments are reused. To preview cache removal:

```bash
bash 2025_R03-SDOH/scripts/clean-private-cache.sh --dry-run
```

Then, only if a clean rebuild is wanted:

```bash
bash 2025_R03-SDOH/scripts/clean-private-cache.sh --execute
```

The cleanup script removes only reconstructable dependency/source caches. It never removes the XLSX, `private-data/derived/`, analysis results, review packet, or figures. Do not zip or email the whole `private-data/` directory; the handoff file is the single deidentified XLSX.

## Privacy

Never stage `private-data/`, never use `git add -f` for participant data, and never upload a source workbook, linked ZIP/ZCTA file, or private provenance/results to this public repository. Before sharing code, run `bash 2025_R03-SDOH/scripts/check-public-files.sh`.

## Reference clean-room verification

The final handoff commit—identified by `git rev-parse HEAD` and recorded in the
handoff report—was tested in a new temporary clone containing only the
deidentified XLSX. On Apple Silicon macOS it discovered Python 3.13.12, restored
the exact Python and R locks, downloaded 17 pinned public files, and passed the
full reproduction contract. A second unchanged run reused both environments and
all 17 cached source files, passed again, retained exactly 11 figures, and left
no partial-download or figure-staging files. Both runs emitted the five
documented `glm.fit` numerical-boundary warnings; these are flagged for human
statistical review rather than suppressed. No tracked file changed after this
exact-commit verification.
