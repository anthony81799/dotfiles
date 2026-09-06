#!/usr/bin/env bash
# ===============================================
# DankMaterialShell (DMS) + Hyprland Setup
# ===============================================
# Optionally runs DMS's own upstream installer (install.danklinux.com), then
# offers to sync the user's tracked hypr/DMS customizations between this repo
# and the live machine.
#
# Never touches DMS-owned/regenerated files (dms/binds.lua, colors.lua,
# cursor.lua, layout.lua, windowrules.lua, outputs.lua -- each carries its
# own "auto-generated, do not edit manually" header) or the live
# ~/.config/DankMaterialShell directory's ownership/ACLs (it's shared with
# the `greeter` group so dms-greeter can read it -- see README.md). Only
# hyprland.lua + dms/binds-user.lua are symlinked; DankMaterialShell files
# are copied onto existing targets so their owner/group/ACL is preserved.
#
# Safe to re-run.
set -euo pipefail
IFS=$'\n\t'

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "${DOTFILES_DIR}/install/lib.sh"

LOG_FILE="${LOG_DIR}/dms.log"
init_log "$LOG_FILE"

ensure_gum

banner "DankMaterialShell + Hyprland Setup"

HYPR_CONFIG_DIR="${XDG_CONFIG_HOME}/hypr"
DMS_CONFIG_DIR="${XDG_CONFIG_HOME}/DankMaterialShell"
REPO_HYPR_DIR="${DOTFILES_DIR}/config/hypr"
REPO_DMS_DIR="${DOTFILES_DIR}/config/DankMaterialShell"

# --- 1. Optionally run the official DMS installer ---
if has_cmd dms && has_cmd Hyprland; then
	info_message "DMS and Hyprland already appear installed."
	RUN_INSTALLER=$(gum choose --header "DMS/Hyprland already present. Re-run upstream installer?" \
		"No, keep current install" "Yes, re-run installer")
else
	RUN_INSTALLER=$(gum choose --header "DMS/Hyprland not detected. Install now?" \
		"Yes, run upstream installer" "No, I already installed it manually" "Skip DMS/Hyprland setup entirely")
fi

case "$RUN_INSTALLER" in
"Skip DMS/Hyprland setup entirely")
	finish "Skipped DMS/Hyprland setup."
	;;
"Yes, run upstream installer" | "Yes, re-run installer")
	INSTALL_GREETER=false
	gum confirm "Also install dms-greeter (DMS's login screen)?" && INSTALL_GREETER=true

	INSTALLER_ARGS=(-c hyprland -t alacritty -y)
	[[ "$INSTALL_GREETER" == true ]] && INSTALLER_ARGS+=(--dms-greeter)

	info_message "Running the official DankInstall script (install.danklinux.com)..."
	sudo -v # prime sudo credentials -- the piped installer can't prompt interactively
	if curl -fsSL https://install.danklinux.com | sh -s -- "${INSTALLER_ARGS[@]}"; then
		okay_message "DankInstall completed."
	else
		fail_message "DankInstall failed. Check ${LOG_FILE} and https://danklinux.com/docs for troubleshooting."
	fi
	;;
esac

# --- 2. Ensure the Hyprland/DMS config scaffold exists ---
if has_cmd dms && [[ ! -f "${HYPR_CONFIG_DIR}/hyprland.lua" ]]; then
	info_message "No existing Hyprland config found -- deploying DMS defaults..."
	dms setup headless --compositor hyprland --skip-existing \
		|| warn_message "dms setup headless failed. Check ${LOG_FILE}."
fi

if [[ ! -d "$HYPR_CONFIG_DIR" ]]; then
	info_message "No ~/.config/hypr directory -- nothing to transplant."
	finish "DMS/Hyprland install step complete (config transplant skipped)."
fi

# --- 3. Config transplant ---
TRANSPLANT_MODE=$(gum choose --header "Sync hypr + DankMaterialShell config between dotfiles repo and this machine" \
	"Apply dotfiles -> live (fresh machine / after pulling repo changes)" \
	"Capture live -> dotfiles (after tweaking hyprland.lua/binds-user.lua by hand)" \
	"Skip config transplant")

