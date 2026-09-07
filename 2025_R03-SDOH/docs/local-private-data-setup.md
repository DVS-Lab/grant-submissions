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
```

The root `.gitignore` protects `private-data/`. In a local, ignored `.Renviron`,
configure paths such as:

```text
SDOH_SOURCE_DATA=/absolute/local/path/2025_R03-SDOH/private-data/QualtricsData_SDOH_DEIDENTIFIED.xlsx
SDOH_PRIVATE_DERIVATIVES_DIR=/absolute/local/path/2025_R03-SDOH/private-data/derived
```

No environment configuration is required when the workbook is at the
recommended default path. Run the complete workflow from the repository root:

```sh
bash 2025_R03-SDOH/scripts/run-private-pipeline.sh
```

Optional reviewed contextual linkage may be supplied with
`SDOH_CONTEXT_DATA`; set `SDOH_CONTEXT_VARIABLE` to its primary exposure.

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
