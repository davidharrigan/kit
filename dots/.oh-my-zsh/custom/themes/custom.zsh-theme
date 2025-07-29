local return_code="%(?..%{$fg[red]%} %?↵%{$reset_color%})"
local user_host="%B%(!.%{$fg[red]%}.%{$fg[green]%})%n@%m%{$reset_color%} "
local user_symbol='%(!.#.$)'
local current_dir="%B%{$fg[blue]%}%~ %{$reset_color%}"

local vcs_branch='$(git_prompt_info)'
local venv_prompt='$(virtualenv_prompt_info)'
if whence kubectx_prompt_info >/dev/null; then
  local kube_prompt='$(kubectx_prompt_info)'
fi

local _newline=$'\n'
local _lineup=$'\e[1A'
local _linedown=$'\e[1B'

PROMPT=${_newline}...whatever...
RPROMPT=%{${_lineup}%}...whatever...%{${_linedown}%}

PROMPT="╭─${user_host}${current_dir}${vcs_branch}${venv_prompt}
╰─%B${user_symbol}%b "
RPROMPT="%{${_lineup}%}${kube_prompt}%B${return_code} %b%{${_linedown}%}"

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[yellow]%}‹"
ZSH_THEME_GIT_PROMPT_SUFFIX="› %{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}●%{$fg[yellow]%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[yellow]%}"

ZSH_THEME_VIRTUAL_ENV_PROMPT_PREFIX="%{$fg[green]%}‹"
ZSH_THEME_VIRTUAL_ENV_PROMPT_SUFFIX="› %{$reset_color%}"
