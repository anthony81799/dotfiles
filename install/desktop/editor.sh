#!/usr/bin/env bash
# ===============================================
# GUI Editor Installer (Optimized)
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library and initialize logging
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "${DOTFILES_DIR}/install/lib.sh"

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
INSTALL_CODIUM=false
INSTALL_ZED=false

# --- 2. Menu Selection ---
CHOICES=$(
	gum choose --no-limit \
		--header "Select editors to install" \
		"VS Code" \
		"VSCodium" \
		"Zed"
)

while IFS= read -r CHOICE; do
	case "$CHOICE" in
	"VS Code") INSTALL_CODE=true ;;
	"VSCodium") INSTALL_CODIUM=true ;;
	"Zed") INSTALL_ZED=true ;;
	esac
done <<<"$CHOICES"

# --- 3. VS Code Installation ---
if [ "$INSTALL_CODE" = true ]; then
	info_message "Starting Visual Studio Code installation..."

	VSCODE_REPO_FILE="/etc/yum.repos.d/vscode.repo"

	if [ ! -f "$VSCODE_REPO_FILE" ]; then
		info_message "Adding VS Code repository (GPG key and repo file)..."

		log "Importing Microsoft GPG key..."
		if ! sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc; then
			warn_message "Failed to import Microsoft GPG key. Installation may fail."
		fi

		sudo tee "$VSCODE_REPO_FILE" >/dev/null <<-EOF
		[code]
		name=Visual Studio Code
		baseurl=https://packages.microsoft.com/yumrepos/vscode
		enabled=1
		gpgcheck=1
		gpgkey=https://packages.microsoft.com/keys/microsoft.asc
		EOF
	else
		info_message "VS Code repository already configured: $VSCODE_REPO_FILE."
	fi

	if has_cmd code; then
		info_message "VS Code already installed. Skipping package installation."
	else
		info_message "Installing VS Code package ('code')..."
		if sudo dnf install -y code; then
			okay_message "VS Code installed successfully."
		else
			fail_message "Failed to install VS Code package. Check $LOG_FILE for details."
		fi
	fi
fi
# --- 4. VSCodium Installation ---
if [ "$INSTALL_CODIUM" = true ]; then
	info_message "Starting VSCodium installation..."

	VSCODIUM_REPO_FILE="/etc/yum.repos.d/vscodium.repo"

	if [ ! -f "$VSCODIUM_REPO_FILE" ]; then
		info_message "Adding VSCodium repository..."

		sudo tee "$VSCODIUM_REPO_FILE" >/dev/null <<-EOF
		[gitlab.com_paulcarroty_vscodium_repo]
		name=gitlab.com_paulcarroty_vscodium_repo
		baseurl=https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/rpms/
		enabled=1
		gpgcheck=1
		repo_gpgcheck=0
		gpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg
		metadata_expire=1h
		EOF
	else
		info_message "VSCodium repository already configured: $VSCODIUM_REPO_FILE."
	fi

	if has_cmd codium; then
		info_message "VSCodium already installed. Skipping package installation."
	else
		info_message "Installing VSCodium package ('codium')..."
		if sudo dnf install -y codium; then
			okay_message "VSCodium installed successfully."
		else
			fail_message "Failed to install VSCodium package. Check $LOG_FILE for details."
		fi
	fi
fi

# --- 5. Zed Editor Installation ---
if [ "$INSTALL_ZED" = true ]; then
	info_message "Starting Zed Editor installation..."

	if has_cmd zed; then
		info_message "Zed Editor is already installed. Skipping installation."
	else
		info_message "Downloading and executing Zed install script..."

		if curl -sSfL https://zed.dev/install.sh | sh; then
			okay_message "Zed Editor installed successfully."
		else
			fail_message "Failed to install Zed Editor via the official script. Check $LOG_FILE for details."
		fi
	fi
fi

finish "GUI Editor installation complete!"
