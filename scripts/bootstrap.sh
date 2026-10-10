#!/usr/bin/env bash

# Post-apply setup nix-darwin can't declare: Oh My Zsh for david and agent, and
# on hosts with the agent user its password, Screen Sharing and FileVault.
# Run as david after the first `just apply`. Safe to re-run; each step skips
# what's already done. -i/--interactive also offers to set agent's password.

set -euo pipefail

INTERACTIVE=false
case "${1:-}" in
  -i | --interactive) INTERACTIVE=true ;;
  "") ;;
  *) echo "usage: $0 [-i|--interactive]" >&2; exit 2 ;;
esac

OMZ_INSTALL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

BLUE=34
GREEN=32
RED=31
BOLD=1
RESET=0

color_code() {
  [ $# -gt 0 ] || return
  IFS=";" printf "\033[%sm" $*
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

as_agent() {
  sudo -u agent -H "$@"
}

need_apply=false

# install_omz <runner...>: install Oh My Zsh into ~/.oh-my-zsh. The apply has
# already linked the theme into ~/.oh-my-zsh/custom, which makes the installer
# refuse to run, so a partial install is removed and the apply rerun after.
install_omz() {
  if "$@" sh -c 'test -f ~/.oh-my-zsh/oh-my-zsh.sh'; then
    success "omz: already installed"
    return
  fi
  info "omz: installing"
  "$@" sh -c "rm -rf ~/.oh-my-zsh && sh -c \"\$(curl -fsSL $OMZ_INSTALL)\" \"\" --unattended --keep-zshrc"
  need_apply=true
}

info "== david =="

install_omz

if id agent &>/dev/null; then
  info "== agent =="

  install_omz as_agent

  answer=n
  $INTERACTIVE && read -r -p "Set agent's login password? [y/N] " answer
  if [[ $answer =~ ^[Yy]$ ]]; then
    read -r -s -p "Password: " password
    echo
    sudo dscl . -passwd /Users/agent "$password"
    unset password
    success "agent: password set"
  else
    success "agent: password unchanged (set it with -i)"
  fi

  if launchctl print-disabled system | grep -q '"com.apple.screensharing" => enabled'; then
    success "screen sharing: already on"
  else
    info "screen sharing: enabling"
    sudo launchctl enable system/com.apple.screensharing
    sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true
  fi

  if fdesetup status | grep -q "FileVault is On"; then
    success "filevault: already on"
  else
    info "filevault: enabling (save the recovery key it prints)"
    sudo fdesetup enable
  fi
fi

if $need_apply; then
  info "Reapplying to restore the Oh My Zsh theme link"
  just apply
fi

success "Done."
