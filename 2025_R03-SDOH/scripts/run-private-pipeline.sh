#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
project_root=$(cd -- "$script_dir/.." && pwd)
repo_root=$(git -C "$project_root" rev-parse --show-toplevel)
default_source="$project_root/private-data/QualtricsData_SDOH_DEIDENTIFIED.xlsx"
source_data=${SDOH_SOURCE_DATA:-$default_source}
private_derivatives=${SDOH_PRIVATE_DERIVATIVES_DIR:-$project_root/private-data/derived}
reference_dir="$project_root/private-data/reference"
python_lock="$project_root/code/context/requirements-lock.txt"
r_lock="$project_root/renv.lock"
r_library="$reference_dir/.r-library"
rscript_command=${SDOH_RSCRIPT:-Rscript}
public_test_python=${SDOH_PUBLIC_TEST_PYTHON:-python3}

if [[ ! -f "$source_data" ]]; then
  printf 'ERROR: the deidentified workbook was not found. On macOS, place QualtricsData_SDOH_DEIDENTIFIED.xlsx in ~/Downloads and run bash 2025_R03-SDOH/scripts/setup-macos.sh; it creates the protected folders and copies the file.\n' >&2
  exit 1
fi
if ! command -v "$public_test_python" >/dev/null 2>&1 && [[ ! -x "$public_test_python" ]]; then
  printf 'ERROR: Python is required. On macOS, run bash 2025_R03-SDOH/scripts/setup-macos.sh to install and configure a compatible Homebrew Python.\n' >&2
  exit 1
fi
if ! command -v "$rscript_command" >/dev/null 2>&1 && [[ ! -x "$rscript_command" ]]; then
  printf 'ERROR: Rscript is required. On macOS, run bash 2025_R03-SDOH/scripts/setup-macos.sh to install and locate reference R 4.5.2.\n' >&2
  exit 1
fi
active_r_version=$("$rscript_command" -e 'cat(as.character(getRversion()))' 2>/dev/null || true)
if [[ "$active_r_version" != "4.5.2" ]]; then
  printf 'ERROR: active R is %s; reference R 4.5.2 is required. On macOS, run bash 2025_R03-SDOH/scripts/setup-macos.sh.\n' "${active_r_version:-unknown}" >&2
  exit 1
fi
if [[ -n $(git -C "$repo_root" ls-files "2025_R03-SDOH/private-data") ]]; then
  printf 'ERROR: private-data contains tracked files. Stopping.\n' >&2
  exit 1
fi
if ! git -C "$repo_root" check-ignore -q "$source_data"; then
  printf 'ERROR: authoritative private workbook is not ignored by Git. Stopping.\n' >&2
  exit 1
fi

mkdir -p "$private_derivatives" "$reference_dir"
cache_log="$private_derivatives/.cache-events-current.tsv"
rm -f -- "$cache_log"
run_started=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
git_sha=$(git -C "$repo_root" rev-parse HEAD)
provenance="$private_derivatives/run-provenance.json"
provenance_part="$provenance.part"
printf '{\n  "status": "incomplete",\n  "started_utc": "%s",\n  "git_commit": "%s"\n}\n' "$run_started" "$git_sha" > "$provenance_part"
mv -f -- "$provenance_part" "$provenance"
trap 'printf "ERROR: private pipeline stopped before completion; run-provenance.json remains marked incomplete.\n" >&2' ERR

export SDOH_PROJECT_ROOT="$project_root"
export SDOH_SOURCE_DATA="$source_data"
export SDOH_PRIVATE_DERIVATIVES_DIR="$private_derivatives"
export SDOH_EXPECTED_N=709
export SDOH_CACHE_LOG="$cache_log"
export SDOH_PUBLIC_TEST_PYTHON="$public_test_python"

printf 'Running participant-free public contracts\n'
bash "$project_root/scripts/test-public-contracts.sh"
bash "$project_root/scripts/check-public-files.sh"

