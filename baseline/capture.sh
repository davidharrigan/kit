#!/usr/bin/env bash
# capture.sh — capture a reviewable baseline of this Mac's current state, to
# later derive a nix-darwin / home-manager config from it.
#
# Re-runnable and idempotent: outputs are overwritten in place under
# baseline/<hostname -s>/. Never modifies system settings, never installs
# anything except `mas` via `brew install mas` if it's missing.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="$(hostname -s)"
OUT="$SCRIPT_DIR/$HOST"
DEFAULTS_DIR="$OUT/defaults"

mkdir -p "$OUT" "$DEFAULTS_DIR"

note() { echo "NOTE: $*"; }

have() { command -v "$1" >/dev/null 2>&1; }

# Run a command, redirecting stdout+stderr to $1. Never aborts the script;
# appends a NOTE line to the output file on nonzero exit.
run() {
  local out="$1"; shift
  if ! have "$1"; then
    echo "SKIPPED: '$1' not found on this system" > "$out"
    return
  fi
  # stderr goes to a sidecar file so lists (leaves, casks, taps) stay parseable
  if ! "$@" > "$out" 2> "$out.stderr"; then
    echo "" >> "$out"
    echo "NOTE: command exited non-zero: $*" >> "$out"
  fi
  [ -s "$out.stderr" ] || rm -f "$out.stderr"
}

# Like run(), but appends instead of overwriting (for building up a file from
# several commands) and does not skip-on-missing (caller already knows).
append() {
  local out="$1"; shift
  {
    echo "=== $* ==="
    if ! "$@" 2>&1; then
      echo "NOTE: command exited non-zero: $*"
    fi
    echo
  } >> "$out"
}

echo "==> Capturing baseline for host: $HOST"
echo "==> Output directory: $OUT"

########################################
# Homebrew
########################################
if have brew; then
  echo "-- Homebrew"
  # --describe is the default behavior in current brew; passing it explicitly errors.
  run "$OUT/Brewfile" brew bundle dump --file=-
  run "$OUT/brew-leaves.txt" brew leaves --installed-on-request
  run "$OUT/casks.txt" brew list --cask -1
  run "$OUT/taps.txt" brew tap
  : > "$OUT/brew-info.txt"
  append "$OUT/brew-info.txt" brew --prefix
  append "$OUT/brew-info.txt" brew --version
  append "$OUT/brew-info.txt" brew config
else
  note "brew not found; skipping all Homebrew captures"
  for f in Brewfile brew-leaves.txt casks.txt taps.txt brew-info.txt; do
    echo "SKIPPED: brew not found" > "$OUT/$f"
  done
fi

########################################
# App Store (mas)
########################################
echo "-- Mac App Store (mas)"
if ! have mas; then
  if have brew; then
    note "mas not found; installing via 'brew install mas' (explicitly allowed)"
    brew install mas || note "brew install mas failed"
  fi
fi
if have mas; then
  run "$OUT/mas.txt" mas list
else
  echo "SKIPPED: mas not available and could not be installed" > "$OUT/mas.txt"
fi

########################################
# Applications (/Applications, ~/Applications)
########################################
echo "-- Applications"
APPS_FILE="$OUT/applications.txt"
: > "$APPS_FILE"

app_dirs=("/Applications" "$HOME/Applications")
all_apps=()
for d in "${app_dirs[@]}"; do
  if [ -d "$d" ]; then
    while IFS= read -r -d '' app; do
      all_apps+=("$app")
    done < <(find "$d" -maxdepth 1 -name "*.app" -print0 2>/dev/null | sort -z)
  fi
done

bundle_id_of() {
  # $1 = path to .app
  local plist="$1/Contents/Info"
  defaults read "$plist" CFBundleIdentifier 2>/dev/null || echo "unknown"
}

echo "# All .app bundles found in: ${app_dirs[*]}" >> "$APPS_FILE"
echo "# Format: <bundle id>\t<path>" >> "$APPS_FILE"
apple_count=0
declare -a nonapple_apps=()
declare -a nonapple_bundle_ids=()
for app in "${all_apps[@]:-}"; do
  [ -z "$app" ] && continue
  bid="$(bundle_id_of "$app")"
  echo -e "${bid}\t${app}" >> "$APPS_FILE"
  if [[ "$bid" == com.apple.* ]]; then
    apple_count=$((apple_count + 1))
  else
    nonapple_apps+=("$app")
    nonapple_bundle_ids+=("$bid")
  fi
