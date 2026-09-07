#!/usr/bin/env bash

set -euo pipefail
repo_root=$(git rev-parse --show-toplevel)
dummy="$repo_root/2025_R03-SDOH/synthetic-participant-negative-test.csv"
cleanup() {
  git -C "$repo_root" rm --cached --quiet --ignore-unmatch -- "2025_R03-SDOH/synthetic-participant-negative-test.csv" || true
  rm -f -- "$dummy"
}
trap cleanup EXIT
printf 'study_id,zip\nSYNTHETIC-ONLY,00000\n' > "$dummy"
git -C "$repo_root" add -f -- "2025_R03-SDOH/synthetic-participant-negative-test.csv"
if bash "$repo_root/2025_R03-SDOH/scripts/check-public-files.sh" >/dev/null 2>&1; then
  printf 'ERROR: privacy guard accepted a synthetic participant-like CSV.\n' >&2
  exit 1
fi
printf 'Privacy negative test passed: the synthetic participant-like CSV was rejected and removed.\n'
