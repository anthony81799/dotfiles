#!/usr/bin/env bash
# ===============================================
# Dotfiles installer (terminal setup)
# ===============================================
set -euo pipefail
IFS=$'\n\t'

source "${HOME}/install/lib.sh"

init_log "${LOG_DIR}/terminal-install.log"

ensure_gum

banner "Installing terminal utilities"

INSTALL_GO=false
INSTALL_DOCKER=false
INSTALL_NODE=false
INSTALL_XDG_NINJA=false

install_node() {
	spinner "Installing Node.js and npm..."
	sudo dnf install -y nodejs-npm || {
		fail_message "Failed to install nodejs-npm via DNF."
		return 1
	}

	spinner "Configuring npm for XDG Base Directory structure..."
	sudo npm config set prefix="${XDG_DATA_HOME}/npm"
	sudo npm config set cache="${XDG_CACHE_HOME}/npm"
	sudo npm config set init-module="${XDG_CONFIG_HOME}/npm/config/npm-init.js"

	mkdir -p "${XDG_CACHE_HOME}/npm"
	sudo chown -R "$(id -u):$(id -g)" "${XDG_CACHE_HOME}/npm" || true

	okay_message "Node.js and npm installed and configured for XDG."
}

CHOICES=$(
	gum choose --no-limit \
		--header "Select terminal components to install" \
		"Go toolchain and lazygit" \
		"Docker" \
		"Node.js and npm" \
		"XDG Ninja"
)

while IFS= read -r CHOICE; do
	case "$CHOICE" in
	"Go toolchain and lazygit") INSTALL_GO=true ;;
	"Docker") INSTALL_DOCKER=true ;;
	"Node.js and npm") INSTALL_NODE=true ;;
	"XDG Ninja") INSTALL_XDG_NINJA=true ;;
	esac
done <<<"$CHOICES"

bash ~/install/terminal/change-shell.sh

spinner "Installing core DNF dependencies..."
sudo dnf install -y \
	zsh autojump-zsh perl jq fastfetch alsa-lib-devel entr fzf tmux lsd \
	neofetch man-db man-pages-ja-less man-pages-ja man-pages-zh-CN-less \
	unzip || {
	fail_message "Failed to install core DNF dependencies."
	finish "Terminal utility setup failed."
}
okay_message "Core DNF dependencies installed."

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

bash ~/install/terminal/git.sh

if [ "$INSTALL_NODE" = true ]; then
	install_node
fi

if [ "$INSTALL_GO" = true ]; then
	bash ~/install/terminal/golang.sh
fi

bash ~/install/terminal/rust.sh
bash ~/install/terminal/editor.sh

if [ "$INSTALL_DOCKER" = true ]; then
	bash ~/install/terminal/docker-services.sh
fi

if [ "$INSTALL_XDG_NINJA" = true ]; then
	spinner "Installing XDG Ninja..."
	XDG_NINJA_DIR="${HOME}/.local/share/xdg-ninja"
	if [ -d "$XDG_NINJA_DIR" ]; then
		info_message "XDG Ninja already cloned. Skipping clone."
	else
		git clone --depth 1 https://github.com/b3nj5m1n/xdg-ninja "$XDG_NINJA_DIR" || {
			fail_message "Failed to clone XDG Ninja."
		}
	fi
	okay_message "XDG Ninja setup complete."
fi

finish "Terminal utility setup complete!"