done
echo "" >> "$APPS_FILE"
echo "# Apple system apps (bundle id starting com.apple.): $apple_count" >> "$APPS_FILE"

# Determine cask coverage via installed cask artifacts (app names)
UNMANAGED_FILE="$OUT/applications-unmanaged.txt"
: > "$UNMANAGED_FILE"

declare -a cask_app_names=()
if have brew && have jq; then
  cask_json="$(brew info --cask --json=v2 --installed 2>/dev/null || echo '')"
  if [ -n "$cask_json" ]; then
    while IFS= read -r name; do
      [ -n "$name" ] && cask_app_names+=("$name")
    done < <(echo "$cask_json" | jq -r '.casks[]?.artifacts[]? | .app? // empty | if type=="array" then .[] else . end' 2>/dev/null | sed 's#/$##')
  fi
else
  note "brew and/or jq not available; cask-based app coverage will be incomplete" >> "$UNMANAGED_FILE"
fi

declare -a mas_app_names=()
if [ -f "$OUT/mas.txt" ] && ! grep -q "^SKIPPED" "$OUT/mas.txt"; then
  while IFS= read -r line; do
    # mas list format: "<id> <Name> (<version>)"
    name="$(echo "$line" | sed -E 's/^[0-9]+ +//; s/ \([0-9.]+\)$//')"
    [ -n "$name" ] && mas_app_names+=("$name")
  done < "$OUT/mas.txt"
fi

echo "# Non-Apple apps in /Applications and ~/Applications NOT covered by an" >> "$UNMANAGED_FILE"
echo "# installed brew cask or mas app (by app display name match)." >> "$UNMANAGED_FILE"
echo "" >> "$UNMANAGED_FILE"
unmanaged_count=0
for app in "${nonapple_apps[@]:-}"; do
  [ -z "$app" ] && continue
  base="$(basename "$app")"
  base_noext="${base%.app}"
  managed=0
  for c in "${cask_app_names[@]:-}"; do
    [ "$c" == "$base" ] && managed=1 && break
  done
  if [ "$managed" -eq 0 ]; then
    for m in "${mas_app_names[@]:-}"; do
      if [ "$m" == "$base_noext" ]; then
        managed=1
        break
      fi
    done
  fi
  if [ "$managed" -eq 0 ]; then
    echo "$app" >> "$UNMANAGED_FILE"
    unmanaged_count=$((unmanaged_count + 1))
  fi
done
echo "" >> "$UNMANAGED_FILE"
echo "# Total unmanaged: $unmanaged_count" >> "$UNMANAGED_FILE"

########################################
# macOS defaults
########################################
echo "-- macOS defaults"
domains=(
  NSGlobalDomain
  com.apple.dock
  com.apple.finder
  com.apple.AppleMultitouchTrackpad
  com.apple.driver.AppleBluetoothMultitouch.trackpad
  com.apple.screencapture
  com.apple.menuextra.clock
  com.apple.controlcenter
  com.apple.WindowManager
  com.apple.spaces
  com.apple.LaunchServices
  com.apple.HIToolbox
  com.apple.symbolichotkeys
  com.apple.universalaccess
  com.apple.loginwindow
  com.apple.screensaver
  com.apple.desktopservices
  com.apple.ActivityMonitor
  com.apple.TextEdit
  com.apple.Safari
  com.apple.SoftwareUpdate
  com.apple.AdLib
)
for domain in "${domains[@]}"; do
  run "$DEFAULTS_DIR/${domain}.plist.txt" defaults read "$domain"
done

run "$DEFAULTS_DIR/currentHost-NSGlobalDomain.txt" defaults -currentHost read -g

# sudo-free system-level reads (skip gracefully if not world-readable)
run "$DEFAULTS_DIR/library-com.apple.loginwindow.txt" defaults read /Library/Preferences/com.apple.loginwindow
run "$DEFAULTS_DIR/library-com.apple.PowerManagement.txt" defaults read /Library/Preferences/com.apple.PowerManagement

