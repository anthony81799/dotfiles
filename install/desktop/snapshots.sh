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
    finish "Snapper setup complete."
fi

if gum confirm "Do you want to install and configure Snapper for Btrfs snapshots?"; then
    spinner "Installing Snapper and dependencies..."
    sudo dnf install -y snapper snap-confine || {
        fail_message "Failed to install Snapper. Skipping setup."
    }

    spinner "Creating Snapper configuration for root partition..."
    # FIX: Removed the faulty 'subvol=/@' check. Snapper can configure / as long as it is BTRFS.
    sudo snapper -c root create-config / || {
        fail_message "Failed to create Snapper configuration for root. Check $LOG_FILE for details."
    }

    okay_message "Snapper installed and configuration 'root' created."
else
    info_message "Snapper installation skipped."
fi

finish "Snapper setup complete."
