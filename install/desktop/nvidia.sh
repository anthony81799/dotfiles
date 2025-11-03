#!/usr/bin/env bash
# ===============================================
# NVIDIA Driver Installation
# ===============================================
set -euo pipefail
IFS=$'\n\t'

source "${HOME}/install/lib.sh"
LOG_FILE="${LOG_DIR}/install-nvidia.log"

init_log "$LOG_FILE"

ensure_gum

banner "NVIDIA Driver and RPMFusion Setup"

spinner "Adding RPMFusion repositories..."
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
        exit 1
    }

    okay_message "NVIDIA drivers installed. The kernel module will build on the next reboot."
else
    info_message "NVIDIA driver installation skipped."
fi

finish "NVIDIA driver installation step complete."
