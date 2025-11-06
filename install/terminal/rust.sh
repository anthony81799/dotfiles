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

banner "Installing Rust and Helix Editor"

# Defaults
INSTALL_RUST=false
INSTALL_HELIX=false
HELIX_SCRIPT="${HOME}/install/terminal/helix.sh"

# Step 1: menu
CHOICES=$(
    gum choose \
        "Install or Reinstall Rust (rustup + crates)" \
        "Install / Update Helix Editor and install LSPs"
)

while IFS= read -r CHOICE; do
    case "$CHOICE" in
    "Install or Reinstall Rust (rustup + crates)") INSTALL_RUST=true ;;
    "Install / Update Helix Editor and install LSPs") INSTALL_HELIX=true ;;
    esac
done <<<"$CHOICES"

# Helper to ensure cargo in path after rustup
ensure_cargo_env() {
    export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    export RUSTUP_HOME="$XDG_DATA_HOME/rustup"

    # RUSTUP_HOME/env is where rustup puts the path setup script when RUSTUP_HOME is set
    RUSTUP_ENV_FILE="${RUSTUP_HOME}/env"

    if [ -f "$RUSTUP_ENV_FILE" ]; then
        # shellcheck disable=SC1090
        source "$RUSTUP_ENV_FILE"
    # Fallback to the default path if RUSTUP_HOME wasn't set or environment is unexpected
    elif [ -f "${HOME}/.cargo/env" ]; then
        # shellcheck disable=SC1090
        source "${HOME}/.cargo/env"
    fi
}

# Step 2: Rust install
if [ "$INSTALL_RUST" = true ]; then
    spinner "Installing Rust (rustup)..."

    export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    export CARGO_HOME="$XDG_DATA_HOME/cargo"
    export RUSTUP_HOME="$XDG_DATA_HOME/rustup"

    # Install rustup non-interactively
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    ensure_cargo_env

    spinner "Installing common Rust crates..."
    # We want the script to continue if a specific crate fails; record failures.
    FAILED_CRATES=()
    CRATES=(
        "atuin" "bacon" "bat" "bluetui" "bottom" "cargo-update" "eza" "fd-find"
        "impala" "ripgrep" "sd" "tealdeer" "topgrade" "wallust" "wiremix" "zoxide"
    )
    for c in "${CRATES[@]}"; do
        if ! cargo install "$c"; then
            FAILED_CRATES+=("$c")
        fi
    done

    # Some crates installed locked/with options
    for c in "yazi-fm" "yazi-cli" "zellij" "dysk" "ast-grep"; do
        if ! cargo install --locked "$c"; then
            FAILED_CRATES+=("$c")
        fi
    done

    if [ "${#FAILED_CRATES[@]}" -ne 0 ]; then
        warn_message "Some cargo installs failed: ${FAILED_CRATES[*]}"
    else
        okay_message "All cargo installs completed."
    fi

    if gum confirm "Do you want to install Helix?"; then
        spinner "Installing Helix and LSPs..."

        $INSTALL_HELIX=true
    else
        info_message "Helix installation skipped."
    fi
else
    info_message "Rust installation skipped."
fi

# Step 3: Helix - call separate script (if requested)
if [ "$INSTALL_HELIX" = true ]; then
    if [ ! -x "$HELIX_SCRIPT" ]; then
        fail_message "Helix script not found or not executable: ${HELIX_SCRIPT}"
        info_message "Please ensure helix.sh exists and is executable."
        return 1
    fi

    # Ensure git available
    if ! command -v git &>/dev/null; then
        spinner "Installing git..."
        sudo dnf install -y git
    fi

    spinner "Running Helix setup script..."
    bash "$HELIX_SCRIPT"
fi

finish "Rust + Helix installation complete!"
