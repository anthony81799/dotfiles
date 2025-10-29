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

# Defaults
INSTALL_RUST=false
INSTALL_HELIX=false
UPDATE_HELIX=false
HELIX_SCRIPT="${HOME}/install/terminal/helix.sh"

# Step 1: menu
CHOICES=$(
    gum choose --no-limit \
        "Install or Reinstall Rust (rustup + crates)" \
        "Install Helix Editor" \
        "Update Helix Editor and install LSPs"
)

while IFS= read -r CHOICE; do
    case "$CHOICE" in
    "Install or Reinstall Rust (rustup + crates)") INSTALL_RUST=true ;;
    "Install Helix Editor") INSTALL_HELIX=true ;;
    "Update Helix Editor and install LSPs") UPDATE_HELIX=true ;;
    esac
done <<<"$CHOICES"

# Helper to ensure cargo in path after rustup
ensure_cargo_env() {
    if [ -f "${HOME}/.cargo/env" ]; then
        # shellcheck disable=SC1090
        source "${HOME}/.cargo/env"
    fi
}

# Step 2: Rust install
if [ "$INSTALL_RUST" = true ]; then
    spinner "Installing Rust (rustup)..."
    # Install rustup non-interactively
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    ensure_cargo_env

    spinner "Installing common Rust crates..."
    # We want the script to continue if a specific crate fails; record failures.
    FAILED_CRATES=()
    CRATES=(
        "atuin" "bacon" "bat" "bottom" "cargo-update" "eza" "fd-find"
        "ripgrep" "sd" "tealdeer" "topgrade" "wallust" "zoxide"
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
else
    info_message "Rust installation skipped."
fi

# Step 3: Helix - call separate script (if requested)
if [ "$INSTALL_HELIX" = true ] || [ "$UPDATE_HELIX" = true ]; then
    if [ ! -x "$HELIX_SCRIPT" ]; then
        fail_message "Helix script not found or not executable: ${HELIX_SCRIPT}"
        info_message "Please ensure helix.sh exists and is executable."
        exit 1
    fi

    # Ensure git available
    if ! command -v git &>/dev/null; then
        spinner "Installing git..." -- sudo dnf install -y git
    fi

    spinner "Running Helix setup script..."
    bash "$HELIX_SCRIPT"
fi

finish "Rust + Helix installation complete!"
