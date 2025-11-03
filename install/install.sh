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

banner "Installing dotfiles and configurations"

bash "${HOME}/install/desktop/install-desktop.sh"

bash "${HOME}/install/terminal/install-terminal.sh"

finish "The installation is finished!"

fastfetch
