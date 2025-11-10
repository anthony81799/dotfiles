#!/usr/bin/env bash
# ===============================================
# Desktop Environment Setup
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library and initialize logging
source "${HOME}/install/lib.sh"

LOG_FILE="${LOG_DIR}/install-desktop.log"
init_log "$LOG_FILE"

ensure_gum

banner "Desktop Environment Setup"

# Directory for helper scripts
DESKTOP_SCRIPT_DIR="${HOME}/install/desktop"

# -------------------------------------------------------------
# --- Modular Execution ---
# -------------------------------------------------------------

# NVIDIA Driver and RPMFusion Setup
log "Running script: nvidia.sh"
bash "${DESKTOP_SCRIPT_DIR}/nvidia.sh"

# Install GUI Applications
log "Running script: gui-apps.sh"
bash "${DESKTOP_SCRIPT_DIR}/gui-apps.sh"

finish "Desktop Environment installation complete. Please reboot for all changes to take effect."
