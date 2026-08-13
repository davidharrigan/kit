#!/usr/bin/env bash
# Watch the PRs opened for one /task run; print one line per event.
#
# Usage: watch-prs.sh <task-id>   (any short slug; names the watch-list file)
# Env:   FLOOR (default 60), CEIL (default 3600) — backoff bounds, seconds.
#        PRS_FILE — override the watch-list path (testing).
#
# Designed to run under the Monitor tool with persistent: true. Every stdout
# line becomes a notification, so it prints ONLY new comments and terminal
# state changes. The poll interval doubles while nothing happens and resets to
# FLOOR on any event; once it would exceed CEIL the script reports and exits,
# so a forgotten PR winds the watch down instead of holding it open forever.
#
# Total quiet time before giving up is about 2x CEIL.
#
# NOTE: `gh api` writes its error body to STDOUT on failure, so every call here
# must be gated on its exit status. Treating a failed call's output as content
# turns a 404 into a permanent stream of bogus events that also resets the
# backoff, and the watch never winds down.

set -uo pipefail

task_id="${1:?usage: watch-prs.sh <task-id>}"
FLOOR="${FLOOR:-60}"
CEIL="${CEIL:-3600}"

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner) || {
  echo "WATCH ENDED: cannot resolve repo (gh not authenticated?)"; exit 1; }

PRS="${PRS_FILE:-$(git rev-parse --git-common-dir)/task-${task_id}-prs}"
[ -s "$PRS" ] || { echo "WATCH ENDED: no open PRs listed at $PRS"; exit 0; }

drop_pr() {  # remove $1 from the watch list
  { grep -v "^${1}$" "$PRS" || true; } > "$PRS.tmp" && mv "$PRS.tmp" "$PRS"
}

emit_comments() {  # $1=api path, $2=jq template; prints only on success
  local body
  body=$(gh api "$1" --jq "$2" 2>/dev/null) || return 1
  [ -n "$body" ] || return 1
  printf '%s\n' "$body"
}

iv=$FLOOR
last=$(date -u +%Y-%m-%dT%H:%M:%SZ)
warned=""

while :; do
  sleep "$iv"
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  hit=0

  # Snapshot the list: the loop body rewrites $PRS as PRs resolve.
  for pr in $(cat "$PRS"); do
    # State first — if the PR is unreachable, skip it without counting an event.
    if ! st=$(gh pr view "$pr" --json state,mergedAt \
                --jq 'if .mergedAt then "MERGED" else .state end' 2>/dev/null); then
      case "$warned" in
        *" $pr "*) ;;
        *) echo "PR $pr unreachable (deleted, or no access) — still listed, not counted as activity"
           warned="$warned $pr " ;;
      esac
      continue
    fi

    if out=$(emit_comments "repos/$REPO/issues/$pr/comments?since=$last" \
               ".[] | \"PR $pr comment from \(.user.login): \(.body)\""); then
      echo "$out"; hit=1
    fi
    if out=$(emit_comments "repos/$REPO/pulls/$pr/comments?since=$last" \
               ".[] | \"PR $pr review comment from \(.user.login) on \(.path): \(.body)\""); then
      echo "$out"; hit=1
    fi

    case "$st" in
      MERGED) echo "PR $pr MERGED";               drop_pr "$pr"; hit=1 ;;
      CLOSED) echo "PR $pr CLOSED without merge"; drop_pr "$pr"; hit=1 ;;
    esac
  done

  last=$now

  [ -s "$PRS" ] || { echo "WATCH ENDED: all PRs resolved."; exit 0; }

  if [ "$hit" = 1 ]; then
    iv=$FLOOR
  else
    iv=$(( iv * 2 ))
    if [ "$iv" -gt "$CEIL" ]; then
      echo "WATCH ENDED: quiet too long. Still open: $(tr '\n' ' ' < "$PRS")"
      exit 0
    fi
  fi
done
