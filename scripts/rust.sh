#!/usr/bin/env bash

# Parse arguments
UPDATE_HELIX=false
INSTALL_HELIX=false
while getopts "h-:u-:i" opt; do
    case $opt in
        h)
            echo "Usage: $0 [--help] [--update-helix]"
            exit 0
        ;;
        i) INSTALL_HELIX=true ;;
        u) UPDATE_HELIX=true ;;
        -) case $OPTARG in
                help)
                    echo "Usage: $0 [--help] [--update-helix]"
                    exit 0
                ;;
                install-helix) INSTALL_HELIX=true ;;
                update-helix) UPDATE_HELIX=true ;;
        esac ;;
    esac
done

# Check if Rust is installed
if ! command -v cargo &> /dev/null; then
    echo "Rust is not installed. Installing Rust and desired crates."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    # Install desired crates
    cargo install atuin bacon bat bottom cargo-update eza fd-find ripgrep sd tealdeer topgrade wallust zoxide
    # cargo install --locked gitui
    cargo install --locked yazi-fm yazi-cli
    cargo install --locked zellij
    cargo install --locked dysk
    cargo install --locked ast-grep
else
    echo "Rust is already installed. Skipping Rust installation."
fi

HELIXDIR=~/.local/share/helix
if $INSTALL_HELIX; then
    echo "Cloning Helix"
    mkdir -p $HELIXDIR
    git clone https://github.com/helix-editor/helix $HELIXDIR
fi

if $UPDATE_HELIX; then
    echo "Updating helix and installing LSPs and debuggers."
    bash ~/scripts/update-helix.sh -d $HELIXDIR
    bash ~/scripts/helix-lsp.sh
fi