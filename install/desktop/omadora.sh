#!/usr/bin/env bash
# ===============================================
# Omadoera Installation
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library and initialize logging
source "${HOME}/install/lib.sh"

LOG_FILE="${LOG_DIR}/install-omadora.log"
init_log "$LOG_FILE"

ensure_gum

banner "Installing Omadora. This is just the initail setup! If you desire a full desktop installation after the system restarts run ./install/install.sh."

# --- 1a. Install Core Dependencies ---
log "Installing core Wayland/build dependencies and utilities..."

# Consolidate core dependencies: Hyprland build tools (Meson, Ninja), uwsm, sddm, grub2
spinner "Installing core dependencies (Wayland, build tools, SDDM, GRUB)..."
sudo dnf install -y \
    snapper \
    perl-Time-HiRes \
    sddm || {
    fail_message "Failed to install core dependencies. Check $LOG_FILE for details."
}
okay_message "Core dependencies installed successfully."

# --- 1b. Install omadora ---
OMADORA_REPO="https://github.com/elpritchos/omadora.git"
OMADORA_DIR="${XDG_DATA_HOME}/omadora"

log "Cloning and building omadora from $OMADORA_REPO"

if [ -d "$OMADORA_DIR" ]; then
    spinner "Updating omadora repository..."
    cd "$OMADORA_DIR"
    git pull --rebase
else
    spinner "Cloning omadora repository..."
    git clone "$OMADORA_REPO" "$OMADORA_DIR"
    cd "$OMADORA_DIR"
fi

spinner "Building and installing omadora..."

bash "$OMADORA_DIR"/install.sh || {
    fail_message "Failed to build and install omadora. Check $LOG_FILE for details."
}

finish "omadora installed!"
