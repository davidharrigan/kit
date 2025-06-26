#!/usr/bin/env bash

set -e

ROOT=$(cd "$(dirname $0)" && pwd)

STOW_DIR="./dots"
BACKUP_DIR="$ROOT/backup"
THIS_BACKUP=$BACKUP_DIR/backup-$(date +%F-%T)

# Color/format codes
RED=31
GREEN=32
BLUE=34
YELLOW=33
BOLD=1
RESET=0

INDENT="  "

color_code() {
  [ $# -gt 0 ] || return
  IFS=";" printf "\033[%sm" $*
}

reset_line() {
  printf "\r\033[K" # move cursor to beginning of line and clear it
}

info() {
  echo -e "$(color_code $BOLD $BLUE)$1$(color_code $RESET)"
}

success() {
  echo -e "$(color_code $BOLD $GREEN)$1$(color_code $RESET)"
}

error() {
  echo -e "$(color_code $BOLD $RED)❌ Error: $1$(color_code $RESET)" >&2
  exit 1
}

pushd() {
  command pushd "$@" >/dev/null
}

popd() {
  command popd "$@" >/dev/null
}

check_deps() {
  if ! command -v stow &>/dev/null; then
    error "stow is not installed."
  fi
}

backup_conflicts() {
  info "Checking for conflicts..."

  # Create backup directory
  mkdir -p "$THIS_BACKUP"

  local conflicts=$(stow -n -v -t "$HOME" . 2>&1 | grep "existing target is" || true)

  if [ -n "$conflicts" ]; then
    echo "$conflicts" | while read -r line; do
      # Extract the target path from the line
      local target=$(echo "$line" | sed -n 's/.*: *\(.*\)/\1/p')

      if [ ! -n "$target" ]; then
        continue
      fi

      local full_target="$HOME/$target"
      if [ -L "$full_target" ]; then
        printf "$INDENT $full_target (symlink, deleting)"
        rm $full_target
        printf "$(reset_line)✅ deleted symlink: $full_target\n"
      elif [ -e "$full_target" ]; then
        local backup_target="$THIS_BACKUP/${target#HOME/}"
        local backup_dir=$(dirname "$backup_target")
        printf "$full_target (conflict, backing up)"
        mkdir -p "$backup_dir"
        cp -r "$full_target" "$backup_target"
        rm -rf "$full_target"
        printf "$(reset_line)✅ backed up conflict: $full_target\n"
      fi
    done
  fi

  if [ -d "$THIS_BACKUP" ] && [ "$(ls -A "$THIS_BACKUP" 2>/dev/null)" ]; then
    success "Backup saved to: $THIS_BACKUP"
  else
    success "No conflicts found"
    rmdir "$THIS_BACKUP" 2>/dev/null || true
  fi
}

install_dotfiles() {
  info "Installing dotfiles..."
  stow -t ~/ .
  success "Dotfiles installed successfully!"
}

remove_dotfiles() {
  info "Removing dotfiles..."

  stow -D -t "$HOME" .
  success "Dotfiles uninstalled successfully!"
}

# Parse command line arguments
REMOVE=false

while [[ $# -gt 0 ]]; do
  case $1 in
  -D | --delete)
    REMOVE=true
    shift
    ;;
  -h | --help)
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -D, --delete     Remove dotfiles"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Files in dotfiles/dotfiles/ will be symlinked to ~/"
    exit 0
    ;;
  *)
    error "Unknown option: $1. Use -h for help."
    ;;
  esac
done

# Check dependencies
check_deps

pushd "$STOW_DIR" || error "Failed to change directory to $STOW_DIR"

# Remove
if [ "$REMOVE" = true ]; then
  remove_dotfiles
  exit 0
fi

# Install dotfiles
backup_conflicts
echo
install_dotfiles

echo
echo "Your dotfiles are now managed by stow!"
echo "Use '$0 -D' to remove them."
