#!/usr/bin/env bash
# ===============================================
# Dotfiles installer
# ===============================================
set -euo pipefail
IFS=$'\n\t'

LOG_DIR="${HOME}/.local/logs"
mkdir -p "$LOG_DIR"

init_log() {
    local log_file="$1"
    # Close FD 6 if it's already open, then open the log file for appending on FD 6
    exec 6>&- || true
    exec 6>>"$log_file"
}
init_log "${LOG_DIR}/dotfiles-install.log"

ensure_gum() {
    if ! command -v gum &>/dev/null; then
        echo "The 'gum' package is required but not installed. Installing it now..."
        sudo dnf install -y gum
    fi
}
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
    bash "${HOME}/install/desktop/install-desktop.sh"
    INSTALL_TERMINAL=true
fi

if [ "$INSTALL_TERMINAL" = true ]; then
    bash "${HOME}/install/terminal/install-terminal.sh"
fi

finish "The installation is finished!"

fastfetch
