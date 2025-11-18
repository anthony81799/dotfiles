#!/usr/bin/env bash
# ===============================================
# Terminal Emulator Installer
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library
source "${HOME}/install/lib.sh"

init_log "${LOG_DIR}/terminal-emulator-install.log"

ensure_gum

banner "Terminal Emulator Selection"

# --- 1. Terminal Selection Menu ---
TERMINAL_CHOICE=$(
	gum choose --no-limit \
		--header "Select your preferred terminal emulator to install" \
		"Alacritty" \
		"Kitty" \
		"WezTerm" \
		"Ghostty" \
		"Skip (Do not install a terminal emulator)"
)

if [[ "$TERMINAL_CHOICE" == "Skip (Do not install a terminal emulator)" ]]; then
	info_message "Terminal emulator installation skipped."
	finish "Terminal emulator setup complete."
fi

TERMINAL_NAME=$(echo "$TERMINAL_CHOICE" | awk '{print $1}')

# --- 2. Installation Logic ---
case "$TERMINAL_NAME" in
"Alacritty")
	spinner "Installing Alacritty..."
	sudo dnf install -y alacritty || {
		fail_message "Failed to install Alacritty."
	}
	okay_message "Alacritty installed."
	;;
"Kitty")
	spinner "Installing Kitty..."
	sudo dnf install -y kitty || {
		fail_message "Failed to install Kitty."
	}
	okay_message "Kitty installed."
	;;
"WezTerm")
	spinner "Installing WezTerm..."
	sudo dnf copr enable -y wezfurlong/wezterm-nightly
	sudo dnf install -y wezterm || {
		fail_message "Failed to install WezTerm."
	}
	okay_message "WezTerm installed."
	;;
"Ghostty")
	sudo dnf copr enable -y scottames/ghostty
	sudo dnf install -y ghostty || {
		fail_message "Failed to install Ghostty."
	}
	okay_message "Ghostty installed."
	;;
*)
	fail_message "Invalid selection: $TERMINAL_CHOICE"
	;;
esac

finish "Terminal emulator setup complete."
