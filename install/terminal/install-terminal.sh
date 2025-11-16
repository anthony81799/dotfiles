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

banner "Installing terminal utilities"

# Variables for user choices
INSTALL_GO=false
INSTALL_RUST=false
INSTALL_DOCKER=false
INSTALL_NODE=false
INSTALL_XDG_NINJA=false

# Step 1: Main menu for installation options
CHOICES=$(
	gum choose --no-limit \
		--header "Select terminal components to install" \
		"Go toolchain and lazygit" \
		"Rust toolchain and crates" \
		"Docker" \
		"Node.js and npm" \
		"XDG Ninja"
)

# Parse choices
while IFS= read -r CHOICE; do
	case "$CHOICE" in
	"Go toolchain and lazygit") INSTALL_GO=true ;;
	"Rust toolchain and crates") INSTALL_RUST=true ;;
	"Docker") INSTALL_DOCKER=true ;;
	"Node.js and npm") INSTALL_NODE=true ;;
	"XDG Ninja") INSTALL_XDG_NINJA=true ;;
	esac
done <<<"$CHOICES"

# Step 2: Shell selection menu
bash ~/install/terminal/change-shell.sh

# Step 3: Installation progress
spinner "Installing dependencies..."
sudo dnf install -y zsh autojump-zsh perl jq fastfetch alsa-lib-devel entr fzf git-all openssl-devel python3-pip protobuf protobuf-c protobuf-compiler protobuf-devel cmake zlib-ng zlib-ng-devel oniguruma-devel luarocks wget fish flatpak kitty

sudo dnf copr enable -y wezfurlong/wezterm-nightly
sudo dnf install -y wezterm

sudo dnf copr enable -y scottames/ghostty
sudo dnf install -y ghostty

spinner "Installing package group dependencies..."
sudo dnf group install -y fonts c-development development-tools

# Step 4: Hostname configuration
STATIC_HOSTNAME=$(gum input --prompt "Static Hostname > " --placeholder "Enter static hostname for this machine" --value "$(hostnamectl --static)")
if [[ -n "$STATIC_HOSTNAME" ]]; then
	spinner "Setting static hostname to '$STATIC_HOSTNAME'..."
	sudo hostnamectl set-hostname --static $STATIC_HOSTNAME
fi
PRETTY_HOSTNAME=$(gum input --prompt "Pretty Hostname > " --placeholder "Enter pretty hostname for this machine" --value "$(hostnamectl --pretty)")
if [[ -n "$PRETTY_HOSTNAME" ]]; then
	spinner "Setting pretty hostname to '$PRETTY_HOSTNAME'..."
	sudo hostnamectl set-hostname --pretty "$PRETTY_HOSTNAME"
fi

# Step 5: Git configuration
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

# Install Node.js and npm if selected
if [ "$INSTALL_NODE" = true ]; then
	spinner "Installing Node.js and npm..."
	sudo dnf install -y nodejs-npm
	sudo npm config set prefix="${XDG_DATA_HOME}/npm"
	sudo npm config set cache="${XDG_CACHE_HOME}/npm"
	sudo npm config set init-module="${XDG_CONFIG_HOME}/npm/config/npm-init.js"
	sudo chmod 777 '.cache'
	sudo chown -R "$(id -u):$(id -g)" "${HOME}/.cache/npm"
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
	bash ~/install/terminal/docker-services.sh
fi

# Install XDG Ninja if selected
if [ "$INSTALL_XDG_NINJA" = true ]; then
	spinner "Installing XDG Ninja..."
	git clone https://github.com/b3nj5m1n/xdg-ninja ~/.local/share/xdg-ninja
fi
