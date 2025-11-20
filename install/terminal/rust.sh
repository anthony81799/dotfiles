#!/usr/bin/env bash
# ===============================================
# Rust + Helix installer/updater
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library
source "${HOME}/install/lib.sh"

init_log "${LOG_DIR}/rust-install.log"

ensure_gum

banner "Rust Toolchain and Helix Editor Installation"

# --- 1. Dependency Checks ---
for cmd in curl git; do
  if ! has_cmd "$cmd"; then
    warn_message "Command '$cmd' not found. Installing..."
    sudo dnf install -y "$cmd" || {
      fail_message "Failed to install $cmd. Aborting installation."
    }
    okay_message "'$cmd' installed."
  fi
done

# Defaults
INSTALL_RUST=false
INSTALL_HELIX=false
HELIX_SCRIPT="${HOME}/install/terminal/helix.sh"

# --- 2. Menu Selection ---
CHOICES=$(
  gum choose \
    --header "Select components to install/update" \
    "Rust (rustup + crates)" \
    "Helix (editor + LSPs)"
)

while IFS= read -r CHOICE; do
  case "$CHOICE" in
  "Rust (rustup + crates)") INSTALL_RUST=true ;;
  "Helix (editor + LSPs)") INSTALL_HELIX=true ;;
  esac
done <<<"$CHOICES"

ensure_cargo_env() {
  export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
  export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
  export CARGO_HOME="$XDG_DATA_HOME/cargo"

  RUSTUP_ENV_FILE="${RUSTUP_HOME}/env"

  if [ -f "$RUSTUP_ENV_FILE" ]; then
    log "Sourcing rustup environment from $RUSTUP_ENV_FILE"
    # shellcheck disable=SC1090
    source "$RUSTUP_ENV_FILE"
  elif [ -f "${HOME}/.cargo/env" ]; then
    log "Sourcing rustup environment from ${HOME}/.cargo/env (default location)"
    # shellcheck disable=SC1090
    source "${HOME}/.cargo/env"
  else
    warn_message "Could not find a Rust environment file. Subsequent cargo commands may fail."
  fi
}

# --- 3. Rust Toolchain Installation ---
if [ "$INSTALL_RUST" = true ]; then
  spinner "Installing Rust (rustup) to $CARGO_HOME and $RUSTUP_HOME..."

  export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
  export CARGO_HOME="$XDG_DATA_HOME/cargo"
  export RUSTUP_HOME="$XDG_DATA_HOME/rustup"

  # Install rustup non-interactively and check for success
  if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
    okay_message "Rust (rustup) installation complete."
  else
    fail_message "Failed to install Rust (rustup). Check log for details."
  fi

  ensure_cargo_env

  if ! has_cmd cargo; then
    fail_message "Cargo command not found after rustup installation. Cannot install crates. Aborting Rust setup."
  fi

  spinner "Installing cargo-binstall for faster Rust binary installs..."
  if cargo install cargo-binstall; then
    okay_message "cargo-binstall installed."
    INSTALL_BINSTALL=true
  else
    warn_message "Failed to install cargo-binstall. Falling back to 'cargo install' for crates."
    INSTALL_BINSTALL=false
  fi

  spinner "Installing common Rust crates..."
  FAILED_CRATES=()
  CRATES=(
    "ast-grep" "atuin" "bacon" "bat" "bottom" "broot" "cargo-update" "du-dust"
    "dysk" "eza" "fd-find" "hyperfine" "procs" "ripgrep" "sd" "tealdeer"
    "topgrade" "xplr" "zellij" "zoxide"
  )

  for c in "${CRATES[@]}"; do
    if [ "$INSTALL_BINSTALL" = true ]; then
      if ! cargo binstall --no-confirm "$c"; then
        FAILED_CRATES+=("$c")
      fi
    else
      if ! cargo install "$c"; then
        FAILED_CRATES+=("$c")
      fi
    fi
  done

  if [ "${#FAILED_CRATES[@]}" -ne 0 ]; then
    warn_message "Some cargo installs failed: ${FAILED_CRATES[*]}"
    info_message "You may need to manually install these with 'cargo install <crate>'."
  else
    okay_message "All selected Rust crates installed successfully."
  fi

else
  info_message "Rust toolchain installation skipped."
fi

# --- 4. Helix Setup ---
if [ "$INSTALL_HELIX" = true ]; then
  if [ ! -x "$HELIX_SCRIPT" ]; then
    fail_message "Helix script not found or not executable: ${HELIX_SCRIPT}. Aborting Helix setup."
  fi

  spinner "Running Helix setup script: ${HELIX_SCRIPT}..."
  if bash "$HELIX_SCRIPT"; then
    okay_message "Helix editor installation/update complete."
  else
    fail_message "Helix setup script failed. Check ${LOG_DIR}/helix-install.log for details."
  fi
else
  info_message "Helix editor installation skipped."
fi

finish "Rust + Helix installation complete!"
