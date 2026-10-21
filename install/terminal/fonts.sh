#!/usr/bin/env bash
# ===============================================
# Nerd Font installer (JetBrainsMono)
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "${DOTFILES_DIR}/install/lib.sh"

LOG_FILE="${LOG_DIR}/fonts-install.log"
init_log "$LOG_FILE"

ensure_gum

banner "JetBrainsMono Nerd Font"

FONT_DIR="${XDG_DATA_HOME}/fonts/JetBrainsMonoNerd"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"

if fc-list : family | grep "^JetBrainsMono Nerd Font Mono" >/dev/null; then
	okay_message "JetBrainsMono Nerd Font already installed. Skipping."
	finish "Font setup complete."
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

info_message "Downloading JetBrainsMono Nerd Font..."
spinner "Downloading JetBrainsMono Nerd Font" curl -fsSL -o "${TMP_DIR}/JetBrainsMono.tar.xz" "$FONT_URL" || {
	fail_message "Failed to download JetBrainsMono Nerd Font."
}

mkdir -p "$FONT_DIR"
tar -xJf "${TMP_DIR}/JetBrainsMono.tar.xz" -C "$FONT_DIR" --wildcards '*.ttf' || {
	fail_message "Failed to extract JetBrainsMono Nerd Font."
}

fc-cache -f "$FONT_DIR" >/dev/null

if fc-list : family | grep "^JetBrainsMono Nerd Font Mono" >/dev/null; then
	okay_message "JetBrainsMono Nerd Font installed to ${FONT_DIR}."
else
	warn_message "Font files extracted but fontconfig does not list JetBrainsMono Nerd Font."
fi

finish "Font setup complete."
