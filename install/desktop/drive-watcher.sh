#!/usr/bin/env bash
# ===============================================
# New Drive Watcher Service
# ===============================================
# Installs + enables a systemd user unit that runs scripts/drive-watcher.sh
# for the lifetime of the graphical session. Whenever a new, unused SSD/HDD
# shows up (at boot or hot-plugged), it opens a terminal with a gum wizard to
# partition, format and mount it. See the header of scripts/drive-watcher.sh.
#
# The unit is bound to graphical-session.target (pulled in by DMS's
# hyprland-session.target), so it starts after Hyprland has exported
# WAYLAND_DISPLAY into the systemd user environment and can open windows.
#
# Safe to re-run.
set -euo pipefail
IFS=$'\n\t'

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "${DOTFILES_DIR}/install/lib.sh"

LOG_FILE="${LOG_DIR}/drive-watcher-install.log"
init_log "$LOG_FILE"

ensure_gum

banner "New Drive Watcher Service"

WATCHER_SCRIPT="${DOTFILES_DIR}/scripts/drive-watcher.sh"
UNIT_DIR="${XDG_CONFIG_HOME}/systemd/user"
UNIT_FILE="${UNIT_DIR}/drive-watcher.service"

[[ -x "$WATCHER_SCRIPT" ]] || fail_message "Watcher script not found or not executable: ${WATCHER_SCRIPT}"

if ! gum confirm "Watch for new drives and offer to set them up automatically?"; then
	finish "Skipped drive watcher setup."
fi

for cmd in parted wipefs udevadm; do
	has_cmd "$cmd" || warn_message "'${cmd}' not found -- the setup wizard needs it (sudo dnf install -y parted util-linux systemd-udev)."
done

info_message "Writing ${UNIT_FILE}..."
mkdir -p "$UNIT_DIR"
cat >"$UNIT_FILE" <<UNIT
[Unit]
Description=Detect new drives and offer to set them up
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Type=simple
Environment=DOTFILES_DIR=${DOTFILES_DIR}
ExecStart=${WATCHER_SCRIPT}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical-session.target
UNIT
log "Wrote ${UNIT_FILE}"

systemctl --user daemon-reload
if systemctl --user enable drive-watcher.service; then
	okay_message "drive-watcher.service enabled -- it will start with your next Hyprland session."
else
	fail_message "Failed to enable drive-watcher.service. Check: systemctl --user status drive-watcher.service"
fi

# Start it right away if we're already inside a graphical session.
if systemctl --user is-active --quiet graphical-session.target; then
	if systemctl --user restart drive-watcher.service; then
		okay_message "drive-watcher.service started."
	else
		warn_message "drive-watcher.service failed to start. Check: journalctl --user -u drive-watcher.service"
	fi
fi

finish "Drive watcher setup complete. Logs: ${LOG_DIR}/drive-watcher.log"
