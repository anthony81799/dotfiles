#!/usr/bin/env bash
# ===============================================
# Dotfiles installer
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library
source "${HOME}/install/lib.sh"

init_log "${LOG_DIR}/dotfiles-install.log"

ensure_gum

# Variables for user choices
INSTALL_DESKTOP=false
INSTALL_TERMINAL=false

# Step 1: Installation type menu
INSTALL_TYPE=$(
    gum choose \
        "Full Desktop" \
        "Terminal Only"
)

case "$INSTALL_TYPE" in
"Full Desktop") INSTALL_DESKTOP=true ;;
"Terminal Only") INSTALL_TERMINAL=true ;;
esac

# Step 2: Run installations
if [ "$INSTALL_DESKTOP" = true ]; then
    # TODO: Write desktop installer!!!
    # bash "${HOME}/install/desktop/install-desktop.sh"
    INSTALL_TERMINAL=true
fi

if [ "$INSTALL_TERMINAL" = true ]; then
    bash "${HOME}/install/terminal/install-terminal.sh"
fi

finish "The installation is finished!"

fastfetch
