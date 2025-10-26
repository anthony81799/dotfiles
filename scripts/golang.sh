#!/usr/bin/env bash
# ===============================================
# Golang installer / updater (gum-based version)
# Similar UX and style to install.sh
# ===============================================

# Ensure gum is installed
if ! command -v gum &>/dev/null; then
    echo "The 'gum' package is required but not installed. Installing it now..."
    sudo dnf install gum -y
fi

# Default options
INSTALL_GO=false
UPDATE_GO=false
SKIPPED=false

# Step 1: Options menu
CHOICE=$(gum choose \
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
    gum spin --title "Checking for existing Go installation..." -- sleep 1
    
    if command -v go &>/dev/null; then
        EXISTING_VER=$(go version | awk '{print $3}')
        gum style --foreground 244 "Existing Go installation detected: $EXISTING_VER"
        if gum confirm "Skip fresh install and update Go instead?"; then
            gum style --foreground 244 "Skipping full installation — proceeding to update..."
            INSTALL_GO=false
            UPDATE_GO=true
        else
            gum style --foreground 244 "Reinstalling Go from scratch..."
            sudo rm -rf /usr/local/go
        fi
    else
        gum style --foreground 244 "No existing Go installation detected. Proceeding with fresh install."
    fi
fi

if [ "$INSTALL_GO" = true ]; then
    gum spin --title "Installing Go..." -- sleep 1
    
    GOLATESTURL="https://go.dev/VERSION?m=text"
    GOLATEST=$(curl -sL "$GOLATESTURL" | head -n1)
    GOLATEST_PRETTY=${GOLATEST#"go"}
    
    wget https://dl.google.com/go/$GOLATEST.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf "$GOLATEST.linux-amd64.tar.gz"
    rm -f "$GOLATEST.linux-amd64.tar.gz"
    
    # Refresh PATH for current session
    export PATH="/usr/local/go/bin:$PATH"
    go version
    go telemetry off
fi

if [ "$UPDATE_GO" = true ]; then
    gum spin --title "Updating Go to the latest version..." -- sleep 1
    curl -sL https://raw.githubusercontent.com/DieTime/go-up/master/go-up.sh | bash
fi

if [ "$SKIPPED" = true ]; then
    gum style --foreground 244 "Go installation/update skipped."
fi

# Final message
gum style --border normal --margin "1" --padding "1" \
--align center --foreground 212 "Go installation complete!"
