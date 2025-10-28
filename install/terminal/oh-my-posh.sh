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

spinner "Installing Oh My Posh..."

# Ensure local bin directory exists
if [ ! -d "${HOME}/.local/bin" ]; then
    mkdir -p "${HOME}/.local/bin"
fi

# Install Oh My Posh
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "${HOME}/.local/bin"

finish "Oh My Posh installation complete!"
