#!/usr/bin/env bash
# ===============================================
# Rust + Helix installer
# ===============================================

# Ensure gum is installed
if ! command -v gum &>/dev/null; then
    echo "The 'gum' package is required but not installed. Installing it now..."
    sudo dnf install gum -y
fi

# Default options
INSTALL_RUST=false
INSTALL_HELIX=false
UPDATE_HELIX=false

# Step 1: Menu for Rust/Helix options
CHOICES=$(
    gum choose --no-limit \
        "Install or Reinstall Rust (rustup + crates)" \
        "Install Helix Editor" \
        "Update Helix Editor and install LSPs"
)

# Parse choices
while IFS= read -r CHOICE; do
    case $CHOICE in
    "Install or Reinstall Rust (rustup + crates)") INSTALL_RUST=true ;;
    "Install Helix Editor") INSTALL_HELIX=true ;;
    "Update Helix Editor and install LSPs") UPDATE_HELIX=true ;;
    esac
done <<<"$CHOICES"

# Step 2: Rust installation
if [ "$INSTALL_RUST" = true ]; then
    gum spin --title "Installing Rust and crates..." -- sleep 1
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"

    gum spin --title "Installing Rust crates..." -- sleep 1
    cargo install atuin bacon bat bottom cargo-update eza fd-find ripgrep sd tealdeer topgrade wallust zoxide
    cargo install --locked yazi-fm yazi-cli
    cargo install --locked zellij dysk ast-grep
else
    gum style --foreground 244 "Rust installation skipped."
fi

# Step 3: Helix installation
if [ "$INSTALL_HELIX" = true || "$UPDATE_HELIX" = true]; then
    bash ~/scripts/helix.sh
fi

# Final message
gum style --border normal --margin "1" --padding "1" \
    --align center --foreground 212 "Rust + Helix installation complete!"
