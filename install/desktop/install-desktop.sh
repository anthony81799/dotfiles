#!/usr/bin/env bash
# ===============================================
# Desktop Environment Setup
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library and initialize logging
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "${DOTFILES_DIR}/install/lib.sh"

LOG_FILE="${LOG_DIR}/install-desktop.log"
init_log "$LOG_FILE"

ensure_gum

banner "Desktop Environment Setup"

# Directory for helper scripts
DESKTOP_SCRIPT_DIR="${DOTFILES_DIR}/install/desktop"

# -------------------------------------------------------------
# --- Modular Execution ---
# -------------------------------------------------------------

for script in nvidia.sh gui-apps.sh; do
    [[ -x "${DESKTOP_SCRIPT_DIR}/${script}" ]] \
        || fail_message "Required script not found or not executable: ${DESKTOP_SCRIPT_DIR}/${script}"
done

# NVIDIA Driver and RPMFusion Setup
log "Running script: nvidia.sh"
bash "${DESKTOP_SCRIPT_DIR}/nvidia.sh"

# Install GUI Applications
log "Running script: gui-apps.sh"
bash "${DESKTOP_SCRIPT_DIR}/gui-apps.sh"

finish "Desktop Environment installation complete. Please reboot for all changes to take effect."
