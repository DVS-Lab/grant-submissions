# Reproducing the private SDOH pipeline

This is the canonical technical guide. On macOS, the handoff requires one
private file and one setup command.

## Minimum input

On a Mac, download only the reviewed handoff file to:

```text
~/Downloads/QualtricsData_SDOH_DEIDENTIFIED.xlsx
```

Keep that exact filename. The setup helper creates the ignored project folders
and copies it into the required location. Do not copy the raw Qualtrics export,
a ResponseId crosswalk, another analyst's cache, or old private results.

For a new clone, open Terminal and run:

```bash
cd "$HOME/Documents"
git clone https://github.com/DVS-Lab/grant-submissions.git
cd grant-submissions
bash 2025_R03-SDOH/scripts/setup-macos.sh
```

If the repository is already cloned, change into its root directory and run
only the final command.

## Requirements

- macOS: Git, `curl`, internet access, and roughly 0.5–1 GB of free disk space.
  The setup helper installs missing R/Python
  runtimes through Homebrew. If Homebrew is absent, it prints the exact manual
  prerequisite steps because installing Apple's command-line tools and
  Homebrew may require a GUI confirmation or administrator password.
- R 4.5.2. On macOS, the helper installs the Homebrew `r-rig` version manager,
  installs the exact reference R, and locates its executable by the version it
  reports. This avoids depending on `rig`'s architecture-specific installation
  name (for example, `4.5-arm64`) or changing the Mac's global default R.
  `renv.lock` records exact R package versions; the runner restores them into ignored
  `private-data/reference/.r-library`, never the global library.
- Python 3.11 or newer with `venv`. On macOS, the helper first discovers
  compatible Homebrew interpreters even when Homebrew is not on `PATH`. If none
  exists, it tries Python 3.13 and then Python 3.12. Both currently have
  Homebrew bottles for Apple-silicon macOS Tahoe. The reference run used Python
  3.12.14, and the handoff was also clean-room tested with Python 3.13.12, on
  Apple Silicon macOS. Direct requirements are in `requirements.in`; the
  complete 19-package reference resolution is in `requirements-lock.txt`.
  Binary availability for geospatial packages can differ by Python version,
  architecture, and operating system, so another platform may need
  compilers/system GIS libraries while retaining the same pins.
  The ignored local cache contains Python/R libraries, eleven annual PM2.5
  grids, and Census geometry.

Reference reproduction was performed on Apple Silicon macOS. Other Unix-like
platforms should be feasible but have not been independently clean-room tested;
native Windows is not currently a tested configuration.

The first run installs isolated dependencies, downloads checksummed public files, and performs polygon/raster aggregation, so it can take many minutes. Later runs verify and reuse the cache.

## First-time Mac setup and run

From the repository root:

```bash
bash 2025_R03-SDOH/scripts/setup-macos.sh
```

The helper looks in Downloads by default. To use a different location:

```bash
bash 2025_R03-SDOH/scripts/setup-macos.sh --source "/full/path/to/QualtricsData_SDOH_DEIDENTIFIED.xlsx"
```

Use `--prepare-only` to create/import the private input and settle system
dependencies without starting the analysis. After first-time setup, either
setup command can be rerun safely; it reuses verified environments and caches.

The workflow (1) checks privacy and participant-free public contracts, (2)
creates/repairs isolated Python and R environments, (3) validates and scores the
workbook, (4) downloads verified fixed-vintage national context files without
transmitting participant geography, (5) links ZIP-native Social Capital Atlas
and RUCA directly to current ZIP, uses crosswalked ZCTA for SDI/Gini/PM2.5, and
builds the 709×91 geography-free analysis master, (6) reruns 35 historical
formulas and the fixed 216-model grant-driven framework, (7) generates 11
private draft figures and review documents, (8) checks the public reproduction
contract, and (9) writes private run provenance.

## Manual fallback when Homebrew is missing

The setup helper prints these same steps and stops before analysis:

1. Open Terminal.
2. Run `xcode-select --install` and complete Apple's prompt if command-line
   tools are not already present.
3. Install Homebrew using the official command at
   <https://brew.sh/>.
4. Run the PATH command printed under Homebrew's **Next steps**. On most
   Apple-silicon Macs it is `eval "$(/opt/homebrew/bin/brew shellenv)"`.
5. Return to the repository and rerun
   `bash 2025_R03-SDOH/scripts/setup-macos.sh`.

If automatic exact-R setup alone fails, run:

```bash
brew install r-rig
rig add 4.5.2
rig list
bash 2025_R03-SDOH/scripts/setup-macos.sh
```

`rig list` may name this installation `4.5-arm64` even though it contains R
4.5.2. Do not run `rig default 4.5.2`; the setup helper finds and uses the exact
installed executable directly.

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

- **Workbook missing:** save it under the exact filename in `~/Downloads`, or
  pass its full path with `--source`. The helper creates the project folder.
- **No internet/transient failure:** keep the verified cache and rerun. Downloads use three attempts, timeouts, `.part` files, exact byte sizes, and SHA-256 checks; an interrupted file is not accepted.
- **AAFP certificate error:** the SDI downloader automatically tries the fixed
  archival capture of the original Robert Graham Center file and accepts it only
  when its uncompressed bytes match the same pinned size and SHA-256. Do not use
  `curl -k` or disable TLS verification.
- **R or Python unavailable on a Mac:** use `setup-macos.sh`, not the lower-level
  runner. Follow its Homebrew instructions if it cannot install the runtimes.
- **Homebrew could not install Python:** rerun after `git pull`; the helper now
  detects usable partial/existing installations and tries both supported Python
  formulas. Homebrew does not need `sudo` for this step. If both attempts fail,
  follow the printed `xcode-select -p`, `brew doctor`, and `brew install`
  diagnostics; retain their complete output.
- **`rig` says installation succeeded and then says R is not installed:** do not
  uninstall R. Run `git pull`, then rerun `setup-macos.sh`. The helper checks
  architecture-specific framework installations directly and does not require
  `Rscript` to be on `PATH` or R 4.5.2 to be the global default.
- **Python unavailable on another platform:** install Python 3.11+ with `venv`.
  To use an existing compatible environment, set `SDOH_CONTEXT_PYTHON`; the
  runner verifies it but never modifies it.
- **Pinned Python wheel unavailable:** use Python 3.12 on a supported 64-bit platform or install the platform compiler/GDAL prerequisites. Do not loosen the lock silently; document any necessary alternate resolution.
- **R package build failure:** run `xcode-select --install`, complete the Apple
  prompt if one appears, and rerun. The ignored local library can be rebuilt
  without changing the global R library.
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
