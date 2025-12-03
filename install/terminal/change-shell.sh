#!/usr/bin/env bash
# ===============================================
# Default Shell Changer (Zsh/Bash/Fish)
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library
source "${HOME}/install/lib.sh"

LOG_FILE="${LOG_DIR}/change-shell.log"
init_log "$LOG_FILE"

ensure_gum

# --- Variables ---
BASH_BLESH_DIR="${XDG_DATA_HOME}/ble.sh"
OH_MY_POSH_SCRIPT="${HOME}/install/terminal/oh-my-posh.sh"

banner "Default Shell Configuration"

# --- 1. Shell Selection Menu & Installation ---
DEFAULT_SHELL=$(
  gum choose \
    --header "Select your preferred default shell" \
    "/bin/zsh (ZSH)" \
    "/bin/bash (Bash)" \
    "/usr/bin/fish (Fish)" \
    "Keep current shell (Skip)"
)

if [ "$DEFAULT_SHELL" == "Keep current shell (Skip)" ]; then
  info_message "Shell change skipped by user."
  finish "Shell setup complete."
fi

TARGET_SHELL=$(echo "$DEFAULT_SHELL" | awk '{print $1}')
TARGET_SHELL_NAME=$(basename "$TARGET_SHELL")

if ! has_cmd "$TARGET_SHELL_NAME"; then
  spinner "Installing ${TARGET_SHELL_NAME}..."
  sudo dnf install -y "$TARGET_SHELL_NAME" || {
    fail_message "Failed to install ${TARGET_SHELL_NAME}. Aborting."
  }
  okay_message "${TARGET_SHELL_NAME} installed."
else
  info_message "${TARGET_SHELL_NAME} is already installed."
fi

# --- 2. Configure Selected Shell (Conditional) ---

if [ ! -d "$BASH_BLESH_DIR" ]; then
  spinner "Cloning ble.sh for Bash enhancements..."
  git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git "$BASH_BLESH_DIR" || {
    warn_message "Failed to clone ble.sh. Bash enhancements will be limited."
  }

  if [ -d "$BASH_BLESH_DIR" ]; then
    spinner "Building and installing ble.sh..."
    if (cd "$BASH_BLESH_DIR" && make -C ble.sh install PREFIX="$BASH_BLESH_DIR"); then
      okay_message "Bash enhancements (ble.sh) set up."
    else
      warn_message "Failed to build ble.sh. Bash enhancements will be limited."
    fi
  fi
else
  info_message "ble.sh already cloned. Skipping build."
fi

if [ -f "$OH_MY_POSH_SCRIPT" ]; then
  spinner "Running Oh My Posh installer script..."
  bash "$OH_MY_POSH_SCRIPT" || warn_message "Oh My Posh installer script failed. Check log for details."
  okay_message "Oh My Posh setup initiated."
else
  warn_message "Oh My Posh script not found at ${OH_MY_POSH_SCRIPT}. Skipping OMP installation."
fi

# --- 3. Final Change Shell Command ---
spinner "Setting default shell to ${TARGET_SHELL} using chsh..."
if sudo chsh -s "$TARGET_SHELL" "$USER"; then
  okay_message "Default shell successfully changed to ${TARGET_SHELL}."
  warn_message "Please log out and log back in (or restart your terminal) for the new shell to take effect."
else
  fail_message "Failed to change shell using 'chsh'. You may need to run 'chsh -s ${TARGET_SHELL}' manually."
fi

finish "Shell change process complete!"
