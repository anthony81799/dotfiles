#!/usr/bin/env bash
# ===============================================
# Default Shell Changer (Zsh/Bash)
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library
source "${HOME}/install/lib.sh"

init_log "${LOG_DIR}/change-shell.log"

ensure_gum

# --- Variables ---
BASH_BLESH_DIR="${XDG_DATA_HOME}"/ble.sh
OH_MY_POSH_SCRIPT="${HOME}/install/terminal/oh-my-posh.sh"

banner "Default Shell Configuration"

# ------------------------------------------------------------
# --- 1. Shell Selection Menu ---
# ------------------------------------------------------------
spinner "Checking available shells..."

DEFAULT_SHELL=$(
    gum choose \
        --header "Select your preferred default shell" \
        "/bin/zsh (ZSH)" \
        "/bin/bash (Bash)" \
        "/usr/bin/fish (Fish)" \
        "Keep current shell (Skip)"
)

# Parse choice
if [ "$DEFAULT_SHELL" == "Keep current shell (Skip)" ]; then
    info_message "Shell change skipped by user."
    finish "Shell setup complete."
fi

# Extract just the shell path
TARGET_SHELL=$(echo "$DEFAULT_SHELL" | awk '{print $1}')

# Check if the chosen shell is installed
if ! has_cmd "$(basename "$TARGET_SHELL")"; then
    spinner "Installing $(basename "$TARGET_SHELL")..."
    sudo dnf install -y "$(basename "$TARGET_SHELL")" || {
        fail_message "Failed to install $(basename "$TARGET_SHELL"). Aborting."
    }
fi

# ------------------------------------------------------------
# --- 2. Configure Selected Shell and Change Default ---
# ------------------------------------------------------------

# BASH Setup
spinner "Installing ble.sh for Bash enhancements..."

# Check for existing installation to avoid errors
if [ ! -d "$BASH_BLESH_DIR" ]; then
    git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git "$BASH_BLESH_DIR"
    cd "$BASH_BLESH_DIR"
    make install
else
    info_message "ble.sh already cloned."
fi

okay_message "Bash enhancements (ble.sh) set up."

if [ -f "$OH_MY_POSH_SCRIPT" ]; then
    spinner "Running Oh My Posh installer..."
    bash "$OH_MY_POSH_SCRIPT"
else
    warn_message "Oh My Posh script not found at ${OH_MY_POSH_SCRIPT}. Skipping OMP installation."
fi

# ------------------------------------------------------------
# --- 3. Final Change Shell Command ---
# ------------------------------------------------------------
spinner "Setting default shell to ${TARGET_SHELL} using chsh..."
# Use chsh -s to change the shell for the current user
if sudo chsh -s "$TARGET_SHELL" "$USER"; then
    okay_message "Default shell successfully changed to ${TARGET_SHELL}."
    warn_message "Please log out and log back in (or restart your terminal) for the new shell to take effect."
else
    fail_message "Failed to change shell using 'chsh'. You may need to run 'chsh -s ${TARGET_SHELL}' manually."
fi

finish "Shell change process complete!"
