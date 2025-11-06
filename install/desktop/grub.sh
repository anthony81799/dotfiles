#!/usr/bin/env bash
# ===============================================
# GRUB Boot Configuration
# ===============================================
set -euo pipefail
IFS=$'\n\t'

source "${HOME}/install/lib.sh"
LOG_FILE="${LOG_DIR}/setup-grub.log"

init_log "$LOG_FILE"

ensure_gum

banner "GRUB Instant Boot Configuration"

spinner "Configuring GRUB to skip the menu prompt (auto-select first entry)..."

GRUB_CONFIG="/etc/default/grub"

if [ -f "$GRUB_CONFIG" ]; then

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
        return 1
    }
    okay_message "GRUB configured to boot the first entry instantly."
else
    warn_message "GRUB configuration file not found at ${GRUB_CONFIG}. Skipping configuration."
fi

finish "GRUB boot configuration complete."
