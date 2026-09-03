#!/usr/bin/env bash
# ===============================================
# Btrfs Snapshots (snapper + dnf plugin)
# ===============================================
# Configures automatic btrfs snapshots so a bad `dnf upgrade` (or anything
# else that leaves the system half-broken) can be rolled back in seconds
# instead of diagnosed from scratch -- e.g. the Sep 2026 Qt6 point-release
# bump that broke quickshell/dms-greeter would have been a one-command
# `snapper undochange` instead of a multi-hour investigation.
#
# - Creates a snapper config per btrfs subvolume that's actually mounted
#   separately (root, and home if it's its own subvolume).
# - python3-dnf-plugin-snapper takes an automatic before/after snapshot pair
#   around every `dnf` transaction.
# - snapper-timeline.timer/-cleanup.timer take periodic snapshots and prune
#   old ones so this doesn't grow unbounded.
#
# No-ops entirely on a non-btrfs root filesystem. Safe to re-run: skips any
# config that already exists.
set -euo pipefail
IFS=$'\n\t'

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "${DOTFILES_DIR}/install/lib.sh"

LOG_FILE="${LOG_DIR}/btrfs-snapshots-install.log"
init_log "$LOG_FILE"

ensure_gum

banner "Btrfs Snapshot Setup (snapper)"

if [[ "$(findmnt -no FSTYPE /)" != "btrfs" ]]; then
	info_message "Root filesystem is not btrfs. Skipping snapshot setup."
	finish "Nothing to do (not on btrfs)."
fi

info_message "Installing snapper and the DNF snapshot plugin..."
if ! sudo dnf install -y snapper python3-dnf-plugin-snapper; then
	fail_message "Failed to install snapper. Check $LOG_FILE for details."
fi

configure_snapper() {
	local config_name="$1"
	local mountpoint="$2"

	if sudo snapper list-configs 2>/dev/null | awk '{print $1}' | grep -qx "$config_name"; then
		info_message "snapper config '${config_name}' already exists. Skipping create-config."
		return
	fi

	info_message "Creating snapper config '${config_name}' for ${mountpoint}..."
	if ! sudo snapper -c "$config_name" create-config "$mountpoint"; then
		warn_message "Failed to create snapper config '${config_name}' for ${mountpoint}."
		return
	fi

	# Sane defaults: keep the automatic dnf pre/post pairs, prune everything
	# else on a modest timeline instead of snapper's chattier stock limits.
	sudo sed -i \
		-e 's/^TIMELINE_CREATE=.*/TIMELINE_CREATE="yes"/' \
		-e 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="5"/' \
		-e 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/' \
		-e 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="4"/' \
		-e 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="6"/' \
		-e 's/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' \
		"/etc/snapper/configs/${config_name}"

	okay_message "snapper config '${config_name}' created for ${mountpoint}."
}

configure_snapper root /

if mountpoint -q /home && [[ "$(findmnt -no FSTYPE /home)" == "btrfs" ]]; then
	configure_snapper home /home
else
	info_message "/home is not a separate btrfs subvolume. Skipping home config."
fi

info_message "Enabling timeline snapshot + cleanup timers..."
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer

okay_message "Snapper is configured. dnf transactions now auto-snapshot before/after."
info_message "List snapshots any time with:  sudo snapper -c root list"
info_message "Roll back a bad change with:   sudo snapper -c root undochange <first>..<second>"
info_message "(Optional, not installed here: 'grub-btrfs' adds GRUB menu entries to boot"
info_message "directly into a snapshot -- worth adding by hand if you want boot-time recovery too.)"

finish "Btrfs snapshot setup complete."
