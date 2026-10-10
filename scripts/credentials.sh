#!/usr/bin/env bash

# Post-install credentials: gh sign-in and GitHub SSH keys for david and agent,
# plus a 1Password service account that gives agent read access to the agent vault.
# Run as david. Safe to re-run; each step skips what's already done, so it only
# asks for input it needs. -i/--interactive also offers to redo done steps.

set -euo pipefail

INTERACTIVE=false
case "${1:-}" in
  -i | --interactive) INTERACTIVE=true ;;
  "") ;;
  *) echo "usage: $0 [-i|--interactive]" >&2; exit 2 ;;
esac

DAVID_LOGIN="davidharrigan"
AGENT_LOGIN="takohoncho"
AGENT_VAULT="agent"
# david's personal vault (named Private or Personal depending on the account).
PRIVATE_VAULT="${PRIVATE_VAULT:-Private}"
SA_ITEM="agent service account"
SA_TOKEN_FILE=".config/op/service-account-token"
SCOPES="admin:public_key"
HOST=$(hostname -s)

# sudo resets PATH, so call the tools by absolute path when acting as agent.
GH=$(command -v gh)
OP=$(command -v op)

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

# confirm <question>: with -i, ask; otherwise no.
confirm() {
  $INTERACTIVE || return 1
  local answer
  read -r -p "$1 [y/N] " answer
  [[ $answer =~ ^[Yy]$ ]]
}

# gh_login <login> <runner...>: sign in to github.com (device flow) as <login>
# with the scope needed to upload SSH keys. <runner> is empty for david.
gh_login() {
  local login=$1
  shift
  local storage=()
  [ $# -gt 0 ] && storage=(--insecure-storage)

  if "$@" "$GH" auth status -h github.com &>/dev/null && ! confirm "gh: sign in again as $login?"; then
    success "gh: already signed in"
  else
    info "gh: sign in as $login (complete the device code in a browser signed in as $login)"
    "$@" "$GH" auth login -h github.com -p ssh -w --skip-ssh-key ${storage[@]+"${storage[@]}"} -s "$SCOPES"
  fi

  if ! "$@" "$GH" auth status -h github.com 2>&1 | grep -q "$SCOPES"; then
    info "gh: adding $SCOPES scope"
    "$@" "$GH" auth refresh -h github.com ${storage[@]+"${storage[@]}"} -s "$SCOPES"
  fi

  local actual
  actual=$("$@" "$GH" api user -q .login)
  [ "$actual" = "$login" ] || error "gh is signed in as $actual, expected $login"
}

# gh_ssh_key <user> <home> <runner...>: upload <home>/.ssh/id_ed25519.pub if GitHub lacks it.
gh_ssh_key() {
  local user=$1 home=$2
  shift 2
  local pub="$home/.ssh/id_ed25519.pub"

  if ! "$@" test -r "$pub"; then
    info "ssh: no $pub, skipping"
    return
  fi

  local key
  key=$("$@" cut -d' ' -f1,2 "$pub")
  if "$@" "$GH" api user/keys -q '.[].key' | grep -qxF "$key"; then
    success "ssh: key already on GitHub"
  else
    info "ssh: adding $pub to GitHub"
    "$@" "$GH" ssh-key add "$pub" -t "$user@$HOST"
  fi
}

info "== david =="

gh_login "$DAVID_LOGIN"
gh_ssh_key david "$HOME"

if ! id agent &>/dev/null; then
  success "No agent user; done."
  exit 0
fi

info "== agent =="

# 1Password is only needed when agent's service account token is missing or broken.
if as_agent sh -c "OP_SERVICE_ACCOUNT_TOKEN=\$(cat ~/$SA_TOKEN_FILE 2>/dev/null) '$OP' vault list" &>/dev/null &&
  ! confirm "op: write agent's service account token again?"; then
  success "op: agent's service account works"
else
  "$OP" whoami &>/dev/null || eval "$("$OP" signin)"

  if "$OP" vault get "$AGENT_VAULT" &>/dev/null; then
    success "op: vault $AGENT_VAULT exists"
  else
    info "op: creating vault $AGENT_VAULT"
    "$OP" vault create "$AGENT_VAULT"
  fi

  if "$OP" item get "$SA_ITEM" --vault "$PRIVATE_VAULT" &>/dev/null; then
    success "op: service account token already saved in $PRIVATE_VAULT"
  else
    info "op: creating service account agent@$HOST"
    # The token is only shown once; save it before anything else can fail.
    token=$("$OP" service-account create "agent@$HOST" --vault "$AGENT_VAULT:read_items" --raw)
    "$OP" item create --vault "$PRIVATE_VAULT" --category "API Credential" \
      --title "$SA_ITEM" "credential=$token" >/dev/null
    unset token
  fi

  "$OP" read "op://$PRIVATE_VAULT/$SA_ITEM/credential" |
    as_agent sh -c "umask 077; mkdir -p ~/.config/op; chmod 700 ~/.config/op; cat > ~/$SA_TOKEN_FILE"
  success "op: token written to ~agent/$SA_TOKEN_FILE"

  info "op: checking service account access"
  as_agent sh -c "OP_SERVICE_ACCOUNT_TOKEN=\$(cat ~/$SA_TOKEN_FILE) '$OP' vault list"
fi

gh_login "$AGENT_LOGIN" as_agent
gh_ssh_key agent /Users/agent as_agent

success "Done."
