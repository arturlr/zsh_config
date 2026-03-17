#!/bin/zsh#### OPTIONS ##################################################################

## https://zsh.sourceforge.io/Doc/Release/Options.html
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
unsetopt inc_append_history
unsetopt share_history

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
alias grep='rg'
alias rgi='rg -i' # Case-insensitive search
alias bat='batcat'

#### FUNCTIONS ################################################################
function gcommit() {
  if git diff --cached --quiet; then
    echo "No staged changes to commit."
    return 1
  fi

  local diff_content
  local line_count=\$(git diff --staged | wc -l)
  local max_lines=500

  if [ "\$line_count" -gt "\$max_lines" ]; then
    echo "⚠️ Diff is large (\$line_count lines). Sending file summary + partial diff to Gemini..."
    diff_content=\$(git diff --staged --stat)
    diff_content+=\$'\n\nDetailed snippet of changes:\n'
    diff_content+=\$(git diff --staged | head -n 150)
  else
    diff_content=\$(git diff --staged)
  fi

  echo "Generating commit message..."
  local msg_file=\$(mktemp)

  echo "\$diff_content" | gemini "Write a Conventional Commit message for this diff.
  Include a short summary line, a blank line, and a bulleted list of key changes.
  Output ONLY the commit message text." > "\$msg_file"

  if [ ! -s "\$msg_file" ]; then
    echo "❌ Failed to generate commit message."
    rm "\$msg_file"
    return 1
  fi

  git commit -F "\$msg_file"
  rm "\$msg_file"
}

# Timestamps & Temp Files
function ts() { date +"%Y-%m-%d %H:%M:%S"; }
function iso() { date +"%Y-%m-%d"; }
function tmpname() { echo "tempfile_\$(date +'%Y-%m-%d_%H-%M-%S')"; }

# Fuzzy Find & Open (fzf + bat)
function fo() {
  local file
  file=\$(fzf --preview 'batcat --color=always --style=numbers --line-range=:500 {}')
  [[ -n "\$file" ]] && \${EDITOR:-nano} "\$file"
}

function ts {
  iso_stamp=`date +"%Y-%m-%d %H:%M:%S"`
  echo $iso_stamp
}

function iso {
  iso_stamp=`date +"%Y-%m-%d"`
  echo $iso_stamp
}

function tmpname {
  local name=`date +"%Y-%m-%d_%H-%M-%S"`
  echo "tempfile_$name"
}

function bandwidth {
  echo "$(echo "en$(route get cachefly.cachefly.net | grep interface | sed -n -e 's/^.*en//p')") $(wget http://cachefly.cachefly.net/100mb.test -O /dev/null --report-speed=bits 2>&1 | grep '\([0-9.]\+ [KMG]b/s\)')"
}

#### OH MY ZSH ################################################################
export ZSH=$HOME/.oh-my-zsh  # Path to your oh-my-zsh installation.
#COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="yyyy-mm-dd"

ZSH_THEME=""

plugins=(
  history-substring-search
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

#### PATH #####################################################################
export PATH="$HOME/bin:/usr/sbin:/usr/local/bin:/usr/bin:/bin:/usr/local/opt/curl/bin:/usr/local/opt/ruby/bin"
export LDFLAGS="-L/usr/local/opt/ruby/lib"
export CPPFLAGS="-I/usr/local/opt/ruby/include"
export PKG_CONFIG_PATH="/usr/local/opt/ruby/lib/pkgconfig"

## Rust
export PATH="$HOME/.cargo/bin:$PATH"

## Snap
export PATH="$PATH:/snap/bin"

# Added by Amplify CLI binary installer
export PATH="$HOME/.amplify/bin:$PATH"

# Android
export ANDROID_HOME="$HOME/Android/Sdk"

eval "$(starship init zsh)"

#### MISE #####################################################################
# you typically want to put mise activate at the end of your shell config so nothing overrides it.
eval "$(~/.local/bin/mise activate zsh)"
