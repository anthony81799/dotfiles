#!/usr/bin/env bash
# ===============================================
# Btrfs Snapshot Setup (Snapper)
# ===============================================
set -euo pipefail
IFS=$'\n\t'

source "${HOME}/install/lib.sh"

LOG_FILE="${LOG_DIR}/setup-snapper.log"

init_log "$LOG_FILE"

ensure_gum

banner "Snapper (Btrfs Snapshot) Setup"

# Check if the root filesystem is Btrfs
if ! findmnt -n -o FSTYPE / | grep -q 'btrfs'; then
    info_message "Root filesystem is not Btrfs. Skipping Snapper setup."
    exit 0
fi

if gum confirm "Do you want to install and configure Snapper for Btrfs snapshots?"; then
    spinner "Installing Snapper and dependencies..."
    sudo dnf install -y snapper snap-confine || {
        warn_message "Failed to install Snapper. Skipping setup."
        exit 1
    }

    spinner "Creating Snapper configuration for root partition..."
    # Ensure the mount point exists for Snapper to work
    if ! sudo mount | grep -q 'subvol=/@'; then
        warn_message "Could not verify subvolume mount structure (/@). Skipping Snapper config."
        exit 1
    fi

    sudo snapper -c root create-config /

    okay_message "Snapper installed and configuration 'root' created."
else
    info_message "Snapper installation skipped."
fi

finish "Snapper setup complete."
