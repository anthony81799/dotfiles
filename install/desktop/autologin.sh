#!/usr/bin/env bash
# ===============================================
# SDDM Autologin Setup
# ===============================================
set -euo pipefail
IFS=$'\n\t'

source "${HOME}/install/lib.sh"
LOG_FILE="${LOG_DIR}/setup-sddm.log"

init_log "$LOG_FILE"

ensure_gum

banner "SDDM Autologin Configuration"

SDDM_CONFIG="/etc/sddm.conf.d/autologin.conf"

if has_cmd sddm; then
    spinner "Configuring SDDM for automatic login..."

    # Create the config directory if it doesn't exist
    sudo mkdir -p "/etc/sddm.conf.d"

    # Write the autologin configuration
    sudo tee "$SDDM_CONFIG" >/dev/null <<EOF
[Autologin]
User=$USER
Session=hyprland-uwsm.desktop

[Users]
DefaultPath=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:$HOME/.local/bin
EOF

    # Enable SDDM service
    spinner "Enabling SDDM service..."
    sudo systemctl enable --now sddm.service || {
        warn_message "Failed to enable sddm.service. You may need to start it manually."
    }

    okay_message "SDDM configured for automatic login using the Hyprland session."
else
    warn_message "SDDM or its service file not found. Automatic login not configured."
fi

finish "SDDM autologin setup complete."
