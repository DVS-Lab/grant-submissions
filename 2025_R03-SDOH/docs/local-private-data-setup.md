# Local private-data setup

Analysts who receive the reviewed N=709 source separately may store it inside an
ignored local directory in their clone. It must never be uploaded to GitHub: not
to `main`, not to a feature branch, and not to a purportedly private branch in
this public repository.

On macOS, the setup helper creates this structure automatically:

```text
grant-submissions/
  2025_R03-SDOH/
    private-data/
      QualtricsData_SDOH_DEIDENTIFIED.xlsx
      derived/
      reference/
```

Download the reviewed workbook to the Mac's Downloads folder with this exact
name:

```text
~/Downloads/QualtricsData_SDOH_DEIDENTIFIED.xlsx
```

Then run the complete setup and workflow from the repository root:

```sh
bash 2025_R03-SDOH/scripts/setup-macos.sh
```

The helper creates `private-data/`, `derived/`, and `reference/`; copies the
workbook without overwriting a different existing copy; applies owner-only file
permissions; and verifies that Git ignores it. It installs/locates reference R
4.5.2 and Python 3.12 through Homebrew only when needed. The pipeline then
creates isolated Python and R package libraries and caches verified public
context downloads under ignored `private-data/reference/`.

If Homebrew is missing, the helper cannot install system runtimes by itself. It
prints numbered commands to install Apple's command-line tools and Homebrew;
complete those steps and rerun the helper. R and Python package dependencies do
not need to be installed manually. See
[`reproducibility.md`](reproducibility.md) for platform requirements, optional
overrides, troubleshooting, and safe cache cleanup.

For a workbook stored elsewhere, supply its full path:

```sh
bash 2025_R03-SDOH/scripts/setup-macos.sh --source "/full/path/to/QualtricsData_SDOH_DEIDENTIFIED.xlsx"
```

Verify the source is ignored:

```sh
git check-ignore -v \
  2025_R03-SDOH/private-data/QualtricsData_SDOH_DEIDENTIFIED.xlsx
```

Before every commit or push, run:

```sh
git status --short
git ls-files 2025_R03-SDOH/private-data
```

The second command must return no files. Never use `git add -f` for participant
data.
