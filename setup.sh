#!/usr/bin/env bash
# ===============================================
# Desktop Environment (Hyprland) setup
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library and initialize logging
source "${HOME}/install/lib.sh"

# 💡 Logging setup: This ensures log messages go to a file (FD 6) and STDOUT/STDERR are free for gum.
LOG_FILE="${LOG_DIR}/setup.log"
init_log "$LOG_FILE"

ensure_gum

spinner "Starting Hyprland and omadora installation..."

# -------------------------------------------------------------
# --- 1. DNF Performance Tweaks ---
# -------------------------------------------------------------
spinner "Optimizing DNF configuration for faster downloads..."

DNF_CONFIG="/etc/dnf/dnf.conf"

if [ -f "$DNF_CONFIG" ]; then
    log "Updating $DNF_CONFIG under [main]."

    # 1. Delete existing lines to prevent duplicates
    sudo sed -i '/^gpgcheck=/d' "$DNF_CONFIG"
    sudo sed -i '/^installonly_limit=/d' "$DNF_CONFIG"
    sudo sed -i '/^clean_requirements_on_remove=/d' "$DNF_CONFIG"
    sudo sed -i '/^max_parallel_downloads=/d' "$DNF_CONFIG"
    sudo sed -i '/^fastestmirror=/d' "$DNF_CONFIG"
    sudo sed -i '/^skip_if_unavailable=/d' "$DNF_CONFIG"
    sudo sed -i '/^defaultyes=/d' "$DNF_CONFIG"

    # 2. Insert new lines immediately after [main] using 'a' (append) command
    # This ensures they are correctly placed within the [main] block.
    sudo sed -i '/\[main\]/a gpgcheck=0' "$DNF_CONFIG"
    sudo sed -i '/\[main\]/a installonly_limit=3' "$DNF_CONFIG"
    sudo sed -i '/\[main\]/a clean_requirements_on_remove=True' "$DNF_CONFIG"
    sudo sed -i '/\[main\]/a max_parallel_downloads=10' "$DNF_CONFIG"
    sudo sed -i '/\[main\]/a fastestmirror=True' "$DNF_CONFIG"
    sudo sed -i '/\[main\]/a skip_if_unavailable=True' "$DNF_CONFIG"
    sudo sed -i '/\[main\]/a defaultyes=True' "$DNF_CONFIG"

    okay_message "DNF optimized for faster downloads."
else
    warn_message "DNF configuration file ($DNF_CONFIG) not found. Skipping DNF optimization."
fi

# -------------------------------------------------------------
# --- 2. Omadora Installation ---
# -------------------------------------------------------------
# --- 2a. Install Core Dependencies ---
log "Installing core Wayland/build dependencies and utilities..."

# Consolidate core dependencies: Hyprland build tools (Meson, Ninja), uwsm, sddm, grub2
spinner "Installing core dependencies (Wayland, build tools, SDDM, GRUB)..." -- sudo dnf install -y \
    git \
    sddm || {
    fail_message "Failed to install core dependencies. Check $LOG_FILE for details."
    exit 1
}
okay_message "Core dependencies installed successfully."

# --- 2b. Install omadora ---
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

bash "$OMADORA_DIR"/install.sh || {
    fail_message "Failed to build and install omadora. Check $LOG_FILE for details."
    exit 1
}
okay_message "omadora installed."

finish "Initail setup is complete! You can now reboot and run ./install/install.sh to finish setting up your dotfiles and terminal environment."
