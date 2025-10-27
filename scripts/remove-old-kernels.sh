#!/usr/bin/env bash
# ===============================================
# Remove select old kernels
# ===============================================

# Ensure gum is installed
if ! command -v gum &>/dev/null; then
    echo "The 'gum' package is required but not installed. Installing it now..."
    sudo dnf install gum -y
fi

# Step 1: Find old kernels
OLD_KERNELS=($(dnf repoquery --installonly --latest-limit=-1 -q))
if [ "${#OLD_KERNELS[@]}" -eq 0 ]; then
    gum style --foreground 244 "No old kernels found"
else
    # Step 2: Main menu for installation options
    SELECTED_KERNELS=()
    while IFS= read -r CHOICE; do
        SELECTED_KERNELS+=("$CHOICE")
    done < <(gum choose --no-limit "${OLD_KERNELS[@]}")

    if ! dnf remove "${SELECTED_KERNELS[@]}" $@; then
        echo "Failed to remove old kernels"
        gum style --foreground 244 "Failed to remove old kernels"
        exit 1
    fi
fi

# Final message
gum style --border normal --margin "1" --padding "1" \
    --align center --foreground 212 "Removed selected kernels"
