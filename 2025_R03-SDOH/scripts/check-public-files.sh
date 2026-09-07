#!/usr/bin/env bash

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
project_path="2025_R03-SDOH"
approved_dictionary="2025_R03-SDOH/docs/analytic-variable-dictionary.csv"
unix_users_root="/Users"
windows_users_segment='\\Users\\'
machine_path_pattern="${unix_users_root}/[^/]+/|[A-Za-z]:${windows_users_segment}"
failed=0

while IFS= read -r tracked_path; do
  normalized_path=$(printf '%s' "$tracked_path" | tr '[:upper:]' '[:lower:]')
  case "$normalized_path" in
    *.csv)
      if [[ "$tracked_path" != "$approved_dictionary" ]]; then
        printf 'ERROR: unexpected tracked SDOH CSV: %s\n' "$tracked_path" >&2
        failed=1
      fi
      ;;
    *.tsv|*.xlsx|*.xls|*.rds|*.rdata|*.parquet|*.feather|*.sav|*.dta)
      printf 'ERROR: prohibited tracked SDOH data file: %s\n' "$tracked_path" >&2
      failed=1
      ;;
  esac
done < <(git -C "$repo_root" ls-files "$project_path")

if git -C "$repo_root" grep -nE \
  "$machine_path_pattern" -- \
  "${project_path}/code" "${project_path}/docs"; then
  printf 'ERROR: machine-specific absolute path found in tracked SDOH code/docs.\n' >&2
  failed=1
fi

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

printf 'Public SDOH tracked-file checks passed.\n'
