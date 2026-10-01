#!/bin/zsh

#### OPTIONS ##################################################################
## https://zsh.sourceforge.io/Doc/Release/Options.html
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
unsetopt inc_append_history
unsetopt share_history

### TMUX
#if [[ -z "$TMUX" ]] && [[ -n "$SSH_CONNECTION" ]]; then
#    # Only run tmux if we ARE NOT in VS Code or Zed
#    if [[ "$TERM_PROGRAM" != "vscode" ]] && [[ "$TERM_PROGRAM" != "zed" ]]; then
#        tmux attach-session -t default || tmux new-session -s default
#    fi
#fi

#### ALIASES ##################################################################
# Mise shortcuts
alias me='mise edit'      # Edit local config
alias mr='mise run'       # Run tasks
alias ml='mise ls'        # List installed runtimes

# Git Essentials (Standard but vital)
alias gst='git status'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias gcm='git commit -m'

# Better 'ls' (Standard Ubuntu)
alias ll='ls -alFh --color=auto --group-directories-first'
alias l='ls -CF'

# Quick reload of Zsh config
alias reload='source ~/.zshrc'

# Path cleaning: show PATH in a readable list
alias path='echo $PATH | tr ":" "\n"'

# Search for text in files (ripgrep)
#alias grep='rg'
alias rgi='rg -i' # Case-insensitive search
alias bat='batcat'

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# History Configuration
HIST_STAMPS="yyyy-mm-dd"
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
unsetopt inc_append_history
unsetopt share_history

# Theme (Handled by Starship)
ZSH_THEME=""

# Plugins
plugins=(
  history-substring-search
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# History Substring Search Keybindings (Arrow Keys)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Prompt
eval "$(starship init zsh)"

#### Secrets
[ -f "$HOME/.config/secrets/env" ] && source "$HOME/.config/secrets/env"

#### MISE
# you typically want to put mise activate at the end of your shell config so nothing overrides it.
eval "$($HOME/.local/bin/mise activate zsh)"
