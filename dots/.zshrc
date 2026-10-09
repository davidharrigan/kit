export ZSH=$HOME/.oh-my-zsh

ZSH_THEME="custom"

## oh-my-zsh configuration
COMPLETION_WAITING_DOTS="true"

# Plug-ins
# plugins=(git kubectx)
plugins=(kubectx)

# completions
export FPATH=$HOME/.completion/zsh:$FPATH

# Homebrew's completion dirs belong to one user, so compinit prompts every other
# user on the machine about insecure dirs. Load them without the prompt.
ZSH_DISABLE_COMPFIX=true

source $ZSH/oh-my-zsh.sh

autoload -U colors
colors

# Draw a horizontal line between commands
_draw_line() {
  print -P '%F{8}${(l:$COLUMNS::─:)}%f'
}
autoload -U add-zsh-hook
add-zsh-hook precmd _draw_line

# User configuration
if command -v direnv >/dev/null 2>&1; then
  # load direnv
  eval "$(direnv hook zsh)"
fi

# Load aliases
alias co="git checkout"
alias cob="git checkout -b"
alias cm="git commit -m"
alias pull="git pull"
alias push="git push"
alias dif="git difftool --tool=opendiff -d"

alias vi="nvim"
alias vim="nvim"
alias vv="nvim"
# alias vv="alias vv='NVIM_APPNAME=nvim-new nvim'"

# Key binds
bindkey "^k" history-beginning-search-backward
bindkey "^j" history-beginning-search-forward

# Load environment variables
export XDG_CONFIG_HOME=$HOME/.config
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export PROMPT_EOL_MARK=""
export CC=gcc
export EDITOR=nvim
export GPG_TTY=$(tty)

# Load OS specific environments
if [[ "$(uname)" == "Darwin" ]]; then
  export PATH="$PATH:/opt/homebrew/bin"
  export PATH="$PATH:$HOME/Library/Python/3.9/bin"
fi

# Load other environment variables
for f in $HOME/.env/*.env(N); do . "$f"; done

# 1Password service account (agent user; written by credentials.sh)
[[ -r ~/.config/op/service-account-token ]] && export OP_SERVICE_ACCOUNT_TOKEN=$(<~/.config/op/service-account-token)

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.local/share/bob/nvim-bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@13/bin:$PATH"

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=($HOME/.docker/completions $fpath)
autoload -Uz compinit
compinit -u
# End of Docker CLI completions

# Custom completions
fpath=($HOME/.zsh/completions $fpath)
autoload -Uz compinit
compinit -u

# Added by Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
export PATH="$HOME/.antigravity-ide/antigravity-ide/bin:$PATH"

# bun completions
[ -s "/Users/david/.bun/_bun" ] && source "/Users/david/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
