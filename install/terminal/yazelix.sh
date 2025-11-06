#!/usr/bin/env bash
# ===============================================
# Yazelix installer (yzi + zellij + helix)
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library
source "${HOME}/install/lib.sh"

init_log "${LOG_DIR}/yazelix-install.log"

ensure_gum

banner "Yazelix Development Environment"

if ! has_cmd nix; then
    warn_message "Nix package manager not found. Installing..."
    curl -sSf -L https://install.lix.systems/lix | sh -s -- install || {
        fail_message "Failed to install Nix. Please install it manually."
    }
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

spinner "Installing devenv CLI..."
nix profile install github:cachix/devenv/latest || {
    fail_message "Failed to install devenv CLI. Please install it manually."
}

spinner "Installing nushell..."
nix profile install nixpkgs#nushell

spinner "Cloning Yazelix repository..."
git clone https://github.com/luccahuguet/yazelix ~/.config/yazelix

spinner "installing required fonts..."
nix profile install nixpkgs#nerd-fonts.fira-code nixpkgs#nerd-fonts.symbols-only

finish "Yazelix installation completed successfully! You can start it using this command: 'nu ~/.config/yazelix/nushell/scripts/core/start_yazelix.nu'"
