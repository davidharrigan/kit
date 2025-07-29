export ZSH=$HOME/.oh-my-zsh

ZSH_THEME="custom"

## oh-my-zsh configuration
COMPLETION_WAITING_DOTS="true"

# Plug-ins
plugins=(git kubectx)

# completions
export FPATH=$HOME/.completion/zsh:$FPATH

source $ZSH/oh-my-zsh.sh

autoload -U colors
colors

# User configuration
if command -v direnv >/dev/null 2>&1; then
  # load direnv
  eval "$(direnv hook zsh)"
fi

# Load aliases
. <(cat $HOME/.aliases/*.alias)

# Load OS specific environments
if [[ "$(uname)" == "Darwin" ]]; then
  . $HOME/.env/os/macos.env
fi

# Load environment variables
. <(cat $HOME/.env/*.env)

# Key binds
bindkey "^k" history-beginning-search-backward
bindkey "^j" history-beginning-search-forward

export GPG_TTY=$(tty)

export PATH="/opt/homebrew/opt/postgresql@13/bin:$PATH"
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/david/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

# Added by Windsurf
export PATH="/Users/david/.codeium/windsurf/bin:$PATH"
