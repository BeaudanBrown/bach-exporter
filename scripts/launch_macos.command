#!/usr/bin/env bash
set -euo pipefail

write_step() {
  printf '\n%s\n' "$1" >&2
}

pause_on_error() {
  local status="$1"
  if [[ "$status" -ne 0 ]]; then
    printf '\nBACH Exporter failed to launch.\n'
    printf 'Please copy the error above and send it to the study team.\n\n'
    read -r -p "Press Return to close..." _ || true
  fi
}

fail() {
  printf '%s\n' "$1" >&2
  pause_on_error 1
  exit 1
}

read_required_r_version() {
  local shared_root="$1"
  local lock_path="$shared_root/app/renv.lock"

  [[ -f "$lock_path" ]] || fail "Could not find app/renv.lock next to this launcher."

  local version
  version="$(awk '
    /"R"[[:space:]]*:/ { in_r = 1; next }
    in_r && /"Version"[[:space:]]*:/ {
      gsub(/.*"Version"[[:space:]]*:[[:space:]]*"/, "")
      gsub(/".*/, "")
      print
      exit
    }
  ' "$lock_path")"

  [[ -n "$version" ]] || fail "app/renv.lock does not declare an R version."
  printf '%s\n' "$version"
}

prepend_existing_path() {
  local path="$1"
  if [[ -d "$path" ]] && [[ ":$PATH:" != *":$path:"* ]]; then
    PATH="$path:$PATH"
  fi
}

update_process_path() {
  prepend_existing_path "/opt/homebrew/bin"
  prepend_existing_path "/usr/local/bin"
  prepend_existing_path "$HOME/.local/bin"
  export PATH
}

get_rig_command() {
  local rig
  if rig="$(command -v rig 2>/dev/null)"; then
    printf '%s\n' "$rig"
    return 0
  fi

  local candidate
  for candidate in \
    "/opt/homebrew/bin/rig" \
    "/usr/local/bin/rig" \
    "$HOME/.local/bin/rig"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

get_brew_command() {
  local brew
  if brew="$(command -v brew 2>/dev/null)"; then
    printf '%s\n' "$brew"
    return 0
  fi

  local candidate
  for candidate in "/opt/homebrew/bin/brew" "/usr/local/bin/brew"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

use_launcher_cache() {
  local cache_root="${BACH_EXPORTER_LOCAL_CACHE_DIR:-$HOME/Library/Caches/org.R-project.R/R/bachExporter}"
  local temp_root="$cache_root/tmp"

  mkdir -p "$cache_root" "$temp_root" || fail "Could not create the local BACH Exporter cache directory."

  export BACH_EXPORTER_LOCAL_CACHE_DIR="$cache_root"
  export TMPDIR="$temp_root"
  export TMP="$temp_root"
  export TEMP="$temp_root"

  printf '%s\n' "$cache_root"
}

install_rig_with_homebrew() {
  local brew
  brew="$(get_brew_command)" || return 1

  write_step "Installing rig with Homebrew..."
  "$brew" install rig >&2
  local status=$?
  update_process_path
  return "$status"
}

ensure_rig() {
  local rig
  if rig="$(get_rig_command)"; then
    printf '%s\n' "$rig"
    return 0
  fi

  if install_rig_with_homebrew; then
    sleep 1
    update_process_path
    if rig="$(get_rig_command)"; then
      printf '%s\n' "$rig"
      return 0
    fi
  fi

  fail "rig is required to install and launch the required R version.

Install rig from:
https://github.com/r-lib/rig/releases

If Homebrew just installed rig, close this window, open a new Terminal window,
and rerun this launcher. This launcher does not change your default R version."
}

get_r_minor_version() {
  local version="$1"
  awk -F. 'NF >= 2 { print $1 "." $2 }' <<<"$version"
}

find_compatible_r_version() {
  local required_minor="$1"
  awk -v minor="$required_minor" '
    $0 ~ "(^|[[:space:]])" minor "\\.[0-9]+($|[[:space:]])" {
      for (i = 1; i <= NF; i++) {
        if ($i ~ "^" minor "\\.[0-9]+$") {
          print $i
          exit
        }
      }
    }
  '
}

run_rig_capture() {
  local output_file="$1"
  local rig="$2"
  shift 2

  "$rig" "$@" >"$output_file" 2>&1
}

print_rig_output() {
  local output_file="$1"
  awk '$0 !~ /^\[INFO\]/ { print }' "$output_file" >&2
}

ensure_r_version() {
  local rig="$1"
  local required_r="$2"
  local required_minor
  required_minor="$(get_r_minor_version "$required_r")"
  [[ -n "$required_minor" ]] || fail "Required R version '$required_r' is not a major.minor.patch version."

  local output_file installed_version
  output_file="$(mktemp)" || fail "Could not create a temporary file for rig output."
  trap 'rm -f "$output_file"' RETURN

  write_step "Checking for R $required_minor.x..."
  if ! run_rig_capture "$output_file" "$rig" list; then
    print_rig_output "$output_file"
    fail "rig could not list installed R versions."
  fi
  print_rig_output "$output_file"

  installed_version="$(find_compatible_r_version "$required_minor" <"$output_file")"
  if [[ -n "$installed_version" ]]; then
    printf '%s\n' "$installed_version"
    return 0
  fi

  write_step "Installing R $required_minor.x with rig..."
  if ! run_rig_capture "$output_file" "$rig" add "$required_minor"; then
    print_rig_output "$output_file"
    fail "rig failed to install R $required_minor.x."
  fi
  print_rig_output "$output_file"

  if ! run_rig_capture "$output_file" "$rig" list; then
    print_rig_output "$output_file"
    fail "rig could not list installed R versions after installing R."
  fi

  installed_version="$(find_compatible_r_version "$required_minor" <"$output_file")"
  [[ -n "$installed_version" ]] || fail "rig installed R, but no R $required_minor.x installation was detected."

  printf '%s\n' "$installed_version"
}

update_process_path
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)" || fail "Could not resolve launcher directory."
SHARED_ROOT="$SCRIPT_DIR"
LAUNCHER="$SHARED_ROOT/launcher/launch_bach_exporter.R"

[[ -f "$LAUNCHER" ]] || fail "Could not find launcher/launch_bach_exporter.R next to this launcher."

REQUIRED_R="$(read_required_r_version "$SHARED_ROOT")" || exit $?
RIG="$(ensure_rig)" || exit $?
RUN_R="$(ensure_r_version "$RIG" "$REQUIRED_R")" || exit $?
CACHE_ROOT="$(use_launcher_cache)" || exit $?

write_step "Launching BACH Exporter with R $RUN_R..."
printf 'Shared root: %s\n' "$SHARED_ROOT"
printf 'Launcher: %s\n' "$LAUNCHER"
printf 'Local cache: %s\n' "$CACHE_ROOT"

set +e
BACH_EXPORTER_LAUNCHER="$LAUNCHER" "$RIG" run --r-version "$RUN_R" -f "$LAUNCHER"
RUN_STATUS=$?
set -e
if [[ "$RUN_STATUS" -ne 0 ]]; then
  printf '\nrig/R exited with status %s.\n' "$RUN_STATUS"
  pause_on_error "$RUN_STATUS"
fi
exit "$RUN_STATUS"
