#!/bin/zsh#### OPTIONS ##################################################################

## https://zsh.sourceforge.io/Doc/Release/Options.html
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
unsetopt inc_append_history
unsetopt share_history

#### ALIASES ##################################################################
alias fd='find . -type d | sort'
alias ff='find . -type f | sort'
alias grep='grep --color=auto'
alias k9='kill -9'
alias ll='ls -lha'
alias bat='batcat'

#### FUNCTIONS ################################################################
function gcommit() {
  # 1. Check for staged changes
  if git diff --cached --quiet; then
    echo "No staged changes to commit."
    return 1
  fi

  echo "Generating multi-line commit message..."

  # 2. Create a temporary file for the message
  local msg_file=$(mktemp)

  # 3. Stream the diff to Gemini and save to the file
  # We ask for a body to avoid the "one-liner" limitation
  git diff --staged | gemini "Write a Conventional Commit message for this diff.
  Include a short summary line, a blank line, and a bulleted list of key changes.
  Output ONLY the commit message text." > "$msg_file"

  # 4. Check if the message generation actually worked
  if [ ! -s "$msg_file" ]; then
    echo "Failed to generate commit message."
    rm "$msg_file"
    return 1
  fi

  # 5. Commit using the file (-F) instead of a string (-m)
  git commit -F "$msg_file"

  # 6. Cleanup
  rm "$msg_file"
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
