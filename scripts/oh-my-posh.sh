#!/usr/bin/env bash
# ===============================================
# Oh My Posh installer / updater
# ===============================================

# Ensure gum is installed
if ! command -v gum &>/dev/null; then
    echo "The 'gum' package is required but not installed. Installing it now..."
    sudo dnf install gum -y
fi

gum spin --title "Install Oh My Posh." -- sleep 2
if [ ! -d ~/.local/bin ]; then
    mkdir -p ~/.local/bin
fi
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin

# Final message
gum style --border normal --margin "1" --padding "1" \
    --align center --foreground 212 "Oh My Posh installation complete!"
