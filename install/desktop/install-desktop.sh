#!/usr/bin/env bash
# ===============================================
# Desktop Environment (Hyprland) installer
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library and initialize logging
source "${HOME}/install/lib.sh"

# 💡 Logging setup: This ensures log messages go to a file (FD 6) and STDOUT/STDERR are free for gum.
LOG_FILE="${LOG_DIR}/desktop-install.log"
init_log "$LOG_FILE"

ensure_gum

spinner "Starting Hyprland and omadora installation..."

# --- 1. Install Dependencies for Hyprland and omadora ---
log "Installing required Wayland/build dependencies..."

# Hyprland and build dependencies for Wayland components
spinner "Installing Wayland and build dependencies (Hyprland, uwsm, Meson, etc.)..." -- sudo dnf install -y \
    git || {
    fail_message "Failed to install required dependencies. Check $LOG_FILE for details."
    exit 1
}
okay_message "Dependencies installed successfully."

# --- 2. Install omadora ---
OMADORA_REPO="https://github.com/elpritchos/omadora.git"
OMADORA_DIR="${XDG_DATA_HOME}/omadora"

log "Cloning and building omadora from $OMADORA_REPO"

if [ -d "$OMADORA_DIR" ]; then
    spinner "Updating omadora repository..."
    cd "$OMADORA_DIR" || exit 1
    git pull --rebase
else
    spinner "Cloning omadora repository..."
    git clone "$OMADORA_REPO" "$OMADORA_DIR"
    cd "$OMADORA_DIR" || exit 1
fi

spinner "Building and installing omadora..."
# Omadoara is built using Meson/Ninja, typical for Wayland projects
bash "$OMADORA_DIR"/install.sh || {
    fail_message "Failed to build and install omadora. Check $LOG_FILE for details."
    exit 1
}

okay_message "omadora installed to ${HOME}/.local/."

# --- 3. Set up Hyprland for Automatic Login (via SDDM) ---
# We will use SDDM, a common and robust display manager for Wayland, for auto-login.

spinner "Configuring SDDM for automatic login to Hyprland..."

# Check if SDDM is installed and the service exists
spinner "Installing automatic login dependencies (Hyprland, uwsm, Meson, etc.)..." -- sudo dnf install -y \
    sddm || {
    fail_message "Failed to install required dependencies. Check $LOG_FILE for details."
    exit 1
}
okay_message "Dependencies installed successfully."

if has_cmd sddm && [ -f "/usr/lib/systemd/system/sddm.service" ]; then

    # 3a. Ensure Hyprland session file exists (needed for SDDM to detect the session)
    if [ ! -f "/usr/share/wayland-sessions/hyprland.desktop" ]; then
        log "Creating basic hyprland.desktop session file."
        sudo tee /usr/share/wayland-sessions/hyprland.desktop >/dev/null <<EOF
[Desktop Entry]
Name=Hyprland
Comment=An experimental Wayland compositor
Exec=Hyprland
Type=Application
EOF
    fi

    # 3b. Configure SDDM for automatic login
    log "Creating SDDM configuration file for autologin."
    USERNAME=$(whoami)
    sudo tee /etc/sddm.conf >/dev/null <<EOF
[Autologin]
User=$USERNAME
Session=Hyprland

[General]
# If you are dual-booting or need a delay, uncomment and set a value
# DisplayServerWait=3

[Wayland]
EnableHiDPI=true
EOF

    # 3c. Enable the SDDM service
    spinner "Enabling SDDM service..."
    sudo systemctl enable sddm || {
        warn_message "Failed to enable sddm.service. You may need to start it manually."
    }

    okay_message "SDDM configured for automatic login using the Hyprland session."
else
    warn_message "SDDM or its service file not found. Automatic login not configured."
fi

finish "Desktop setup (omadora/Hyprland) complete! A reboot is required for auto-login to take effect."
