#!/usr/bin/env bash
# ===============================================
# Quickshell Rebuild (Qt private-ABI break fix)
# ===============================================
# quickshell (from the avengemedia/danklinux COPR) links against Qt's private
# QML property-binding API (symbols versioned e.g. `Qt_6.11_PRIVATE_API`),
# which Fedora's qt6-qt* packages do NOT promise to keep stable across point
# releases (only the public API is ABI-stable within a minor series). When
# Fedora ships a Qt6 bump before the COPR has rebuilt against it, `qs` starts
# failing instantly with a `symbol lookup error` -- which breaks `dms.service`
# (the DMS panel/bar) and `dms-greeter` (the graphical login screen) the same
# way, since both just spawn `qs` to do the actual QML rendering.
#
# This script rebuilds quickshell from its own source RPM against whatever Qt
# is currently installed, restoring the ABI match. Safe to re-run any time --
# it checks first and no-ops if quickshell already links cleanly.
#
# Must be run in a real interactive terminal: sudo needs to prompt for your
# password, which won't work piped through a non-interactive shell.
set -euo pipefail
IFS=$'\n\t'

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "${DOTFILES_DIR}/install/lib.sh"

LOG_FILE="${LOG_DIR}/rebuild-quickshell.log"
init_log "$LOG_FILE"

ensure_gum

banner "Quickshell Rebuild (Qt ABI Fix)"

if ! has_cmd rpmbuild; then
	fail_message "rpmbuild not found. Install it with: sudo dnf install -y rpm-build"
fi

QS_BIN="$(command -v quickshell || true)"
if [[ -z "$QS_BIN" ]]; then
	fail_message "quickshell is not installed. Nothing to rebuild."
fi

# --- 1. Check whether a rebuild is actually needed ---
info_message "Checking quickshell (${QS_BIN}) against the installed Qt libraries..."
LDD_OUTPUT="$(ldd -r "$QS_BIN" 2>&1 || true)"
log "ldd -r output: ${LDD_OUTPUT}"

if ! grep -q "undefined symbol" <<<"$LDD_OUTPUT"; then
	okay_message "quickshell already links cleanly against the installed Qt. Nothing to do."
	finish "No rebuild needed."
fi

warn_message "quickshell has unresolved symbols against the current Qt -- rebuild needed:"
grep "undefined symbol" <<<"$LDD_OUTPUT" | while read -r line; do warn_message "  $line"; done

# --- 2. Fetch the source RPM ---
BUILD_DIR="$(mktemp -d /tmp/quickshell-rebuild.XXXXXX)"
info_message "Working in ${BUILD_DIR}"
cd "$BUILD_DIR"

info_message "Downloading quickshell's source RPM..."
if ! dnf download --source quickshell; then
	fail_message "Failed to download the quickshell source RPM. Check $LOG_FILE for details."
fi

SRPM="$(find . -maxdepth 1 -name 'quickshell-*.src.rpm' | head -n1)"
if [[ -z "$SRPM" ]]; then
	fail_message "No quickshell source RPM found after download."
fi
okay_message "Got ${SRPM#./}"

# --- 3. Install build dependencies ---
info_message "Installing build dependencies (will prompt for your sudo password)..."
if ! sudo dnf builddep -y "$SRPM"; then
	fail_message "Failed to install build dependencies. Check $LOG_FILE for details."
fi

# --- 4. Rebuild against the currently-installed Qt ---
info_message "Rebuilding quickshell against the installed Qt -- this takes a few minutes..."
if ! rpmbuild --define "_topdir ${BUILD_DIR}/rpmbuild" --rebuild "$SRPM"; then
	fail_message "rpmbuild failed. Check $LOG_FILE, and build artifacts under ${BUILD_DIR}."
fi

mapfile -t RPMS_OUT < <(find "${BUILD_DIR}/rpmbuild/RPMS" -name '*.rpm' ! -iname '*debuginfo*' ! -iname '*debugsource*')
if [[ ${#RPMS_OUT[@]} -eq 0 ]]; then
	fail_message "Build finished but no output RPM was found under ${BUILD_DIR}/rpmbuild/RPMS."
fi
okay_message "Built: ${RPMS_OUT[*]}"

# --- 5. Install the freshly-built package(s) ---
info_message "Installing the rebuilt quickshell (will prompt for your sudo password)..."
if ! sudo dnf reinstall -y "${RPMS_OUT[@]}"; then
	fail_message "Failed to install the rebuilt quickshell. Check $LOG_FILE for details."
fi

# --- 6. Verify the fix ---
LDD_RECHECK="$(ldd -r "$QS_BIN" 2>&1 || true)"
if grep -q "undefined symbol" <<<"$LDD_RECHECK"; then
	fail_message "quickshell still has unresolved symbols after rebuild. Manual investigation needed."
fi
okay_message "quickshell now links cleanly against the installed Qt."

# --- 7. Restart the live DMS shell (if running) and clear greetd's lockout ---
if systemctl --user list-unit-files dms.service &>/dev/null; then
	info_message "Restarting dms.service to pick up the rebuilt quickshell..."
	systemctl --user reset-failed dms.service &>/dev/null || true
	if systemctl --user restart dms.service; then
		okay_message "dms.service restarted."
	else
		warn_message "dms.service failed to restart. Check: systemctl --user status dms.service"
	fi
fi

if systemctl list-unit-files greetd.service &>/dev/null; then
	info_message "Clearing greetd's failure lockout (will prompt for your sudo password)..."
	sudo systemctl reset-failed greetd || warn_message "Could not reset greetd's failure state."
fi

# --- 8. Clean up build artifacts ---
rm -rf "$BUILD_DIR"

finish "Quickshell rebuild complete -- the greeter and DMS shell should work normally again."
