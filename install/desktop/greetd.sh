#!/usr/bin/env bash
# ===============================================
# greetd / dms-greeter Setup
# ===============================================
# Finishes wiring an already-installed greetd + dms-greeter (DMS's Hyprland
# login screen) so it matches the real desktop session instead of falling
# back to defaults:
#
# - Installs gnome-keyring-pam and enables gnome-keyring-daemon.socket, so
#   the PAM hooks greetd already ships (in /etc/pam.d/greetd) can actually
#   unlock your login keyring instead of silently no-op-ing.
# - Loads the my-dmsgreeter SELinux module (allows xdm_t to write to its own
#   dir; without it, targeted enforcing mode blocks part of the greeter
#   session).
# - Generates /etc/greetd/dms-hypr-monitors.lua from the current Hyprland
#   monitor layout and points dms-greeter at it via config.toml, so the
#   greeter's monitors match orientation/position/refresh rate instead of a
#   generic default (see scripts/regen-greeter-monitors.sh -- re-run that any
#   time the monitor layout changes after this initial setup).
#
# This script does NOT install greetd/Hyprland/DMS itself -- it assumes
# that's already set up (e.g. via the avengemedia/danklinux COPR) and no-ops
# if greetd isn't present, so it's safe to run on machines that don't use
# this greeter at all.
set -euo pipefail
IFS=$'\n\t'

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "${DOTFILES_DIR}/install/lib.sh"

LOG_FILE="${LOG_DIR}/greetd.log"
init_log "$LOG_FILE"

ensure_gum

banner "greetd / dms-greeter Setup"

if ! has_cmd greetd && ! systemctl list-unit-files greetd.service &>/dev/null; then
	info_message "greetd not found on this system. Skipping greeter setup."
	finish "No greeter to configure."
fi

# --- 1. Ensure gnome-keyring can actually auto-unlock at greetd login ---
# /etc/pam.d/greetd (shipped by the greetd package itself, not hand-edited --
# verify with `rpm -qf /etc/pam.d/greetd`) already includes optional
# pam_gnome_keyring.so auth/session lines; they silently no-op unless the
# module providing pam_gnome_keyring.so is actually installed.
if ! rpm -q gnome-keyring-pam &>/dev/null; then
	info_message "Installing gnome-keyring-pam so the greeter's PAM hooks can unlock your keyring..."
	sudo dnf install -y gnome-keyring-pam || warn_message "Failed to install gnome-keyring-pam."
else
	info_message "gnome-keyring-pam already installed."
fi

if has_cmd systemctl; then
	if ! systemctl --user is-enabled gnome-keyring-daemon.socket &>/dev/null; then
		info_message "Enabling gnome-keyring-daemon.socket (user unit)..."
		systemctl --user enable --now gnome-keyring-daemon.socket \
			|| warn_message "Failed to enable gnome-keyring-daemon.socket."
	else
		info_message "gnome-keyring-daemon.socket already enabled."
	fi
fi

# --- 2. Load the SELinux module the greeter needs under enforcing mode ---
SELINUX_MODULE="${DOTFILES_DIR}/my-dmsgreeter.pp"
if has_cmd getenforce && [[ "$(getenforce)" != "Disabled" ]]; then
	if [[ -f "$SELINUX_MODULE" ]]; then
		info_message "Loading my-dmsgreeter SELinux module (will prompt for your sudo password)..."
		if sudo semodule -i "$SELINUX_MODULE"; then
			okay_message "SELinux module loaded."
		else
			warn_message "Failed to load ${SELINUX_MODULE}. The greeter may hit AVC denials under enforcing mode."
		fi
	else
		warn_message "${SELINUX_MODULE} not found. Skipping SELinux module install."
	fi
else
	info_message "SELinux disabled -- skipping module install."
fi

# --- 3. Sync the greeter's monitor layout + config.toml wiring ---
REGEN_SCRIPT="${DOTFILES_DIR}/scripts/regen-greeter-monitors.sh"
if [[ -x "$REGEN_SCRIPT" ]]; then
	info_message "Syncing greeter monitor layout..."
	bash "$REGEN_SCRIPT" || warn_message "Greeter monitor sync failed. Check $LOG_FILE and re-run ${REGEN_SCRIPT} manually."
else
	warn_message "${REGEN_SCRIPT} not found or not executable. Skipping monitor layout sync."
fi

finish "greetd setup complete."
