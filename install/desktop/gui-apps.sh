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
sudo dnf install -y dolphin || {
    warn_message "Failed to install Dolphin. Check $LOG_FILE for details."
}
okay_message "Dolphin installed."

# ------------------------------------------------------------
# --- 2. Install VS Code (Official RPM/Repo) ---
# ------------------------------------------------------------
spinner "Installing VS Code repository..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

spinner "Installing VS Code..."
sudo dnf check-update >/dev/null # Refresh cache
sudo dnf install -y code || {
    warn_message "Failed to install VS Code. Check $LOG_FILE for details."
}
okay_message "VS Code installed."

# ------------------------------------------------------------
# --- 3. Install Brave Browser (Official RPM/Repo) ---
# ------------------------------------------------------------
spinner "Installing Brave Browser repository..."
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo

spinner "Installing Brave Browser..."
sudo dnf check-update >/dev/null # Refresh cache
sudo dnf install -y brave-browser || {
    warn_message "Failed to install Brave Browser. Check $LOG_FILE for details."
}
okay_message "Brave Browser installed."

# set Brave as default browser
# The desktop file name for Brave is typically brave-browser.desktop
spinner "Setting Brave Browser as the default web browser..."
# Set the default handler for x-scheme-handler/http and x-scheme-handler/https
xdg-settings set default-web-browser brave-browser.desktop || {
    warn_message "Failed to set Brave Browser as default using xdg-settings. This may require an active graphical session or manual setting."
}
okay_message "Attempted to set Brave Browser as default."

# ------------------------------------------------------------
# --- 4. Install Zed Editor (Flathub - Recommended) ---
# ------------------------------------------------------------
sudo dnf install flatpak
if has_cmd flatpak; then
    spinner "Installing Zed Editor via Flatpak..."
    # Ensure Flathub is enabled
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    # Install Zed
    flatpak install flathub dev.zed.Zed -y || {
        warn_message "Failed to install Zed Editor via Flatpak. Check $LOG_FILE for details."
    }
    okay_message "Zed Editor (Flatpak) installed."
else
    warn_message "Flatpak not installed. Skipping Zed Editor installation. Install Flatpak/Zed manually."
fi

# ------------------------------------------------------------
# --- 5. Install Thunderbird Email Client (DNF/Official) ---
# ------------------------------------------------------------
spinner "Installing Thunderbird..."
sudo dnf install -y thunderbird || {
    warn_message "Failed to install thunderbird. Check $LOG_FILE for details."
}
okay_message "Thunderbird installed."

finish "GUI Applications installation complete."
