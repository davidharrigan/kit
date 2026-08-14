#!/usr/bin/env bash
# Launch an orchestrator workspace for a /task run.
#
# Usage: launch.sh <task-id> <summary> <closing-ref> <brief-file>
#   task-id      short kebab slug, names the workspace and status pill
#   summary      one-line workspace description
#   closing-ref  "Closes #N" for a same-repo GitHub issue, else "none"
#   brief-file   path to the resolved task brief (written by the skill with the
#                Write tool, so arbitrary quotes/backticks/newlines are safe)
#
# Renders the orchestrator prompt from orchestrator.md + the brief itself, then
# does everything deterministic about the launch so the skill needs one
# approval, not five:
#   * forwards the CALLER's live permission mode to the child claude session
#     (read from the newest transcript in the caller's project dir), so the
#     orchestrator starts with the same autonomy the user already granted
#   * groups the workspace under its repo, one group per repo, and tints the
#     group + workspace + status pill a deterministic purple shade for that repo
#   * sets the orchestrator status pill
#
# Prints two lines the skill parses:  WORKSPACE <ref>   and   MODE <mode>

set -uo pipefail

task_id="${1:?usage: launch.sh <task-id> <summary> <closing-ref> <brief-file>}"
summary="${2:-$task_id}"
closing_ref="${3:-none}"
brief_file="${4:?missing brief-file}"
[ -s "$brief_file" ] || { echo "ERROR: brief file empty or missing: $brief_file" >&2; exit 1; }

repo_root="$(git rev-parse --show-toplevel)" || { echo "ERROR: not in a git repo" >&2; exit 1; }
repo="$(basename "$repo_root")"

# --- 0. Render the orchestrator prompt from the template + brief --------------
tmpl="$HOME/.claude/skills/task/orchestrator.md"
[ -s "$tmpl" ] || { echo "ERROR: orchestrator template missing: $tmpl" >&2; exit 1; }
prompt="$(mktemp /tmp/task-XXXXXX.md)"
sed "s|{{TASK_ID}}|$task_id|g" "$tmpl" > "$prompt"
{ printf '\nClosing reference: %s\n\n' "$closing_ref"; cat "$brief_file"; } >> "$prompt"

# --- 1. Detect the caller's live permission mode -----------------------------
# Each transcript entry carries a top-level "permissionMode". The caller's
# session is the newest .jsonl in the project dir for its cwd; fall back to the
# newest transcript anywhere if that lookup misses.
proj_slug="$(printf '%s' "$PWD" | sed 's#[/.]#-#g')"
proj_dir="$HOME/.claude/projects/$proj_slug"
newest=""
[ -d "$proj_dir" ] && newest="$(ls -t "$proj_dir"/*.jsonl 2>/dev/null | head -1)"
[ -n "$newest" ] || newest="$(ls -t "$HOME"/.claude/projects/*/*.jsonl 2>/dev/null | head -1)"

parent_mode=""
[ -n "$newest" ] && parent_mode="$(grep -oh '"permissionMode":"[a-zA-Z]*"' "$newest" 2>/dev/null | tail -1 | sed 's/.*:"//;s/"$//')"

# Map to a --permission-mode flag. "default"/normal/unknown => no flag (the
# child's natural default). The rest are pass-through choices claude accepts.
perm_flag=""
case "$parent_mode" in
  auto|acceptEdits|plan|bypassPermissions) perm_flag="--permission-mode $parent_mode" ;;
esac

# Command the child shell runs. $(cat ...) must expand in THAT shell, so its $
# is escaped here; the prompt file is read at child start-up.
child_cmd="claude"
[ -n "$perm_flag" ] && child_cmd="$child_cmd $perm_flag"
child_cmd="$child_cmd \"\$(cat '$prompt')\""

# --- 2. Deterministic purple shade for this repo -----------------------------
palette=(a855f7 9333ea 7c3aed 8b5cf6 6d28d9 c026d3 a21caf 7e22ce)
h="$(printf '%s' "$repo" | cksum | cut -d' ' -f1)"
shade="#${palette[$(( h % ${#palette[@]} ))]}"

export CMUX_QUIET=1

# --- 3. Resolve (or plan to create) the repo's group -------------------------
group_ref_for() {  # print ref of the group named "$1", empty if none
  cmux workspace-group list --json 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
for g in d.get('groups',[]):
    if g.get('name')==sys.argv[1]:
        print(g.get('ref') or g.get('id') or ''); break
" "$1"
}
group_color_for() {  # print custom_color (or empty) of group named "$1"
  cmux workspace-group list --json 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
for g in d.get('groups',[]):
    if g.get('name')==sys.argv[1]:
        print(g.get('custom_color') or ''); break
" "$1"
}

gref="$(group_ref_for "$repo")"

# --- 4. Create the workspace, inside the group when one already exists --------
if [ -n "$gref" ]; then
  out="$(cmux new-workspace --name "$task_id" --cwd "$repo_root" \
          --description "$summary" --focus false \
          --env "TASK_SHADE=$shade" \
          --group "$gref" --group-placement end \
          --command "$child_cmd")"
else
  out="$(cmux new-workspace --name "$task_id" --cwd "$repo_root" \
          --description "$summary" --focus false \
          --env "TASK_SHADE=$shade" \
          --command "$child_cmd")"
fi

wsref="$(printf '%s\n' "$out" | grep -oE 'workspace:[0-9]+' | head -1)"
[ -n "$wsref" ] || { echo "ERROR: could not parse workspace ref from: $out" >&2; exit 1; }

# Form the group from this workspace if the repo had none yet (no phantom anchor).
if [ -z "$gref" ]; then
  cmux workspace-group create --name "$repo" --from "$wsref" >/dev/null 2>&1
  gref="$(group_ref_for "$repo")"
fi

# Tint the group if it has no color yet, so every repo reads as its own shade.
if [ -n "$gref" ] && [ -z "$(group_color_for "$repo")" ]; then
  cmux workspace-group set-color "$gref" --hex "$shade" >/dev/null 2>&1
fi

# --- 5. Tint the workspace row + status pill to match -------------------------
cmux workspace-action --workspace "$wsref" --action set-color --color "$shade" >/dev/null 2>&1
cmux set-status orchestrator "$task_id" --workspace "$wsref" \
  --icon sparkle --color "$shade" --priority 80 >/dev/null 2>&1

echo "WORKSPACE $wsref"
echo "MODE ${parent_mode:-default}"
