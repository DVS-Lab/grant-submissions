#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
project_root=$(cd "$script_dir/.." && pwd)
repo_root=$(cd "$project_root/.." && pwd)

expected_workbook_name="QualtricsData_SDOH_DEIDENTIFIED.xlsx"
destination_workbook="$project_root/private-data/$expected_workbook_name"
reference_r_version="4.5.2"
run_pipeline=1
workbook_source=""
brew_command=""

usage() {
  cat <<'EOF'
Prepare and run the private SDOH pipeline on macOS.

Usage:
  bash 2025_R03-SDOH/scripts/setup-macos.sh [WORKBOOK]
  bash 2025_R03-SDOH/scripts/setup-macos.sh --source WORKBOOK
  bash 2025_R03-SDOH/scripts/setup-macos.sh --prepare-only [WORKBOOK]

If WORKBOOK is omitted, the script looks for:
  ~/Downloads/QualtricsData_SDOH_DEIDENTIFIED.xlsx

The workbook must have exactly that filename. The script creates the private-data
folders, copies the workbook without overwriting a different existing copy,
checks privacy protections, installs the reference R runtime and a compatible
Python through Homebrew when necessary, restores pinned project dependencies,
and runs the pipeline. Use --prepare-only to stop before running the pipeline.
EOF
}

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

