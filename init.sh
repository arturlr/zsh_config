#!/bin/bash
set -e

echo "Starting system initialization..."

# 1. Update and install essentials
sudo apt-get update -qq
sudo apt-get install -y -qq zsh jq wget curl unzip ripgrep bat tmux git zip ca-certificates

# 2. Install Starship (Prompt)
if ! command -v starship &> /dev/null; then
    echo "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# 3. Install Mise
MISE_BIN="$HOME/.local/bin/mise"
if [ ! -f "$MISE_BIN" ]; then
    echo "Installing Mise..."
    curl https://mise.run | sh
fi

# 4. Install Oh My Zsh (Non-interactive)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 5. Install Custom Plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Syntax Highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# History Substring Search
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]; then
    git clone https://github.com/zsh-users/zsh-history-substring-search.git "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
fi

# 6. Generate .zshrc (Overwrite with your specific config)
echo "Generating .zshrc..."
cat <<EOF > "$HOME/.zshrc"
# Path to your oh-my-zsh installation.
export ZSH="\$HOME/.oh-my-zsh"

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

source \$ZSH/oh-my-zsh.sh

# History Substring Search Keybindings (Arrow Keys)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Prompt
eval "\$(starship init zsh)"

#### MISE 
# you typically want to put mise activate at the end of your shell config so nothing overrides it.
eval "\$($HOME/.local/bin/mise activate zsh)"
EOF

# 7. Use Mise to install runtimes
"$MISE_BIN" use -g node@20
"$MISE_BIN" use -g python@3.12

# 8. Installing AWSCLI
if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI..."
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip -q /tmp/awscliv2.zip -d /tmp/aws_install_dir
    sudo /tmp/aws_install_dir/aws/install --update
    rm -rf /tmp/awscliv2.zip /tmp/aws_install_dir
fi

# 9. Set Zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    sudo chsh -s "$(which zsh)" "$USER"
fi

echo "-------------------------------------------------------"
echo "Initialization complete!"
echo "Please LOG OUT and LOG BACK IN to start your new Zsh session."
echo "-------------------------------------------------------"
