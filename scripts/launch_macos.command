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

is_r_lib_rig() {
  local candidate="$1"
  [[ -x "$candidate" ]] || return 1
  "$candidate" list >/dev/null 2>&1
}

get_rig_command() {
  local rig
  if rig="$(command -v rig 2>/dev/null)" && is_r_lib_rig "$rig"; then
    printf '%s\n' "$rig"
    return 0
  fi

  local candidate
  for candidate in \
    "/opt/homebrew/bin/rig" \
    "/usr/local/bin/rig" \
    "$HOME/.local/bin/rig"; do
    if is_r_lib_rig "$candidate"; then
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

  write_step "Installing r-lib rig with Homebrew..."
  "$brew" tap r-lib/rig >&2
  "$brew" install --cask rig >&2
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

Install r-lib rig from:
https://github.com/r-lib/rig/releases

If Homebrew installed the unrelated identity-generator rig formula, remove it with:
brew uninstall rig
brew tap r-lib/rig
brew install --cask rig

Then close this window, open a new Terminal window, and rerun this launcher.
This launcher does not change your default R version."
}

append_env_path() {
  local env_name="$1"
  local path="$2"
  local current="${!env_name:-}"

  [[ -d "$path" ]] || return 1
  if [[ -z "$current" ]]; then
    export "$env_name=$path"
  elif [[ ":$current:" != *":$path:"* ]]; then
    export "$env_name=$path:$current"
  fi
}

configure_gettext_build_env() {
  local prefix="$1"

  [[ -d "$prefix" ]] || return 1
  append_env_path PATH "$prefix/bin" || true
  append_env_path PKG_CONFIG_PATH "$prefix/lib/pkgconfig" || true
  export BACH_EXPORTER_GETTEXT_PREFIX="$prefix"
  export CPPFLAGS="-I$prefix/include ${CPPFLAGS:-}"
  export LDFLAGS="-L$prefix/lib ${LDFLAGS:-}"
  export PKG_CPPFLAGS="-I$prefix/include ${PKG_CPPFLAGS:-}"
  export PKG_LIBS="-L$prefix/lib -lintl ${PKG_LIBS:-}"
  export PATH
  write_step "Configured gettext for R package builds: $prefix"
  return 0
}

find_gettext_prefix() {
  local brew prefix
  if brew="$(get_brew_command)"; then
    prefix="$($brew --prefix gettext 2>/dev/null || true)"
    if [[ -n "$prefix" && -d "$prefix" ]]; then
      printf '%s\n' "$prefix"
      return 0
    fi
  fi

  for prefix in "/opt/homebrew/opt/gettext" "/usr/local/opt/gettext"; do
    if [[ -d "$prefix" ]]; then
      printf '%s\n' "$prefix"
      return 0
    fi
  done

  return 1
}

ensure_gettext() {
  local prefix brew
  if prefix="$(find_gettext_prefix)"; then
    configure_gettext_build_env "$prefix"
    return 0
  fi

  brew="$(get_brew_command)" || fail "Homebrew is required to install gettext, needed if R packages compile from source. Install Homebrew or ask IT to install gettext."
  write_step "Installing gettext with Homebrew for R package builds..."
  "$brew" install gettext >&2

  prefix="$(find_gettext_prefix)" || fail "Homebrew installed gettext, but its install prefix could not be found."
  configure_gettext_build_env "$prefix"
}

ensure_homebrew_package() {
  local package="$1"
  local description="$2"
  local brew

  command -v "$package" >/dev/null 2>&1 && return 0
  brew="$(get_brew_command)" || fail "Homebrew is required to install $description. Install Homebrew or ask IT to install $package."

  write_step "Installing $description with Homebrew..."
  "$brew" install "$package" >&2
  update_process_path
}

write_r_makevars() {
  local cache_root="$1"
  local gettext_prefix="${BACH_EXPORTER_GETTEXT_PREFIX:-}"
  local makevars_dir="$cache_root/r-build"
  local makevars_path="$makevars_dir/Makevars"

  [[ -n "$gettext_prefix" && -d "$gettext_prefix" ]] || return 0
  mkdir -p "$makevars_dir" || fail "Could not create R build configuration directory."
  cat >"$makevars_path" <<EOF
CPPFLAGS += -I$gettext_prefix/include
LDFLAGS += -L$gettext_prefix/lib
PKG_CPPFLAGS += -I$gettext_prefix/include
PKG_LIBS += -L$gettext_prefix/lib -lintl
EOF
  export R_MAKEVARS_USER="$makevars_path"
  write_step "Configured R Makevars for source package builds: $makevars_path"
}

ensure_xcode_command_line_tools() {
  if xcrun --find clang >/dev/null 2>&1; then
    return 0
  fi

  write_step "Installing Apple Command Line Tools for R package builds..."
  xcode-select --install >/dev/null 2>&1 || true
  fail "Apple Command Line Tools are required if R packages compile from source. Complete the installer that just opened, then rerun this launcher."
}

ensure_macos_build_requirements() {
  local cache_root="$1"

  ensure_gettext
  write_r_makevars "$cache_root"
  ensure_homebrew_package cmake "CMake for R package builds"
  ensure_xcode_command_line_tools
}

get_r_minor_version() {
  local version="$1"
  awk -F. 'NF >= 2 { print $1 "." $2 }' <<<"$version"
}

find_compatible_r_version() {
  local required_minor="$1"
  awk -v minor="$required_minor" '
    {
      for (i = 1; i <= NF; i++) {
        if ($i ~ "^" minor "\\.[0-9]+$") {
          print $i
          exit
        }
        if ($i ~ "^" minor "-(arm64|x86_64|x86_64-arm64|arm64-x86_64)$") {
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

run_rig_visible_capture() {
  local output_file="$1"
  local rig="$2"
  shift 2

  set +e
  "$rig" "$@" 2>&1 | tee "$output_file" >&2
  local status=${PIPESTATUS[0]}
  set -e
  return "$status"
}

run_sudo_rig_visible_capture() {
  local output_file="$1"
  local rig="$2"
  shift 2

  command -v sudo >/dev/null 2>&1 || return 1
  write_step "Requesting administrator permission for the R installation..."
  sudo -v || return 1

  set +e
  sudo "$rig" "$@" 2>&1 | tee "$output_file" >&2
  local status=${PIPESTATUS[0]}
  set -e
  return "$status"
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
  if ! run_rig_visible_capture "$output_file" "$rig" add "$required_minor"; then
    write_step "Retrying R $required_minor.x installation with sudo rig..."
    if ! run_sudo_rig_visible_capture "$output_file" "$rig" add "$required_minor"; then
      fail "rig failed to install R $required_minor.x, even when retried with sudo."
    fi
  fi

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
ensure_macos_build_requirements "$CACHE_ROOT"

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
