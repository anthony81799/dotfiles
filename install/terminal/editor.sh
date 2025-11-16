#!/usr/bin/env bash
# ===============================================
# Terminal Editor Installer
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library and initialize logging
source "${HOME}/install/lib.sh"

LOG_FILE="${LOG_DIR}/terminal-editor.log"
init_log "$LOG_FILE"

ensure_gum

banner "Terminal Editor Installation"

INSTALL_NEOVIM=false
INSTALL_HELIX=false

# Step 1: Main menu for installation options
CHOICES=$(
	gum choose --no-limit \
		--header "Select editors to install" \
		"Neovim" \
		"Helix"
)

# Parse choices
while IFS= read -r CHOICE; do
	case "$CHOICE" in
	"Neovim") INSTALL_NEOVIM=true ;;
	"Helix") INSTALL_HELIX=true ;;
	esac
done <<<"$CHOICES"

if [ "$INSTALL_NEOVIM" = true ]; then
	spinner "Installing Neovim..."
	if sudo dnf install -y neovim; then
		pip install neovim
		npm instll -g neovim
		okay_message "Neovim installed."
	else
		warn_message "Failed to install Neovim. Check $LOG_FILE for details."
	fi
fi

if [ "$INSTALL_HELIX" = true ]; then
	spinner "Installing Helix..."
	bash ~/install/terminal/helix.sh
fi
