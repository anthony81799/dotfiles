#!/usr/bin/env bash
# ===============================================
# Remove select old kernels
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library
source "${HOME}/install/lib.sh"

ensure_gum

banner "Old Kernel Removal Utility"

# --- 1. Query Old Kernels ---
spinner "Querying for old kernels to remove..."
mapfile -t OLD_KERNELS < <(dnf repoquery --installonly --latest-limit=-1 -q)

if [ "${#OLD_KERNELS[@]}" -eq 0 ]; then
	info_message "No old kernels found to remove."
	finish "Kernel removal complete."
fi

okay_message "Found ${#OLD_KERNELS[@]} old kernels."

# --- 2. User Selection ---
SELECTED=()
while IFS= read -r CHOICE; do
	SELECTED+=("$CHOICE")
done < <(gum choose --no-limit --header "Select old kernels to remove" "${OLD_KERNELS[@]}")

if [ "${#SELECTED[@]}" -eq 0 ]; then
	info_message "No kernels selected. Nothing to remove."
	finish "Kernel removal complete."
fi

# --- 3. Confirmation and Removal ---
warn_message "The following ${#SELECTED[@]} kernels will be removed:"
for k in "${SELECTED[@]}"; do
	echo "  - $k"
done

if ! gum confirm "Proceed to remove the selected kernels?"; then
	info_message "Aborted by user."
	finish "Kernel removal complete."
fi

spinner "Removing selected kernels..."
if sudo dnf remove -y "${SELECTED[@]}"; then
	okay_message "Successfully removed ${#SELECTED[@]} kernels."
else
	fail_message "Failed to remove some kernels. Check ${LOG_FILE} for details."
fi

finish "Kernel removal complete."
