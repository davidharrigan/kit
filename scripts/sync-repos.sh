#!/usr/bin/env bash

# Set up each repo in repos.yaml for the Hermes agent: clone it, create its
# kanban board with the repo as default workdir, and bind a project to the board
# so each card gets a worktree at <workdir>/.worktrees/<card>.
# Run as david on the host with the agent user. Safe to re-run; each step skips
# what's already done.

set -euo pipefail

REPOS_FILE="${1:-$(dirname "$0")/../repos.yaml}"
AGENT_HOME="/Users/agent"

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

# sudo resets PATH; keep david's tools and put agent's hermes first.
as_agent() {
  sudo -u agent -H env PATH="/etc/profiles/per-user/agent/bin:$PATH" "$@"
}

id agent &>/dev/null || error "no agent user on this host"
[ -f "$REPOS_FILE" ] || error "$REPOS_FILE not found"

yq -r '.repos[] | [.name, .repo, .workdir // "$HOME/src/" + .name] | @tsv' "$REPOS_FILE" |
  while IFS=$'\t' read -r name repo workdir; do
    workdir=${workdir/#\$HOME/$AGENT_HOME}
    workdir=${workdir/#\~/$AGENT_HOME}
    url="git@${repo%%/*}:${repo#*/}.git"
    info "$name ($url -> $workdir)"

    if as_agent test -d "$workdir/.git"; then
      echo "  already cloned"
    else
      as_agent git clone "$url" "$workdir" </dev/null
    fi

    as_agent hermes kanban boards create "$name" </dev/null
    as_agent hermes kanban boards set-default-workdir "$name" "$workdir" </dev/null

    if as_agent hermes project show "$name" &>/dev/null </dev/null; then
      as_agent hermes project bind-board "$name" "$name" </dev/null
    else
      as_agent hermes project create "$name" "$workdir" --slug "$name" --board "$name" </dev/null
    fi

    success "  $name ready"
  done
