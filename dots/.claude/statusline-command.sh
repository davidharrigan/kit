#!/usr/bin/env bash
# Claude Code status line — mirrors the custom zsh theme style

input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Git info (skip lock to avoid blocking)
git_branch=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --is-inside-work-tree --no-optional-locks >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
fi

# ANSI colors (dimmed terminal will further mute these)
blue='\033[0;34m'
yellow='\033[0;33m'
cyan='\033[0;36m'
magenta='\033[0;35m'
bold_magenta='\033[1;35m'
reset='\033[0m'
bold='\033[1m'

# Claude branding label — visually distinctive so Claude sessions stand out
claude_label="${bold_magenta}⬡ CLAUDE${reset}"

display_cwd="${cwd/#$HOME/~}"
dir_part="${bold}${blue}${display_cwd}${reset}"
branch_part=""
if [ -n "$git_branch" ]; then
  branch_part=" ${yellow}‹${git_branch}›${reset}"
fi

model_part=""
if [ -n "$model" ]; then
  model_part=" ${cyan}${model}${reset}"
fi

ctx_part=""
if [ -n "$used" ]; then
  ctx_part=" ctx:$(printf '%.0f' "$used")%"
fi

printf "%b %b%b%b%b\n" \
  "$claude_label" \
  "$dir_part" \
  "$branch_part" \
  "$model_part" \
  "$ctx_part"
