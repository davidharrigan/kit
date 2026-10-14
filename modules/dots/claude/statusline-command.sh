#!/usr/bin/env bash
# Claude Code status line — one line, two zones, degrades under a width budget
#
#   ⬡  Opus 5 (high) [13%] · NORMAL  dots/.claude  ‹codex-and-skills›

BUDGET=100

input=$(cat)

eval "$(
  echo "$input" | jq -r '
    @sh "cwd=\(.cwd // .workspace.current_dir // "")",
    @sh "proj=\(.workspace.project_dir // "")",
    @sh "wt=\(.worktree.name // .workspace.git_worktree // "")",
    @sh "model=\(.model.display_name // "")",
    @sh "effort=\(.effort.level // "")",
    @sh "style=\(.output_style.name // "")",
    @sh "fast=\(.fast_mode // false)",
    @sh "used=\(.context_window.used_percentage // "")",
    @sh "vim=\(.vim.mode // "")"
  '
)"

git_branch=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --is-inside-work-tree --no-optional-locks >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
fi

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
grey='\033[0;90m'
bold='\033[1m'
bold_magenta='\033[1;35m'
reset='\033[0m'

# Path relative to the project root, so deep worktree paths stay short
short_path() {
  local p=$1 root=$2
  if [ -n "$root" ] && { [ "$p" = "$root" ] || [ "${p#"$root"/}" != "$p" ]; }; then
    local out="${root##*/}"
    [ "$p" != "$root" ] && out="${out}/${p#"$root"/}"
    printf '%s' "$out"
  else
    printf '%s' "${p/#$HOME/~}"
  fi
}

# Long branch names lose their middle, not their tail
short_branch() {
  local b=$1 max=$2
  if [ ${#b} -gt "$max" ]; then
    printf '%s…%s' "${b:0:$((max / 2 - 2))}" "${b: -$((max / 2))}"
  else
    printf '%s' "$b"
  fi
}

p1=""; c1=""
add_session() {
  if [ -n "$p1" ]; then p1="${p1}  "; c1="${c1}  "; fi
  p1="${p1}$1"; c1="${c1}$2"
}

p2=""; c2=""
add_place() {
  if [ -n "$p2" ]; then p2="${p2}  "; c2="${c2}  "; fi
  p2="${p2}$1"; c2="${c2}$2"
}

# The model's own parenthetical becomes a suffix, so (effort) is the only one
mp=""; mc=""
if [ -n "$model" ]; then
  base=${model%% (*}
  mcol=$grey
  if [ "$model" != "$base" ]; then
    paren=${model#*(}; paren=${paren%%)*}
    [ "${paren% context}" = "1M" ] && mcol=$cyan
  fi
  mp="$base"; mc="${mcol}${base}${reset}"
  [ -n "$effort" ] && { mp="${mp} (${effort})"; mc="${mc} ${magenta}(${effort})${reset}"; }
fi

if [ -n "$used" ]; then
  pct=$(printf '%.0f' "$used")
  ctx_colour=$grey
  [ "$pct" -ge 70 ] && ctx_colour=$yellow
  [ "$pct" -ge 90 ] && ctx_colour=$red
  [ -n "$mp" ] && { mp="${mp} "; mc="${mc} "; }
  mp="${mp}[${pct}%]"; mc="${mc}${ctx_colour}[${pct}%]${reset}"
fi

if [ -n "$mp" ]; then
  add_session "⬡  ${mp}" "${bold_magenta}⬡${reset}  ${mc}"
else
  add_session "⬡" "${bold_magenta}⬡${reset}"
fi

[ "$fast" = "true" ] && add_session "⚡ fast" "${yellow}⚡ fast${reset}"
[ -n "$style" ] && [ "$style" != "default" ] && add_session "$style" "${green}${style}${reset}"

build_place() {
  local path=$1 branch=$2
  p2=""; c2=""
  [ -n "$vim" ] && [ "$vim" != "INSERT" ] && add_place "$vim" "${bold}${grey}${vim}${reset}"
  [ -n "$path" ] && add_place "$path" "${bold}${blue}${path}${reset}"
  if [ -n "$branch" ]; then
    local pb="‹${branch}›" cb="${yellow}‹${branch}›${reset}"
    [ -n "$wt" ] && { pb="${pb}⑂"; cb="${cb}${grey}⑂${reset}"; }
    add_place "$pb" "$cb"
  fi
}

over_budget() {
  local total=${#p1}
  [ -n "$p2" ] && total=$((total + 3 + ${#p2}))
  [ "$total" -gt "$BUDGET" ]
}

path=$(short_path "$cwd" "$proj")
branch=$(short_branch "$git_branch" 28)
build_place "$path" "$branch"
over_budget && { path="…/${path##*/}"; build_place "$path" "$branch"; }
over_budget && { branch=$(short_branch "$git_branch" 18); build_place "$path" "$branch"; }

if [ -n "$p2" ]; then
  printf "%b\n" "${c1}${grey} · ${reset}${c2}"
else
  printf "%b\n" "$c1"
fi
