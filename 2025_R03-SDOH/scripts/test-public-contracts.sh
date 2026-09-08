#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
python_command=${SDOH_PUBLIC_TEST_PYTHON:-python3}
if ! command -v "$python_command" >/dev/null 2>&1 && [[ ! -x "$python_command" ]]; then
  printf 'ERROR: Python is required for the public contract tests. On macOS, run bash 2025_R03-SDOH/scripts/setup-macos.sh.\n' >&2
  exit 1
fi
bash -n "$script_dir/setup-macos.sh"
bash -n "$script_dir/run-private-pipeline.sh"
"$python_command" "$script_dir/test-public-contracts.py"
