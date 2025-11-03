#!/usr/bin/env bash
# ===============================================
# Bazzite Gaming Features & Nobara/Performance Tweaks
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library and initialize logging
source "${HOME}/install/lib.sh"
LOG_FILE="${LOG_DIR}/install-gaming-tweaks.log"

init_log "$LOG_FILE"

ensure_gum

banner "Gaming Features and Performance Tweaks"

# -------------------------------------------------------------
# --- 1. Install Bazzite Gaming Features ---
# -------------------------------------------------------------
spinner "Installing common Bazzite/Gaming features (Gamescope, Launchers, Controller support)..."

# General gaming dependencies (gamescope, steam, controller support tools)
sudo dnf install -y \
    gamescope \
    steam \
    xpad \
    steam-devices \
    mesa-vulkan-drivers \
    mesa-vulkan-drivers.i686 \
    pipewire-alsa \
    pipewire-jack-audio-connection-kit \
    vulkan-loader \
    vulkan-tools || {
    warn_message "Some gaming dependencies failed to install. Continuing..."
}

# Enable xone for Xbox controllers (requires a reboot)
if has_cmd xone; then
    spinner "Enabling xone service for Xbox controllers..."
    sudo systemctl enable --now xone@"$USER" || true
fi

okay_message "Gaming features installed successfully."

# -------------------------------------------------------------
# --- 2. Nobara/Performance Tweaks ---
# -------------------------------------------------------------
spinner "Applying system performance and scheduling tweaks (like Nobara's modifications)..."

# Install irqbalance for better CPU resource distribution
spinner "Installing irqbalance..."
sudo dnf install -y irqbalance
sudo systemctl enable --now irqbalance

# Apply common performance sysctl settings (requires root)
log "Applying kernel sysctl tweaks for improved I/O and latency."
sudo tee /etc/sysctl.d/99-performance-tweaks.conf >/dev/null <<EOF
# Increase inotify limits for applications like VS Code, IDEs
fs.inotify.max_user_watches = 524288
# Reduce swappiness for better desktop responsiveness
vm.swappiness = 10
EOF

# Load the new sysctl settings immediately
sudo sysctl -p /etc/sysctl.d/99-performance-tweaks.conf || true

okay_message "System performance tweaks applied. Full effect requires a reboot."

finish "Gaming and performance setup complete."