# Power settings
: > "$OUT/power.txt"
append "$OUT/power.txt" pmset -g custom
append "$OUT/power.txt" pmset -g
echo "# systemsetup skipped: requires sudo" >> "$OUT/power.txt"

########################################
# Shell
########################################
echo "-- Shell"
: > "$OUT/shell.txt"
{
  echo "=== \$SHELL ==="
  echo "${SHELL:-unset}"
  echo
} >> "$OUT/shell.txt"
append "$OUT/shell.txt" dscl . -read "/Users/$USER" UserShell
append "$OUT/shell.txt" cat /etc/shells

########################################
# Git
########################################
echo "-- Git"
run "$OUT/git.txt" git config --global --list --show-origin

########################################
# SSH (client) — never copy private key contents
########################################
echo "-- SSH"
SSH_FILE="$OUT/ssh.txt"
: > "$SSH_FILE"
if [ -d "$HOME/.ssh" ]; then
  {
    echo "=== ls -la ~/.ssh (names, perms, symlink targets only) ==="
    ls -la "$HOME/.ssh"
    echo
  } >> "$SSH_FILE" 2>&1 || note "could not list ~/.ssh" >> "$SSH_FILE"

  if [ -f "$HOME/.ssh/config" ]; then
    {
      echo "=== ~/.ssh/config ==="
      cat "$HOME/.ssh/config"
      echo
      echo "=== Include lines in ~/.ssh/config ==="
      grep -in '^[[:space:]]*Include' "$HOME/.ssh/config" || echo "(none found)"
      echo
    } >> "$SSH_FILE" 2>&1
  else
    echo "# No ~/.ssh/config present" >> "$SSH_FILE"
  fi

  echo "=== Public key fingerprints ===" >> "$SSH_FILE"
  if have ssh-keygen; then
    shopt -s nullglob
    pubs=("$HOME/.ssh"/*.pub)
    shopt -u nullglob
    if [ "${#pubs[@]}" -eq 0 ]; then
      echo "(no *.pub files found)" >> "$SSH_FILE"
    else
      for pub in "${pubs[@]}"; do
        ssh-keygen -lf "$pub" >> "$SSH_FILE" 2>&1 || echo "NOTE: could not fingerprint $pub" >> "$SSH_FILE"
      done
    fi
  else
    echo "SKIPPED: ssh-keygen not found" >> "$SSH_FILE"
  fi
else
  echo "# No ~/.ssh directory present" >> "$SSH_FILE"
fi

########################################
# Fonts
########################################
echo "-- Fonts"
FONTS_FILE="$OUT/fonts.txt"
: > "$FONTS_FILE"
append "$FONTS_FILE" ls -1 "$HOME/Library/Fonts"
append "$FONTS_FILE" ls -1 /Library/Fonts
{
  echo "=== font-* casks installed (brew) ==="
  if [ -f "$OUT/casks.txt" ] && ! grep -q "^SKIPPED" "$OUT/casks.txt"; then
    grep '^font-' "$OUT/casks.txt" || echo "(none)"
  else
    echo "SKIPPED: casks.txt unavailable"
  fi
  echo
} >> "$FONTS_FILE"

########################################
# Login items / launch agents & daemons
########################################
echo "-- Login items"
LOGIN_FILE="$OUT/login-items.txt"
: > "$LOGIN_FILE"

run_with_timeout() {
  # run_with_timeout <secs> <cmd...>  -> prints stdout+stderr, returns cmd's status (124 on timeout)
  local secs="$1"; shift
  local tmp
  tmp="$(mktemp)"
  "$@" > "$tmp" 2>&1 &
  local pid=$!
  (
    sleep "$secs"
    kill -9 "$pid" 2>/dev/null
  ) &
  local watcher=$!
  local status=0
  if wait "$pid" 2>/dev/null; then
    status=0
  else
    status=$?
  fi
  kill "$watcher" 2>/dev/null || true
  wait "$watcher" 2>/dev/null || true
  cat "$tmp"
  rm -f "$tmp"
  return "$status"
}

{
  echo "=== Login Items (osascript, 5s timeout; may prompt for permission) ==="
  if have osascript; then
    if ! run_with_timeout 5 osascript -e 'tell application "System Events" to get the name of every login item'; then
      echo "NOTE: osascript failed, timed out, or was denied permission — skipped"
    fi
  else
    echo "SKIPPED: osascript not found"
  fi
  echo
} >> "$LOGIN_FILE"

append "$LOGIN_FILE" ls -1 "$HOME/Library/LaunchAgents"
append "$LOGIN_FILE" ls -1 /Library/LaunchAgents
append "$LOGIN_FILE" ls -1 /Library/LaunchDaemons

########################################
# System info
########################################
echo "-- System"
SYS_FILE="$OUT/system.txt"
: > "$SYS_FILE"
append "$SYS_FILE" sw_vers
append "$SYS_FILE" uname -m
append "$SYS_FILE" scutil --get ComputerName
append "$SYS_FILE" scutil --get LocalHostName
append "$SYS_FILE" scutil --get HostName
append "$SYS_FILE" fdesetup status
append "$SYS_FILE" id
{
  echo "=== dscl . -list /Users UniqueID | awk '\$2>=500' ==="
  dscl . -list /Users UniqueID 2>/dev/null | awk '$2>=500' || echo "NOTE: command failed"
  echo
} >> "$SYS_FILE"
append "$SYS_FILE" groups

########################################
# /etc files nix-darwin commonly manages, and existing Nix state
########################################
echo "-- /etc and Nix state"
ETC_FILE="$OUT/etc.txt"
: > "$ETC_FILE"

etc_paths=(
  /etc/zshrc
  /etc/zprofile
  /etc/zshenv
  /etc/bashrc
  /etc/nix/nix.conf
  /etc/shells
  /etc/pam.d/sudo_local
)
{
  echo "=== Existence / symlink status ==="
  for p in "${etc_paths[@]}"; do
    if [ -L "$p" ]; then
      echo "$p -> symlink -> $(readlink "$p")"
    elif [ -e "$p" ]; then
      echo "$p -> regular file/dir"
    else
      echo "$p -> does not exist"
    fi
  done
  if compgen -G "/etc/ssh/sshd_config.d/*" > /dev/null 2>&1; then
    echo "/etc/ssh/sshd_config.d/* ->"
    for f in /etc/ssh/sshd_config.d/*; do
      if [ -L "$f" ]; then
        echo "  $f -> symlink -> $(readlink "$f")"
      else
        echo "  $f -> regular file"
      fi
    done
  else
    echo "/etc/ssh/sshd_config.d/* -> no files present"
  fi
  echo
} >> "$ETC_FILE"

{
  echo "=== /etc/pam.d/sudo_local contents ==="
  if [ -r /etc/pam.d/sudo_local ]; then
    cat /etc/pam.d/sudo_local
  else
    echo "NOTE: not present or not readable without sudo — skipped"
  fi
  echo
} >> "$ETC_FILE"

{
  echo "=== /etc/zshrc contents ==="
  if [ -r /etc/zshrc ]; then
    cat /etc/zshrc
  else
    echo "NOTE: not present or not readable — skipped"
  fi
  echo
} >> "$ETC_FILE"

{
  echo "=== Existing Nix install check ==="
  if [ -d /nix ]; then
    echo "/nix exists"
    ls -la /nix 2>/dev/null || true
  else
    echo "/nix does not exist"
  fi
  if have nix; then
    echo "nix found on PATH: $(command -v nix)"
  else
    echo "nix not found on PATH"
  fi
  if [ -f /etc/synthetic.conf ]; then
    echo "/etc/synthetic.conf exists:"
    cat /etc/synthetic.conf 2>/dev/null || echo "NOTE: not readable"
  else
    echo "/etc/synthetic.conf does not exist"
  fi
  echo
} >> "$ETC_FILE"

{
  echo "=== Remote login (sshd) status via launchctl (systemsetup needs sudo, skipped) ==="
  if have launchctl; then
    launchctl print system/com.openssh.sshd 2>&1 | head -n 20 || echo "NOTE: command failed"
  else
    echo "SKIPPED: launchctl not found"
  fi
  echo
} >> "$ETC_FILE"

echo "==> Done. Outputs written to: $OUT"
