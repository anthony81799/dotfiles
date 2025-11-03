#!/usr/bin/env bash
# ===============================================
# Golang installer / updater
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library
source "${HOME}/install/lib.sh"

init_log "${LOG_DIR}/go-install.log"

ensure_gum

banner "Installing or Updating Go Toolchain"

# Default options
INSTALL_GO=false
UPDATE_GO=false
SKIPPED=false

# Step 1: Options menu
CHOICE=$(
    gum choose \
        "Install Go" \
        "Update existing Go installation" \
        "Skip (Do nothing)"
)

# Parse choice
case "$CHOICE" in
"Install Go") INSTALL_GO=true ;;
"Update existing Go installation") UPDATE_GO=true ;;
"Skip (Do nothing)") SKIPPED=true ;;
esac

# Step 2: Installation or update
if [ "$INSTALL_GO" = true ]; then
    spinner "Checking for existing Go installation..."

    if command -v go &>/dev/null; then
        EXISTING_VER=$(go version | awk '{print $3}')
        info_message "Existing Go installation detected: $EXISTING_VER"
        if gum confirm "Skip fresh install and update Go instead?"; then
            info_message "Skipping full installation — proceeding to update..."
            INSTALL_GO=false
            UPDATE_GO=true
        else
            info_message "Reinstalling Go from scratch..."
            sudo rm -rf /usr/local/go
        fi
    else
        info_message "No existing Go installation detected. Proceeding with fresh install."
    fi
fi

if [ "$INSTALL_GO" = true ]; then
    spinner "Installing Go..."

    GOLATESTURL="https://go.dev/VERSION?m=text"
    GOLATEST=$(curl -sL "$GOLATESTURL" | head -n1)
    GOLATEST_PRETTY=${GOLATEST#"go"}

    wget "https://dl.google.com/go/${GOLATEST}.linux-amd64.tar.gz"
    sudo tar -C /usr/local -xzf "${GOLATEST}.linux-amd64.tar.gz"
    rm -f "${GOLATEST}.linux-amd64.tar.gz"

    # Refresh PATH for current session
    export PATH="/usr/local/go/bin:$PATH"
    go version
    go telemetry off

    # Optional: install a few global Go tools
    go install github.com/jesseduffield/lazygit@latest
    go install mvdan.cc/sh/v3/cmd/shfmt@latest
    go install github.com/charmbracelet/glow/v2@latest

    okay_message "Go installation completed successfully."
fi

if [ "$UPDATE_GO" = true ]; then
    spinner "Updating Go to the latest version..."
    curl -sL https://raw.githubusercontent.com/DieTime/go-up/master/go-up.sh | bash
fi

if [ "$SKIPPED" = true ]; then
    info_message "Go installation/update skipped."
fi

finish "Go installation complete!"
