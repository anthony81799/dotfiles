#!/usr/bin/env bash
# ===============================================
# GUI Editor Installer (Optimized)
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library and initialize logging
source "${HOME}/install/lib.sh"

LOG_FILE="${LOG_DIR}/gui-editor.log"
init_log "$LOG_FILE"

ensure_gum

banner "GUI Editor Installation"

# --- 1. Dependency Checks ---
# Ensure essential system utilities are present
if ! has_cmd curl; then
	fail_message "Required command 'curl' not found. Aborting."
fi

INSTALL_CODE=false
INSTALL_ZED=false

# --- 2. Menu Selection ---
CHOICES=$(
	gum choose --no-limit \
		--header "Select editors to install" \
		"VS Code" \
		"Zed"
)

while IFS= read -r CHOICE; do
	case "$CHOICE" in
	"VS Code") INSTALL_CODE=true ;;
	"Zed") INSTALL_ZED=true ;;
	esac
done <<<"$CHOICES"

# --- 3. VS Code Installation ---
if [ "$INSTALL_CODE" = true ]; then
	info_message "Starting Visual Studio Code installation..."

	VSCODE_REPO_FILE="/etc/yum.repos.d/vscode.repo"

	if [ ! -f "$VSCODE_REPO_FILE" ]; then
		spinner "Adding VS Code repository (GPG key and repo file)..."

		log "Importing Microsoft GPG key..."
		if ! sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc; then
			warn_message "Failed to import Microsoft GPG key. Installation may fail."
		fi

		REPO_CONTENT="[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc"
		if echo -e "$REPO_CONTENT" | sudo tee "$VSCODE_REPO_FILE" >/dev/null; then
			okay_message "VS Code repository configured."
		else
			fail_message "Failed to create VS Code repository file: $VSCODE_REPO_FILE. Aborting VS Code install."
			# Continue to Zed if selected, otherwise script continues to finish.
		fi
	else
		info_message "VS Code repository already configured: $VSCODE_REPO_FILE."
	fi

	if has_cmd code; then
		info_message "VS Code already installed. Skipping package installation."
	else
		spinner "Installing VS Code package ('code')..."
		sudo dnf clean all >/dev/null
		if sudo dnf install -y code; then
			okay_message "VS Code installed successfully."
		else
			fail_message "Failed to install VS Code package. Check $LOG_FILE for details."
		fi
	fi
fi

# --- 4. Zed Editor Installation ---
if [ "$INSTALL_ZED" = true ]; then
	info_message "Starting Zed Editor installation..."

	if has_cmd zed; then
		info_message "Zed Editor is already installed. Skipping installation."
	else
		spinner "Downloading and executing Zed install script..."

		if curl -sSfL https://zed.dev/install.sh | sh; then
			okay_message "Zed Editor installed successfully."
		else
			fail_message "Failed to install Zed Editor via the official script. Check $LOG_FILE for details."
		fi
	fi
fi

finish "GUI Editor installation complete!"
