#!/usr/bin/env bash
# ===============================================
# Desktop Environment (Hyprland) installer
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library and initialize logging
source "${HOME}/install/lib.sh"

LOG_FILE="${LOG_DIR}/desktop-install.log"
init_log "$LOG_FILE"

ensure_gum

spinner "Starting desktop installation..."

# -------------------------------------------------------------
# --- 1. NVIDIA Driver Installation ---
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
# --- 2. Install Bazzite Gaming Features ---
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
    sudo systemctl enable --now xone@"$USER" || true
fi

okay_message "Gaming features installed successfully."

# -------------------------------------------------------------
# --- 3. Nobara/Performance Tweaks ---
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

# ------------------------------------------------------------
# --- 4. Btrfs Snapshot Setup (Snapper) ---
# ------------------------------------------------------------
spinner "Setting up Btrfs snapshots with Snapper..."

# Check if the root filesystem is Btrfs
if df -t btrfs / >/dev/null 2>&1; then
    log "Btrfs root filesystem detected. Proceeding with snapper setup."

    # 1. Create the default snapper configuration for the root filesystem
    if ! sudo snapper -c root create-config /; then
        warn_message "Failed to create default snapper configuration for /. Snapper setup may require manual intervention (e.g., if / is not a proper BTRFS subvolume)."
    else
        # 2. Enable snapper services
        spinner "Enabling snapper timeline and cleanup timer services..."

        # snapper-timeline.timer creates hourly snapshots
        sudo systemctl enable --now snapper-timeline.timer || true

        # snapper-cleanup.timer cleans up old snapshots according to config
        sudo systemctl enable --now snapper-cleanup.timer || true

        okay_message "Btrfs snapshots (Snapper) configured. Timers are now active."
    fi
else
    info_message "Root filesystem is not Btrfs. Btrfs snapshot setup skipped."
fi

# -----------------------------------------------------------------
# --- 5. Set up Hyprland for Automatic Login (via SDDM) ---
# Replicates the omarchy robust autologin setup using config snippets.
# -----------------------------------------------------------------
spinner "Configuring SDDM for automatic login to Hyprland..."

if has_cmd sddm && [ -f "/usr/lib/systemd/system/sddm.service" ]; then

    # Disable and mask GDM or other potential conflicts for robustness
    if has_cmd gdm; then
        log "Disabling and masking gdm.service to prevent conflict."
        sudo systemctl disable gdm --now || true
        sudo systemctl mask gdm || true
    fi

    # Configure SDDM for automatic login using the recommended snippet approach
    log "Creating SDDM configuration snippet file for autologin: /etc/sddm.conf.d/autologin.conf"

    # Ensure the snippet directory exists
    sudo mkdir -p /etc/sddm.conf.d

    USERNAME=$(whoami)

    # Write the configuration to the snippet file
    sudo tee /etc/sddm.conf.d/autologin.conf >/dev/null <<EOF
[Autologin]
User=$USERNAME
# Use the uwsm-managed Hyprland session
Session=hyprland-uwsm.desktop

[Wayland]
EnableHiDPI=true

[General]
# DisplayServerWait=3
EOF

    # Ensure the main SDDM service is enabled and started
    spinner "Enabling and starting SDDM service..."
    sudo systemctl enable sddm --now || {
        warn_message "Failed to enable sddm.service. You may need to check the logs and start it manually."
    }

    okay_message "SDDM configured for automatic login using the Hyprland session."

else
    warn_message "SDDM or its service file not found. Automatic login not configured."
fi

# -------------------------------------------------------------
# --- 6. Skip GRUB Menu Prompt ---
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
