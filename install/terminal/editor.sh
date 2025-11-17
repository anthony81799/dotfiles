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

# --- Functions ---
install_neovim() {
	banner "Neovim Installation"

	spinner "Installing Neovim via DNF..."
	sudo dnf install -y neovim || {
		fail_message "Failed to install Neovim via DNF. Check $LOG_FILE for details."
	}

	# 2. Install optional Python client (for providers)
	if has_cmd pip; then
		spinner "Installing Python Neovim client (pip install neovim)..."
		pip install --break-system-packages neovim || {
			warn_message "Failed to install Python Neovim client. Proceeding."
		}
	else
		info_message "pip not found. Skipping Python Neovim client install."
	fi

	# 3. Install optional Node.js client (for providers/LSPs)
	if has_cmd npm; then
		spinner "Installing Node.js Neovim client (npm install -g neovim)..."
		sudo npm install -g neovim || {
			warn_message "Failed to install Node.js Neovim client. Proceeding."
		}
	else
		info_message "npm not found. Skipping Node.js Neovim client install."
	fi

	okay_message "Neovim installed and clients configured."
}

install_helix() {
	banner "Helix Editor Installation"

	spinner "Running Helix installation script: ~/install/terminal/helix.sh"
	bash "${HOME}/install/terminal/helix.sh" || {
		fail_message "Helix installation script failed. Check $LOG_FILE for details."
	}
	okay_message "Helix installed successfully."
}

# --- Step 1: Main menu for installation options ---
CHOICES=$(
	gum choose --no-limit \
		--header "Select editors to install" \
		"Neovim" \
		"Helix"
)

while IFS= read -r CHOICE; do
	case "$CHOICE" in
	"Neovim") INSTALL_NEOVIM=true ;;
	"Helix") INSTALL_HELIX=true ;;
	esac
done <<<"$CHOICES"

# --- Step 2: Execution ---
if [ "$INSTALL_NEOVIM" = true ]; then
	install_neovim
fi

if [ "$INSTALL_HELIX" = true ]; then
	install_helix
fi

finish "Terminal editor setup complete."
