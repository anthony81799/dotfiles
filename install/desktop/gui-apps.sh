#!/usr/bin/env bash
# ===============================================
# GUI Applications Installer (Optimized)
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library and initialize logging
source "${HOME}/install/lib.sh"

LOG_FILE="${LOG_DIR}/gui-apps-install.log"
init_log "$LOG_FILE"

ensure_gum

banner "GUI Applications Installation"

# --- 1. DNF Package Installation ---
DNF_PACKAGES=(
	"dolphin"          # Dolphin File Manager
	"thunderbird"      # Thunderbird Email Client
	"discord"          # Discord
	"dnf-plugins-core" # Required for config-manager used in Brave setup
	"xdg-utils"        # Required for xdg-settings
)

spinner "Installing core GUI applications..."
if ! sudo dnf install -y "${DNF_PACKAGES[@]}"; then
	warn_message "Some core DNF packages failed to install. Check $LOG_FILE for details."
else
	okay_message "Core GUI applications installed successfully."
fi

# --- 2. Brave Browser Installation ---
if ! has_cmd brave-browser; then
	info_message "Starting Brave Browser installation..."

	sudo dnf install -y dnf-plugins-core
	sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo

	BRAVE_INSTALLED=false
	spinner "Installing Brave Browser..."
	if sudo dnf install -y brave-browser; then
		BRAVE_INSTALLED=true
		okay_message "Brave Browser installed."
	else
		warn_message "Failed to install Brave Browser. Check $LOG_FILE for details."
	fi
else
	info_message "Brave Browser already installed."
	BRAVE_INSTALLED=true
fi

if [ "${BRAVE_INSTALLED:-false}" = true ]; then
	spinner "Attempting to set Brave Browser as default web browser..."
	if has_cmd xdg-settings; then
		if xdg-settings set default-web-browser brave-browser.desktop; then
			okay_message "Brave Browser set as default web browser."
		else
			warn_message "Failed to set Brave Browser as default using xdg-settings (requires active graphical session)."
		fi
	else
		warn_message "xdg-settings not found. Cannot set Brave Browser as default."
	fi
fi

# --- 3. LocalSend File Sharing ---
if has_cmd flatpak; then
	if ! flatpak list | grep -q 'org.localsend.localsend_app'; then
		spinner "Installing LocalSend via Flatpak..."

		if sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
			if flatpak install flathub org.localsend.localsend_app -y; then
				okay_message "LocalSend (Flatpak) installed."
			else
				warn_message "Failed to install LocalSend via Flatpak. Check $LOG_FILE for details."
			fi
		else
			warn_message "Failed to add Flathub repository. Skipping LocalSend installation."
		fi
	else
		info_message "LocalSend (Flatpak) is already installed."
	fi
else
	warn_message "Flatpak not installed. Skipping LocalSend installation. Please install Flatpak/LocalSend manually."
fi

# --- 4. Call Helper Scripts for GUI Editors ---
EDITOR_SCRIPT="${HOME}/install/desktop/editor.sh"
TERMINAL_SCRIPT="${HOME}/install/desktop/terminal-emulator.sh"

# Run editor script
if [ -x "$EDITOR_SCRIPT" ]; then
	spinner "Running GUI Editor setup script ($EDITOR_SCRIPT)..."
	if bash "$EDITOR_SCRIPT"; then
		okay_message "GUI Editor setup completed."
	else
		warn_message "GUI Editor setup script failed."
	fi
else
	warn_message "GUI Editor script not found or not executable: $EDITOR_SCRIPT. Skipping."
fi

if [ -x "$TERMINAL_SCRIPT" ]; then
	spinner "Running Terminal Emulator setup script ($TERMINAL_SCRIPT)..."
	if bash "$TERMINAL_SCRIPT"; then
		okay_message "Terminal Emulator setup completed."
	else
		warn_message "Terminal Emulator setup script failed."
	fi
else
	warn_message "Terminal Emulator script not found or not executable: $TERMINAL_SCRIPT. Skipping."
fi

finish "GUI Applications installation complete."