apply_hypr() {
	[[ -f "${REPO_HYPR_DIR}/hyprland.lua" ]] \
		&& _link "${REPO_HYPR_DIR}/hyprland.lua" "${HYPR_CONFIG_DIR}/hyprland.lua"
	[[ -f "${REPO_HYPR_DIR}/dms/binds-user.lua" ]] \
		&& _link "${REPO_HYPR_DIR}/dms/binds-user.lua" "${HYPR_CONFIG_DIR}/dms/binds-user.lua"
}

capture_hypr() {
	mkdir -p "${REPO_HYPR_DIR}/dms"
	[[ -f "${HYPR_CONFIG_DIR}/hyprland.lua" ]] \
		&& cp "${HYPR_CONFIG_DIR}/hyprland.lua" "${REPO_HYPR_DIR}/hyprland.lua"
	[[ -f "${HYPR_CONFIG_DIR}/dms/binds-user.lua" ]] \
		&& cp "${HYPR_CONFIG_DIR}/dms/binds-user.lua" "${REPO_HYPR_DIR}/dms/binds-user.lua"
	okay_message "Captured hyprland.lua + binds-user.lua into ${REPO_HYPR_DIR}. Review with 'git -C ${DOTFILES_DIR} diff' and commit."
}

# DankMaterialShell/ is copy-based, never symlinked -- see header comment.
DMS_TRACKED_FILES=(settings.json plugin_settings.json firefox.css)

apply_dms_shell() {
	mkdir -p "$DMS_CONFIG_DIR"
	for f in "${DMS_TRACKED_FILES[@]}"; do
		[[ -f "${REPO_DMS_DIR}/${f}" ]] || continue
		if [[ -f "${DMS_CONFIG_DIR}/${f}" ]]; then
			cp "${REPO_DMS_DIR}/${f}" "${DMS_CONFIG_DIR}/${f}"
		else
			install -m 0644 "${REPO_DMS_DIR}/${f}" "${DMS_CONFIG_DIR}/${f}"
		fi
		log "Applied DMS config: ${f}"
	done
	[[ -d "${REPO_DMS_DIR}/themes" ]] && cp -r "${REPO_DMS_DIR}/themes/." "${DMS_CONFIG_DIR}/themes/" 2>/dev/null

	if has_cmd dms && [[ -f "${REPO_DMS_DIR}/plugins.lock.json" ]]; then
		info_message "Restoring plugins from tracked plugins.lock.json..."
		dms plugins restore "${REPO_DMS_DIR}/plugins.lock.json" \
			|| warn_message "dms plugins restore failed. Check ${LOG_FILE}."
	fi
	warn_message "settings.json may contain machine-specific values (e.g. screenPreferences.lockScreen monitor names) -- verify after applying on a different machine."
}

capture_dms_shell() {
	mkdir -p "$REPO_DMS_DIR"
	for f in "${DMS_TRACKED_FILES[@]}"; do
		[[ -f "${DMS_CONFIG_DIR}/${f}" ]] && cp "${DMS_CONFIG_DIR}/${f}" "${REPO_DMS_DIR}/${f}"
	done
	if [[ -d "${DMS_CONFIG_DIR}/themes" ]]; then
		mkdir -p "${REPO_DMS_DIR}/themes"
		cp -r "${DMS_CONFIG_DIR}/themes/." "${REPO_DMS_DIR}/themes/"
	fi
	if has_cmd dms; then
		dms plugins lock -o "${REPO_DMS_DIR}/plugins.lock.json" \
			|| warn_message "dms plugins lock failed. Check ${LOG_FILE}."
	fi
	okay_message "Captured DankMaterialShell config into ${REPO_DMS_DIR}. Review with 'git -C ${DOTFILES_DIR} diff' and commit."
}

case "$TRANSPLANT_MODE" in
"Apply dotfiles -> live"*)
	apply_hypr
	apply_dms_shell
	;;
"Capture live -> dotfiles"*)
	capture_hypr
	capture_dms_shell
	;;
*)
	info_message "Skipped config transplant."
	;;
esac

info_message "If you use greetd/dms-greeter, re-run greetd.sh to sync the greeter's monitor layout and gnome-keyring wiring."
finish "DankMaterialShell + Hyprland setup complete."
