#!/usr/bin/env bash

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
project_root="$repo_root/2025_R03-SDOH"
default_source="$project_root/private-data/QualtricsData_SDOH_DEIDENTIFIED.xlsx"
source_data=${SDOH_SOURCE_DATA:-$default_source}
private_derivatives=${SDOH_PRIVATE_DERIVATIVES_DIR:-$project_root/private-data/derived}

if [[ ! -f "$source_data" ]]; then
  printf 'ERROR: authoritative private workbook not found. Set SDOH_SOURCE_DATA.\n' >&2
  exit 1
fi

if git -C "$repo_root" ls-files --error-unmatch "$source_data" >/dev/null 2>&1; then
  printf 'ERROR: private workbook is tracked by Git. Stopping.\n' >&2
  exit 1
fi

if ! git -C "$repo_root" check-ignore -q "$source_data"; then
  printf 'ERROR: private workbook is not ignored by Git. Stopping.\n' >&2
  exit 1
fi

if [[ -n $(git -C "$repo_root" ls-files "2025_R03-SDOH/private-data") ]]; then
  printf 'ERROR: private-data contains tracked files. Stopping.\n' >&2
  exit 1
fi

mkdir -p "$private_derivatives"
export SDOH_PROJECT_ROOT="$project_root"
export SDOH_SOURCE_DATA="$source_data"
export SDOH_PRIVATE_DERIVATIVES_DIR="$private_derivatives"
export SDOH_EXPECTED_N=709

pipeline_scripts=(01_validate_source.R 02_score_core_measures.R)
for script in "${pipeline_scripts[@]}"; do
  printf 'Running %s\n' "$script"
  Rscript "$project_root/code/pipeline/$script"
done

context_scripts=(00_prepare_context_sources.R 01_validate_zip.R 02_zip_to_zcta.R 03_link_social_capital.R 04_link_deprivation.R 05_link_income_inequality.R 06_link_pm25.R 07_link_rurality.R 08_link_crime_disorder.R 09_build_context_master.R 10_validate_context.R)
for script in "${context_scripts[@]}"; do
  printf 'Running context/%s\n' "$script"
  Rscript "$project_root/code/context/$script"
done

pipeline_scripts=(03_build_analysis_master.R 04_validate_scores.R 05_rerun_prior_model_screen.R 06_grant_candidate_analyses.R 07_generate_figure_candidates.R 08_build_review_packet.R)
for script in "${pipeline_scripts[@]}"; do
  printf 'Running %s\n' "$script"
  Rscript "$project_root/code/pipeline/$script"
done

bash "$project_root/scripts/check-public-files.sh"
printf 'Private pipeline complete. Open 2025_R03-SDOH/private-data/derived/melanie-review-packet.md first.\n'
