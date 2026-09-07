# Local private-data setup

Analysts who receive the reviewed N=709 source separately may store it inside an
ignored local directory in their clone. It must never be uploaded to GitHub: not
to `main`, not to a feature branch, and not to a purportedly private branch in
this public repository.

Recommended local structure:

```text
grant-submissions/
  2025_R03-SDOH/
    private-data/
      QualtricsData_SDOH_DEIDENTIFIED.xlsx
      derived/
      reference/
```

The root `.gitignore` protects `private-data/`. No environment configuration or
manual package installation is required when the workbook is at the recommended
default path. Run the complete workflow from the repository root:

```sh
bash 2025_R03-SDOH/scripts/run-private-pipeline.sh
```

The runner creates isolated Python and R libraries and caches verified public
context downloads under ignored `private-data/reference/`. See
[`reproducibility.md`](reproducibility.md) for platform requirements, optional
overrides, troubleshooting, and safe cache cleanup.

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
