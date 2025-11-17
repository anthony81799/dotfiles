#!/usr/bin/env bash
# ===============================================
# Oh My Posh installer / updater
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library
source "${HOME}/install/lib.sh"

init_log "${LOG_DIR}/oh-my-posh-install.log"

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
	spinner "Creating local bin directory: ${HOME}/.local/bin"
	mkdir -p "${HOME}/.local/bin"
fi

# --- 3. Install/Update Oh My Posh (Robust Execution) ---
spinner "Installing or Updating Oh My Posh to ${HOME}/.local/bin..."

if curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "${HOME}/.local/bin"; then
	okay_message "Oh My Posh installed/updated successfully."
else
	fail_message "Oh My Posh installation failed. Check the log for details."
fi

finish "Oh My Posh installation complete!"
