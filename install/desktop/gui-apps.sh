#!/usr/bin/env bash
# ===============================================
# GUI Applications Installer
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library and initialize logging
source "${HOME}/install/lib.sh"

LOG_FILE="${LOG_DIR}/gui-apps-install.log"
init_log "$LOG_FILE"

ensure_gum

banner "GUI Applications Installation"

# ------------------------------------------------------------
# --- 1. Install Dolphin File Manager (DNF/Official) ---
# ------------------------------------------------------------
spinner "Installing Dolphin File Manager..."
if sudo dnf install -y dolphin; then
    okay_message "Dolphin installed."
else
    warn_message "Failed to install Dolphin. Check $LOG_FILE for details."
fi

# ------------------------------------------------------------
# --- 2. Install VS Code (Official RPM/Repo) ---
# ------------------------------------------------------------
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

# ------------------------------------------------------------
# --- 3. Install Brave Browser (Official RPM/Repo) ---
# ------------------------------------------------------------
spinner "Installing Brave Browser repository..."
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

# Set as default only if installed successfully
if [ "$BRAVE_INSTALLED" = true ]; then
    # Set the default handler for x-scheme-handler/http and x-scheme-handler/https
    if xdg-settings set default-web-browser brave-browser.desktop; then
        okay_message "Brave Browser set as default web browser."
    else
        warn_message "Failed to set Brave Browser as default using xdg-settings. This may require an active graphical session or manual setting."
    fi
fi

# ------------------------------------------------------------
# --- 4. Install Zed Editor
# ------------------------------------------------------------
spinner "Installing Zed Editor..."
curl -f https://zed.dev/install.sh | sh

# ------------------------------------------------------------
# --- 5. Install Thunderbird Email Client (DNF/Official) ---
# ------------------------------------------------------------
spinner "Installing Thunderbird..."
if sudo dnf install -y thunderbird; then
    okay_message "Thunderbird installed."
else
    warn_message "Failed to install thunderbird. Check $LOG_FILE for details."
fi

# ------------------------------------------------------------
# --- 5. Install LocalSend File Sharing (Flathub - Recommended) ---
# ------------------------------------------------------------
if has_cmd flatpak; then
    spinner "Installing LocalSend via Flatpak..."
    # Ensure Flathub is enabled
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    # Install LocalSend
    if flatpak install flathub org.localsend.localsend_app -y; then
        okay_message "LocalSend (Flatpak) installed."
    else
        warn_message "Failed to install LocalSend via Flatpak. Check $LOG_FILE for details."
    fi
else
    warn_message "Flatpak not installed. Skipping LocalSend installation. Install Flatpak/LocalSend manually."
fi

# ------------------------------------------------------------
# --- 6. Install Discord (DNF - RPMFusion) ---
# ------------------------------------------------------------
spinner "Installing Discord via Flatpak..."
sudo dnf install -y discord || {
    warn_message "Failed to install Discord. Check $LOG_FILE for details."
}

finish "GUI Applications installation complete."