command_path() {
  local candidate=$1
  if [[ -x "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi
  command -v "$candidate" 2>/dev/null
}

r_version_for() {
  local candidate=$1
  "$candidate" -e 'cat(as.character(getRversion()))' 2>/dev/null
}

find_reference_rscript() {
  local candidate candidate_path candidate_version
  for candidate in \
    "${SDOH_RSCRIPT:-}" \
    Rscript \
    /Library/Frameworks/R.framework/Versions/*/Resources/bin/Rscript \
    "$HOME"/.local/share/rig/r/*/Resources/bin/Rscript \
    "$HOME"/.local/share/rig/r/*/bin/Rscript \
    /usr/local/bin/Rscript-* \
    /opt/homebrew/bin/Rscript-*; do
    [[ -n "$candidate" ]] || continue
    candidate_path=$(command_path "$candidate" || true)
    [[ -n "$candidate_path" ]] || continue
    candidate_version=$(r_version_for "$candidate_path" || true)
    if [[ "$candidate_version" == "$reference_r_version" ]]; then
      printf '%s\n' "$candidate_path"
      return 0
    fi
  done
  return 1
}

find_brew() {
  local candidate
  for candidate in brew /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if command_path "$candidate" >/dev/null 2>&1; then
      command_path "$candidate"
      return 0
    fi
  done
  return 1
}

show_homebrew_instructions() {
  cat >&2 <<EOF

Homebrew is needed to install missing system dependencies. Complete these steps:

  1. Open Terminal.
  2. Install Apple's command-line tools if prompted:
       xcode-select --install
  3. Install Homebrew with its official installer:
       /bin/bash -c "\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  4. If Homebrew prints a command under "Next steps", run that command. On most
     Apple-silicon Macs it is:
       eval "\$(/opt/homebrew/bin/brew shellenv)"
  5. Return to the repository and rerun:
       bash 2025_R03-SDOH/scripts/setup-macos.sh

Homebrew instructions: https://docs.brew.sh/Installation
EOF
}

require_brew() {
  if [[ -z "$brew_command" ]]; then
    brew_command=$(find_brew || true)
  fi
  if [[ -z "$brew_command" ]]; then
    show_homebrew_instructions
    fail "Homebrew is not installed or is not on PATH."
  fi
}

show_r_instructions() {
  cat >&2 <<EOF

To finish the exact R setup manually, run these commands in Terminal:

  xcode-select --install
  brew update
  brew install r-rig
  rig add $reference_r_version
  rig list
  bash 2025_R03-SDOH/scripts/setup-macos.sh

If the first command says the tools are already installed, continue to the next
command. The setup script discovers R by its reported version and does not
depend on rig's platform-specific name or the shell's default R. Exact-version
R installer documentation: https://github.com/r-lib/rig
EOF
}

show_python_instructions() {
  cat >&2 <<'EOF'

To finish Python setup manually, run these commands in Terminal:

  xcode-select --install
  brew update
  brew install python@3.12
  bash 2025_R03-SDOH/scripts/setup-macos.sh

If the first command says the tools are already installed, continue to the next
command.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --prepare-only)
      run_pipeline=0
      shift
      ;;
    --source)
      [[ $# -ge 2 ]] || fail "--source requires a workbook path."
      workbook_source=$2
      shift 2
      ;;
    --*)
      fail "Unknown option: $1. Run with --help for usage."
      ;;
    *)
      [[ -z "$workbook_source" ]] || fail "Provide only one workbook path."
      workbook_source=$1
      shift
      ;;
  esac
done

[[ "$(uname -s)" == "Darwin" ]] || fail "This helper is for macOS. See docs/reproducibility.md for other systems."

mkdir -p \
  "$project_root/private-data/derived" \
  "$project_root/private-data/reference"

if [[ -z "$workbook_source" ]]; then
  if [[ -f "$destination_workbook" ]]; then
    workbook_source=$destination_workbook
  elif [[ -f "$HOME/Downloads/$expected_workbook_name" ]]; then
    workbook_source="$HOME/Downloads/$expected_workbook_name"
  else
    cat >&2 <<EOF
The private-data folders now exist, but the input workbook was not found.

Download the deidentified workbook to:
  $HOME/Downloads/$expected_workbook_name

Then rerun:
  bash 2025_R03-SDOH/scripts/setup-macos.sh

Or provide its exact location:
  bash 2025_R03-SDOH/scripts/setup-macos.sh --source "/path/to/$expected_workbook_name"
EOF
    fail "Missing $expected_workbook_name."
  fi
fi

[[ -f "$workbook_source" ]] || fail "Workbook not found: $workbook_source"
[[ "$(basename "$workbook_source")" == "$expected_workbook_name" ]] || fail \
  "The workbook must be named exactly $expected_workbook_name; refusing a differently named export."

if [[ -e "$destination_workbook" && "$workbook_source" -ef "$destination_workbook" ]]; then
  printf 'Using existing private workbook: %s\n' "$destination_workbook"
elif [[ -e "$destination_workbook" ]]; then
  if cmp -s "$workbook_source" "$destination_workbook"; then
    printf 'The downloaded workbook matches the existing private copy.\n'
  else
    fail "A different workbook already exists at $destination_workbook. Move or rename it after confirming which copy is correct; this script will not overwrite it."
  fi
else
  cp -p "$workbook_source" "$destination_workbook"
  printf 'Copied the private workbook into the protected project folder.\n'
fi
chmod 600 "$destination_workbook"

if git -C "$repo_root" ls-files --error-unmatch \
  "2025_R03-SDOH/private-data/$expected_workbook_name" >/dev/null 2>&1; then
  fail "The private workbook is tracked by Git. Remove it from Git before continuing."
fi
git -C "$repo_root" check-ignore -q \
  "2025_R03-SDOH/private-data/$expected_workbook_name" || fail \
  "The private workbook is not protected by a Git ignore rule."

rscript_command=$(find_reference_rscript || true)
installed_r_version=""
if [[ -n "$rscript_command" ]]; then installed_r_version=$(r_version_for "$rscript_command"); fi

if [[ "$installed_r_version" != "$reference_r_version" ]]; then
  active_rscript=$(command_path "${SDOH_RSCRIPT:-Rscript}" || true)
  active_r_version=""
  if [[ -n "$active_rscript" ]]; then active_r_version=$(r_version_for "$active_rscript" || true); fi
  if [[ -z "$active_r_version" ]]; then
    printf 'R is not installed; installing reference R %s.\n' "$reference_r_version"
  else
    printf 'Found R %s; installing reference R %s alongside it.\n' \
      "$active_r_version" "$reference_r_version"
  fi
  require_brew

  rig_command=$(command_path rig || true)
  if [[ -z "$rig_command" ]]; then
    if ! "$brew_command" install r-rig; then
      show_r_instructions
      fail "Homebrew could not install the r-rig exact-R manager."
    fi
    rig_command=$(command_path rig || true)
    if [[ -z "$rig_command" ]]; then
      rig_prefix=$($brew_command --prefix r-rig)
      rig_command=$(command_path "$rig_prefix/bin/rig" || true)
    fi
  fi
  [[ -n "$rig_command" ]] || fail "Homebrew installed r-rig, but the rig command could not be found."

  rig_add_status=0
  "$rig_command" add "$reference_r_version" || rig_add_status=$?
  hash -r
  rscript_command=$(find_reference_rscript || true)
  installed_r_version=""
  if [[ -n "$rscript_command" ]]; then installed_r_version=$(r_version_for "$rscript_command"); fi
  if [[ "$installed_r_version" != "$reference_r_version" && "$rig_add_status" -ne 0 ]]; then
    printf 'rig add exited with status %s.\n' "$rig_add_status" >&2
  fi
fi

if [[ "$installed_r_version" != "$reference_r_version" ]]; then
  show_r_instructions
  fail "R $reference_r_version is required; active version is ${installed_r_version:-unavailable}."
fi
printf 'R dependency ready: %s (%s)\n' "$rscript_command" "$installed_r_version"

python_command=""
python_candidates=()
if [[ -n "${SDOH_BOOTSTRAP_PYTHON:-}" ]]; then
  python_candidates+=("$SDOH_BOOTSTRAP_PYTHON")
fi
python_candidates+=(python3.12 python3.13 python3.14 python3)

for candidate in "${python_candidates[@]}"; do
  candidate_path=$(command_path "$candidate" || true)
  [[ -n "$candidate_path" ]] || continue
  if "$candidate_path" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 11) else 1)' >/dev/null 2>&1; then
    python_command=$candidate_path
    break
  fi
done

if [[ -z "$python_command" ]]; then
  printf 'Python 3.11 or newer is not installed; installing Python 3.12.\n'
  require_brew
  if ! "$brew_command" install python@3.12; then
    show_python_instructions
    fail "Homebrew could not install Python 3.12."
  fi
  python_prefix=$($brew_command --prefix python@3.12)
  python_command="$python_prefix/bin/python3.12"
fi

[[ -x "$python_command" ]] || fail "A compatible Python interpreter could not be found."
"$python_command" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 11) else 1)' || fail \
  "Python 3.11 or newer is required."
"$python_command" -m venv --help >/dev/null || fail "Python's venv module is required."
printf 'Python dependency ready: %s (%s)\n' \
  "$python_command" "$($python_command -c 'import platform; print(platform.python_version())')"

export SDOH_RSCRIPT="$rscript_command"
export SDOH_BOOTSTRAP_PYTHON="$python_command"
export SDOH_PUBLIC_TEST_PYTHON="$python_command"

if [[ "$run_pipeline" -eq 0 ]]; then
  cat <<EOF

Mac setup is ready. To run the complete pipeline later:
  bash 2025_R03-SDOH/scripts/setup-macos.sh
EOF
  exit 0
fi

printf '\nRunning the complete private pipeline...\n'
bash "$script_dir/run-private-pipeline.sh"
