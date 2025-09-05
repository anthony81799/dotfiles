#!/usr/bin/env bash

# Parse arguments
UPDATE_HELIX=false
while getopts "h-:u-:" opt; do
  case $opt in
  h)
    echo "Usage: $0 [--help] [--update-helix]"
    exit 0
    ;;
  u) UPDATE_HELIX=true ;;
  -) case $OPTARG in
    help)
      echo "Usage: $0 [--help] [--update-helix]"
      exit 0
      ;;
    update-helix) UPDATE_HELIX=true ;;
    esac ;;
  esac
done

# Install Rust
echo "Install Rust and desired crates."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install atuin bacon bat bottom cargo-update eza fd-find ripgrep sd tealdeer topgrade wallust zoxide
# cargo install --locked gitui
cargo install --locked yazi-fm yazi-cli
cargo install --locked zellij
cargo install --locked dysk
cargo install --locked ast-grep

echo "Creating repos folder and cloning Helix"
mkdir ~/repos
git clone https://github.com/helix-editor/helix ~/repos/helix

if $UPDATE_HELIX; then
  echo "Updating helix and installing LSPs and debuggers."
  bash ~/scripts/update-helix.sh
  bash ~/scripts/helix-lsp.sh
fi
