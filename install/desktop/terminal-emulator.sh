#!/usr/bin/env bash
# ===============================================
# Terminal Emulator Installer
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library
source "${HOME}/install/lib.sh"

LOG_FILE="${LOG_DIR}/terminal-emulator-install.log"
init_log "$LOG_FILE"

ensure_gum

banner "Terminal Emulator Selection"

# --- 1. Terminal Selection Menu ---
TERMINAL_CHOICE=$(
	gum choose --header "Select your preferred terminal emulator to install" \
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

TERMINAL_NAME="${TERMINAL_CHOICE%% *}"

# --- 2. Installation Logic ---
case "$TERMINAL_NAME" in
"Alacritty")
	info_message "Installing Alacritty..."
	sudo dnf install -y alacritty || {
		fail_message "Failed to install Alacritty."
	}
	okay_message "Alacritty installed."
	;;
"Kitty")
	info "Installing Kitty..."
	sudo dnf install -y kitty || {
		fail_message "Failed to install Kitty."
	}
	okay_message "Kitty installed."
	;;
"WezTerm")
	info_message "Enabling WezTerm Copr..."
	sudo dnf copr enable -y wezfurlong/wezterm-nightly

	info_message "Installing WezTerm..."
	sudo dnf install -y wezterm || {
		fail_message "Failed to install WezTerm."
	}
	okay_message "WezTerm installed."
	;;
"Ghostty")
	info_message "Enasbling Ghostty Copr..."
	sudo dnf copr enable -y scottames/ghostty &&

	info_message "Installing Ghostty..."
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
