#!/usr/bin/env bash
# ===============================================
# Remove select old kernels
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library
source "${HOME}/install/lib.sh"

init_log "${LOG_DIR}/remvove-old-kernels.log"

ensure_gum

# Get old kernels (one per line); mapfile handles spacing safely
mapfile -t OLD_KERNELS < <(dnf repoquery --installonly --latest-limit=-1 -q)

if [ "${#OLD_KERNELS[@]}" -eq 0 ]; then
    info_message "No old kernels found."
    finish "Kernel removal complete."
fi

# Prompt user to select kernels to remove (multi-select)
SELECTED=()
while IFS= read -r CHOICE; do
    SELECTED+=("$CHOICE")
done < <(gum choose --no-limit --header "Select old kernels to remove" "${OLD_KERNELS[@]}")

if [ "${#SELECTED[@]}" -eq 0 ]; then
    info_message "No kernels selected. Nothing to remove."
    finish "Kernel removal complete."
fi

# Confirm removal
warn_message "The following kernels will be removed:"
for k in "${SELECTED[@]}"; do
    echo "  - $k"
done

if ! gum confirm "Proceed to remove the selected kernels?"; then
    info_message "Aborted by user."
    finish "Kernel removal complete."
fi

# Remove with sudo and -y to avoid prompts
spinner "Removing selected kernels..." --
sudo dnf remove -y "${SELECTED[@]}" || {
    fail_message "Failed to remove some kernels. Check ${LOG} for details."
}

finish "Kernel removal complete."
