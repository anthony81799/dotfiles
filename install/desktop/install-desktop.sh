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
# --- Modular Steps Execution ---
# -------------------------------------------------------------

# Step 1: NVIDIA Driver and RPMFusion Setup
log "Running script: nvidia.sh"
bash "${DESKTOP_SCRIPT_DIR}/nvidia.sh"

# Step 2: Gaming Features and Performance Tweaks
log "Running script: gaming-tweaks.sh"
bash "${DESKTOP_SCRIPT_DIR}/gaming-tweaks.sh"

# Step 3: Btrfs Snapshot Setup (Snapper)
log "Running script: snapshots.sh"
bash "${DESKTOP_SCRIPT_DIR}/snapshots.sh"

# STEP 4: Install GUI Applications
log "Running script: gui-apps.sh"
bash "${DESKTOP_SCRIPT_DIR}/gui-apps.sh"

# Step 5: Setup SDDM Autologin
log "Running script: autologin.sh"
bash "${DESKTOP_SCRIPT_DIR}/autologin.sh"

# Step 6: Skip GRUB Menu Prompt
log "Running script: grub.sh"
bash "${DESKTOP_SCRIPT_DIR}/grub.sh"

finish "Desktop Environment installation complete. Please reboot for all changes (drivers, kernel modules, shell, GRUB) to take effect."
