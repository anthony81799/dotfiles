#!/usr/bin/env bash
# ===============================================
# Editor Installer
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library and initialize logging
source "${HOME}/install/lib.sh"

LOG_FILE="${LOG_DIR}/editor.log"
init_log "$LOG_FILE"

ensure_gum

banner "Editor Installation"

INSTALL_CODE=false
INSTALL_ZED=false

# Step 1: Main menu for installation options
CHOICES=$(
    gum choose --no-limit \
        "Install VS Code" \
        "Install Zed"
)

# Parse choices
while IFS= read -r CHOICE; do
    case "$CHOICE" in
    "Install VS Code") INSTALL_CODE=true ;;
    "Install Zed") INSTALL_ZED=true ;;
    esac
done <<<"$CHOICES"

if [ "$INSTALL_CODE" = true ]; then
    spinner "Installing VS Code repository..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

    spinner "Installing VS Code..."
    sudo dnf check-update >/dev/null # Refresh cache
    if sudo dnf install -y code; then
        okay_message "VS Code installed."
    else
        warn_message "Failed to install VS Code. Check $LOG_FILE for details."
    fi
fi

if [ "$INSTALL_ZED" = true ]; then
    spinner "Installing Zed Editor..."
    curl -f https://zed.dev/install.sh | sh
fi
