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

# -------------------------------------------------------------
# --- 1. DNF Performance Tweaks ---
# -------------------------------------------------------------
spinner "Optimizing DNF configuration for faster downloads..."

DNF_CONFIG="/etc/dnf/dnf.conf"

if [ -f "$DNF_CONFIG" ]; then
    log "Updating $DNF_CONFIG to set max_parallel_downloads and enable fastestmirror."

    # Set to a high number for parallel downloads
    sudo sed -i '/^max_parallel_downloads=/d' "$DNF_CONFIG"
    sudo sed -i '1i max_parallel_downloads=10' "$DNF_CONFIG"

    # Enable the fastest mirror plugin
    sudo sed -i '/^fastestmirror=/d' "$DNF_CONFIG"
    sudo sed -i '1i fastestmirror=True' "$DNF_CONFIG"

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

# -------------------------------------------------------------
# --- 3. NVIDIA Driver Installation ---
# -------------------------------------------------------------
spinner "Adding RPMFusion..."
sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

sudo dnf update -y

if gum confirm "Do you want to install NVIDIA drivers from RPMFusion?"; then
    spinner "Installing NVIDIA drivers and Vulkan dependencies..."

    # Core packages for dnf/akmod setup (Requires RPMFusion to be enabled)
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda \
        vulkan-loader vulkan-loader.i686 || {
        fail_message "Failed to install NVIDIA drivers. Check $LOG_FILE for details."
    }

    okay_message "NVIDIA drivers installed. The kernel module will build on the next reboot."
else
    info_message "NVIDIA driver installation skipped."
fi

# -------------------------------------------------------------
# --- 4. Install Bazzite Gaming Features ---
# -------------------------------------------------------------
spinner "Installing common Bazzite/Gaming features (Gamescope, Launchers, Controller support)..."

# General gaming dependencies (gamescope, steam, controller support tools)
sudo dnf install -y \
    gamescope \
    steam \
    xone \
    xpad \
    steam-devices \
    mesa-vulkan-drivers \
    mesa-vulkan-drivers.i686 \
    pipewire-alsa \
    pipewire-jack \
    libvulkan.i686 \
    vulkan-tools || {
    warn_message "Some gaming dependencies failed to install. Continuing..."
}

# Enable xone for Xbox controllers (requires a reboot)
if has_cmd xone; then
    sudo systemctl enable --now xone@"$USER" || true
fi

okay_message "Gaming features installed successfully."

# -------------------------------------------------------------
# --- 5. Nobara/Performance Tweaks ---
# -------------------------------------------------------------
spinner "Applying system performance and scheduling tweaks (like Nobara's modifications)..."

# Install irqbalance for better CPU resource distribution
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

# -------------------------------------------------------------
# --- 6. Set up Hyprland for Automatic Login (via SDDM) ---
# -------------------------------------------------------------
spinner "Configuring SDDM for automatic login to Hyprland..."

if has_cmd sddm && [ -f "/usr/lib/systemd/system/sddm.service" ]; then

    # Configure SDDM for automatic login
    log "Creating SDDM configuration file for autologin."
    USERNAME=$(whoami)
    sudo tee /etc/sddm.conf >/dev/null <<EOF
[Autologin]
User=$USERNAME
# Use the uwsm-managed session
Session=hyprland-uwsm.desktop

[General]
# DisplayServerWait=3

[Wayland]
EnableHiDPI=true
EOF

    # Enable the SDDM service
    spinner "Enabling SDDM service..."
    sudo systemctl enable sddm || {
        warn_message "Failed to enable sddm.service. You may need to start it manually."
    }

    okay_message "SDDM configured for automatic login using the Hyprland session."
else
    warn_message "SDDM or its service file not found. Automatic login not configured."
fi

# -------------------------------------------------------------
# --- 7. Skip GRUB Menu Prompt ---
# -------------------------------------------------------------
spinner "Configuring GRUB to skip the menu prompt (auto-select first entry)..."

GRUB_CONFIG="/etc/default/grub"

if [ -f "$GRUB_CONFIG" ]; then
    log "Updating $GRUB_CONFIG: Setting GRUB_TIMEOUT=0 and GRUB_TIMEOUT_STYLE=hidden."

    # Set the timeout to 0 (no delay)
    sudo sed -i 's/^GRUB_TIMEOUT=[0-9]*$/GRUB_TIMEOUT=0/' "$GRUB_CONFIG"

    # Hide the prompt entirely
    if ! grep -q '^GRUB_TIMEOUT_STYLE=' "$GRUB_CONFIG"; then
        sudo echo 'GRUB_TIMEOUT_STYLE=hidden' | sudo tee -a "$GRUB_CONFIG" >/dev/null
    else
        sudo sed -i 's/^GRUB_TIMEOUT_STYLE=.*$/GRUB_TIMEOUT_STYLE=hidden/' "$GRUB_CONFIG"
    fi

    # Apply changes
    spinner "Applying new GRUB configuration..."
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg || {
        fail_message "Failed to update GRUB configuration. Check $LOG_FILE for details."
        warn_message "You may need to run 'sudo grub2-mkconfig -o /boot/grub2/grub.cfg' manually."
    }
    okay_message "GRUB configured to boot the first entry instantly."
else
    warn_message "GRUB configuration file ($GRUB_CONFIG) not found. Skipping auto-skip configuration."
fi

finish "Desktop setup (omadora/Hyprland) complete! A reboot is required for all changes to take full effect."