if [[ -n ${SDOH_CONTEXT_PYTHON:-} ]]; then
  python="$SDOH_CONTEXT_PYTHON"
  export SDOH_CUSTOM_PYTHON=1
  export SDOH_PYTHON_ENV_ACTION=custom-verified
  if [[ ! -x "$python" ]]; then
    printf 'ERROR: SDOH_CONTEXT_PYTHON is not executable.\n' >&2
    exit 1
  fi
  "$python" "$project_root/scripts/verify-python-dependencies.py" --lock "$python_lock"
else
  python="$reference_dir/.venv-context/bin/python"
  export SDOH_CUSTOM_PYTHON=
  if [[ ! -x "$python" ]]; then
    printf 'Creating isolated private Python environment\n'
    bootstrap_python=${SDOH_BOOTSTRAP_PYTHON:-}
    if [[ -z "$bootstrap_python" ]]; then
      for candidate in python3.12 python3.13 python3.14 /opt/homebrew/bin/python3 /usr/local/bin/python3 python3; do
        candidate_path=$(command -v "$candidate" 2>/dev/null || true)
        [[ -n "$candidate_path" ]] || continue
        if "$candidate_path" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,11) else 1)' 2>/dev/null; then
          bootstrap_python="$candidate_path"
          break
        fi
      done
    fi
    if [[ -z "$bootstrap_python" ]] || ! "$bootstrap_python" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,11) else 1)' 2>/dev/null; then
      printf 'ERROR: Python 3.11 or newer is required to create the pinned spatial environment. Set SDOH_BOOTSTRAP_PYTHON.\n' >&2
      exit 1
    fi
    "$bootstrap_python" -m venv "$reference_dir/.venv-context"
    export SDOH_PYTHON_ENV_ACTION=created
  else
    export SDOH_PYTHON_ENV_ACTION=reused
  fi
  if ! "$python" "$project_root/scripts/verify-python-dependencies.py" --lock "$python_lock"; then
    printf 'Installing or repairing exact Python dependencies\n'
    "$python" -m pip install --disable-pip-version-check --requirement "$python_lock"
    "$python" "$project_root/scripts/verify-python-dependencies.py" --lock "$python_lock"
    if [[ "$SDOH_PYTHON_ENV_ACTION" == reused ]]; then export SDOH_PYTHON_ENV_ACTION=repaired; fi
  fi
fi
export SDOH_CONTEXT_PYTHON="$python"

if [[ -d "$r_library" ]]; then export SDOH_R_ENV_ACTION=reused; else export SDOH_R_ENV_ACTION=created; fi
export R_LIBS_USER="$r_library:$reference_dir/.r-bootstrap"
printf 'Checking isolated private R environment\n'
"$rscript_command" "$project_root/scripts/bootstrap-r-dependencies.R" "$project_root" "$r_library" "$r_lock"

pipeline_scripts=(01_validate_source.R 02_score_core_measures.R)
for script in "${pipeline_scripts[@]}"; do
  printf 'Running %s\n' "$script"
  "$rscript_command" "$project_root/code/pipeline/$script"
done

context_scripts=(00_prepare_context_sources.R 01_validate_zip.R 02_zip_to_zcta.R 03_link_social_capital.R 04_link_deprivation.R 05_link_income_inequality.R 06_link_pm25.R 07_link_rurality.R 08_link_crime_disorder.R 09_build_context_master.R 10_validate_context.R)
for script in "${context_scripts[@]}"; do
  printf 'Running context/%s\n' "$script"
  "$rscript_command" "$project_root/code/context/$script"
done

pipeline_scripts=(03_build_analysis_master.R 04_validate_scores.R 05_rerun_prior_model_screen.R 06_grant_candidate_analyses.R 07_generate_figure_candidates.R 08_build_review_packet.R)
for script in "${pipeline_scripts[@]}"; do
  printf 'Running %s\n' "$script"
  "$rscript_command" "$project_root/code/pipeline/$script"
done

printf 'Verifying private reproduction contract\n'
"$rscript_command" "$project_root/scripts/verify-reproduction.R"
"$rscript_command" "$project_root/code/pipeline/09_write_run_provenance.R"
bash "$project_root/scripts/check-public-files.sh"
trap - ERR
printf 'Private pipeline complete. Open 2025_R03-SDOH/private-data/derived/melanie-review-packet.md first.\n'
