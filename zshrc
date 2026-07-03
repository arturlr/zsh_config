#!/bin/zsh

#### OPTIONS ##################################################################
## https://zsh.sourceforge.io/Doc/Release/Options.html
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
unsetopt inc_append_history
unsetopt share_history

### TMUX  ###
if [[ "$TERM" == "xterm-ghostty" && -z "$TMUX" ]]; then
  export TERM=xterm-256color
fi

if [[ -z "$TMUX" ]] && [[ -n "$SSH_CONNECTION" ]]; then
    # Only run tmux if we ARE NOT in VS Code or Zed
    if [[ "$TERM_PROGRAM" != "vscode" ]] && [[ "$TERM_PROGRAM" != "zed" ]]; then
        tmux attach-session -t default || tmux new-session -s default
    fi
fi

# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/.local/share/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/.local/share/kiro-cli/shell/zshrc.pre.zsh"

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

# Path cleaning: Native zsh array printer (faster, cleaner, no pipe spawned)
alias path='print -l $path'

# Search for text in files (ripgrep)
alias grep='rg'
alias rgi='rg -i' # Case-insensitive search
alias bat='batcat'

#### FUNCTIONS ################################################################

# Load fast Zsh native date/time module (removes external `date` process overhead)
zmodload zsh/datetime

# 1. Store a secret key in AWS Parameter Store as a SecureString
ssm-set() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage:  ssm-set <parameter-name> <value>"
        echo "Ex:     ssm-set /prod/gemini/api_key AIzaSy..."
        return 1
    fi

    local name="$1"
    local value="$2"

    echo "Uploading secure parameter to AWS..."
    aws ssm put-parameter \
        --name "$name" \
        --value "$value" \
        --type "SecureString" \
        --overwrite

    if [ $? -eq 0 ]; then
        echo "Parameter '$name' successfully saved."
    else
        echo "Failed to save parameter."
    fi
}

# 2. Retrieve a secret from AWS Parameter Store and export it
ssm-get() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage:  ssm-get <parameter-name> <env-var-to-export>"
        echo "Ex:     ssm-get /prod/gemini/api_key GEMINI_API_KEY"
        return 1
    fi

    local name="$1"
    local env_var="$2"

    echo "🔄 Fetching parameter from AWS..."
    local secret_value
    secret_value=$(aws ssm get-parameter \
        --name "$name" \
        --with-decryption \
        --query "Parameter.Value" \
        --output text 2>/dev/null)

    if [ -z "$secret_value" ] || [ "$secret_value" = "None" ]; then
        echo "Error: Could not retrieve or decrypt parameter '$name'."
        return 1
    fi

    # Dynamically export it to the environment variable of choice
    export "$env_var"="$secret_value"
    echo "Exported '$name' to \$$env_var in your current session!"
}

# 3. Quick fuzzy finder switch for AWS CLI Profiles
asp() {
  local profile
  profile=$(aws configure list-profiles 2>/dev/null | fzf --height 40% --layout=reverse --border)
  if [[ -n "$profile" ]]; then
    export AWS_PROFILE="$profile"
    echo "☁️ Switched to AWS Profile: $AWS_PROFILE"
  fi
}

## using aws logs tail ###
ltail() {
    local func_name=$1
    local filter=$2
    local log_group="/aws/lambda/$func_name"

    if [[ -z "$func_name" ]]; then
        echo "Usage: ltail <function_name> [filter_pattern]"
        return 1
    fi

    if [[ -n "$filter" ]]; then
        echo "Tailing $log_group with filter: $filter"
        # --follow ensures it stays open; rg handles the filtering
        aws logs tail "$log_group" --follow --format short | rg "$filter"
    else
        echo "Tailing $log_group (no filter)..."
        aws logs tail "$log_group" --follow --format short
    fi
}

# Function to find errors in Lambda logs
# Usage: lerr <function_name> [search_term]
function lerr() {
    local func_name=$1
    local search_term=${2:-"ERROR"} # Defaults to "ERROR" if no 2nd arg is provided
    local log_group="/aws/lambda/$func_name"

    if [[ -z "$func_name" ]]; then
        echo "Usage: lerr <function_name> [search_term]"
        return 1
    fi

    echo "Searching $log_group for \"$search_term\"..."

    aws logs filter-log-events \
        --log-group-name "$log_group" \
        --filter-pattern "$search_term" \
        --interleaved \
        --query 'events[*].[timestamp, message]' \
        --output table
}

# Fuzzy Find & Open (fzf + bat)
function fo() {
  local file
  file=$(fzf --preview 'batcat --color=always --style=numbers --line-range=:500 {}')
  [[ -n "$file" ]] && ${EDITOR:-nano} "$file"
}

function ts {
  strftime "%Y-%m-%d %H:%M:%S" $EPOCHSECONDS
}

function iso {
  strftime "%Y-%m-%d" $EPOCHSECONDS
}

function tmpname {
  local name
  strftime -v name "%Y-%m-%d_%H-%M-%S" $EPOCHSECONDS
  echo "tempfile_$name"
}

function bandwidth {
  local url="http://cachefly.cachefly.net/100mb.test"
  if [[ "$(uname)" == "Darwin" ]]; then
    curl -o /dev/null -w "Download speed: %{speed_download} bytes/sec\n" -s "$url"
  else
    wget "$url" -O /dev/null --report-speed=bits 2>&1 | grep -oP '\d+[\.,]?\d*\s[KMG]?b/s'
  fi
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

#### MISE #####################################################################
# you typically want to put mise activate at the end of your shell config so nothing overrides it.
eval "$(~/.local/bin/mise activate zsh)"

## Java
export JAVA_TOOLS_OPTIONS="-Dlog4j2.formatMsgNoLookups=true"

## DOTNET (Silenced missing path checks during startup)
export DOTNET_ROOT="$(mise where dotnet 2>/dev/null)"

## Rust
export PATH="$HOME/.cargo/bin:$PATH"

## Snap
export PATH="$PATH:/snap/bin"

# Added by Amplify CLI binary installer
export PATH="$HOME/.amplify/bin:$PATH"

# Android
export ANDROID_HOME="$HOME/Android/Sdk"

# cfn-nag
export PATH="$HOME/.guard/bin:$PATH"

eval "$(starship init zsh)"

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/.local/share/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/.local/share/kiro-cli/shell/zshrc.post.zsh"

# Added by Antigravity CLI installer
export PATH="/home/arturlr/.local/bin:$PATH"

# -----------------------------------------------------------------------------
# AWS PARAMETER MANIFEST (Add automated ssm-get commands here later if needed)
# If the variable isn't set yet, dynamically grab it right now
#if [[ -z "$GEMINI_API_KEY" ]]; then
#    ssm-get /dev/apis/gemini_key GEMINI_API_KEY || return 1
#fi
# -----------------------------------------------------------------------------
