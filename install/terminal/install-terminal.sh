#!/usr/bin/env bash
# ===============================================
# Dotfiles installer (terminal setup)
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library
source "${HOME}/install/lib.sh"

init_log "${LOG_DIR}/terminal-install.log"

ensure_gum

spinner "Installing terminal utilities..."

# Variables for user choices
INSTALL_GO=false
INSTALL_RUST=false
DEFAULT_SHELL=""
INSTALL_DOCKER=false
INSTALL_NODE=false
INSTALL_XDG_NINJA=false

# Step 1: Main menu for installation options
CHOICES=$(
    gum choose --no-limit \
        "Install Go toolchain and lazygit" \
        "Install Rust toolchain and crates" \
        "Install Docker" \
        "Install Node.js and npm" \
        "Install XDG Ninja"
)

# Parse choices
while IFS= read -r CHOICE; do
    case "$CHOICE" in
    "Install Go toolchain and lazygit") INSTALL_GO=true ;;
    "Install Rust toolchain and crates") INSTALL_RUST=true ;;
    "Install Docker") INSTALL_DOCKER=true ;;
    "Install Node.js and npm") INSTALL_NODE=true ;;
    "Install XDG Ninja") INSTALL_XDG_NINJA=true ;;
    esac
done <<<"$CHOICES"

# Step 2: Shell selection menu
DEFAULT_SHELL=$(
    gum choose \
        "/bin/zsh (ZSH)" \
        "/bin/bash (Bash)" \
        "/usr/bin/fish (Fish)" \
        "Skip (Keep current shell)"
)

case "$DEFAULT_SHELL" in
"/bin/zsh (ZSH)") DEFAULT_SHELL="/bin/zsh" ;;
"/bin/bash (Bash)") DEFAULT_SHELL="/bin/bash" ;;
"/usr/bin/fish (Fish)") DEFAULT_SHELL="/usr/bin/fish" ;;
"Skip (Keep current shell)") DEFAULT_SHELL="" ;; # Skip changing the shell
esac

# Step 3: Installation progress
spinner "Installing dependencies..."
sudo dnf install -y zsh autojump-zsh perl jq fastfetch alsa-lib-devel entr fzf git-all neovim openssl-devel python3-pip protobuf protobuf-c protobuf-compiler protobuf-devel cmake zlib-ng zlib-ng-devel oniguruma-devel luarocks wget fish

spinner "Installing package group dependencies..."
sudo dnf group install -y fonts c-development development-tools

pip install neovim

# Step 4: Git configuration
GIT_NAME=$(gum input --placeholder "Enter your full name for Git")
GIT_EMAIL=$(gum input --placeholder "Enter your email address for Git")

# Configure Git if both name and email are provided
if [[ -n "$GIT_NAME" && -n "$GIT_EMAIL" ]]; then
    spinner "Configuring Git..."
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.st status
    git config --global pull.rebase true
    git config --global init.defaultBranch master
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
else
    info_message "Git name or email not provided. Skipping Git configuration."
fi

# Install Go if selected
if [ "$INSTALL_GO" = true ]; then
    spinner "Installing Go and lazygit..."
    bash ~/install/terminal/golang.sh
fi

# Install Rust if selected
if [ "$INSTALL_RUST" = true ]; then
    spinner "Installing Rust..."
    bash ~/install/terminal/rust.sh
fi

# Install Docker if selected
if [ "$INSTALL_DOCKER" = true ]; then
    spinner "Installing Docker..."
    sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine || true
    sudo dnf install -y dnf-plugins-core
    sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable --now docker
fi

# Install Node.js and npm if selected
if [ "$INSTALL_NODE" = true ]; then
    spinner "Installing Node.js and npm..."
    sudo dnf install -y nodejs-npm
    sudo npm config set prefix="${XDG_DATA_HOME}/npm"
    sudo npm config set cache="${XDG_CACHE_HOME}/npm"
    sudo npm config set init-module="${XDG_CONFIG_HOME}/npm/config/npm-init.js"
    sudo chmod 777 '.cache'
    sudo chown -R "$(id -u):$(id -g)" "${HOME}/.cache/npm" || true
fi

# Install XDG Ninja if selected
if [ "$INSTALL_XDG_NINJA" = true ]; then
    spinner "Installing XDG Ninja..."
    git clone https://github.com/b3nj5m1n/xdg-ninja ~/.local/share/xdg-ninja
fi

# Change default shell if selected
if [ -n "$DEFAULT_SHELL" ]; then
    spinner "Changing default shell to $DEFAULT_SHELL..."
    if [ "$DEFAULT_SHELL" == "/bin/bash" ]; then
        spinner "Installing ble.sh for Bash enhancements..."
        git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git "${XDG_DATA_HOME}"/ble.sh
        cd "${XDG_DATA_HOME}"/ble.sh
        make install
    fi
    bash ~/install/terminal/oh-my-posh.sh
    chsh -s "$DEFAULT_SHELL"
else
    info_message "Skipping shell change."
fi

finish "The terminal installation is finished!"
