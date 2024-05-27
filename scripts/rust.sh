#!/usr/bin/env bash

# Install Rust once main install is finished.
echo "Install Rust and desired crates."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install atuin bacon bat bottom cargo-update eza fd-find gitui ripgrep sd tealdeer topgrade zoxide
cargo install --locked yazi-fm yazi-cli
cargo install --locked zellij