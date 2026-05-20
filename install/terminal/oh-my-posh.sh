#!/usr/bin/env bash
# ===============================================
# Oh My Posh installer / updater
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "${DOTFILES_DIR}/install/lib.sh"

LOG_FILE="${LOG_DIR}/oh-my-posh-install.log"
init_log "$LOG_FILE"

ensure_gum

banner "Oh My Posh"

# --- 1. Dependency Check: curl ---
if ! has_cmd curl; then
	warn_message "Command 'curl' not found. Installing..."
	sudo dnf install -y curl || {
		fail_message "Failed to install curl. Aborting Oh My Posh installation."
	}
fi

# --- 2. Setup Directory ---
if [ ! -d "${HOME}/.local/bin" ]; then
	info_message "Creating local bin directory: ${HOME}/.local/bin"
	mkdir -p "${HOME}/.local/bin"
fi

# --- 3. Install/Update Oh My Posh (Robust Execution) ---
info_message "Installing or Updating Oh My Posh to ${HOME}/.local/bin..."

if curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "${HOME}/.local/bin"; then
	okay_message "Oh My Posh installed/updated successfully."
else
	fail_message "Oh My Posh installation failed. Check the log for details."
fi

if has_cmd oh-my-posh; then
    okay_message "Oh My Posh installed: $(oh-my-posh --version)"
else
    warn_message "oh-my-posh binary not found after install. Check $LOG_DIR/oh-my-posh-install.log"
fi

finish "Oh My Posh installation complete!"
