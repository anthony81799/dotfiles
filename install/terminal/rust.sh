#!/usr/bin/env bash
# ===============================================
# Rust installer
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "${DOTFILES_DIR}/install/lib.sh"

LOG_FILE="${LOG_DIR}/rust-install.log"
init_log "$LOG_FILE"

ensure_gum

banner "Rust Toolchain Installation"

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

ensure_cargo_env() {
	export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
	export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
	export CARGO_HOME="$XDG_DATA_HOME/cargo"

	local rustup_env_file="${RUSTUP_HOME}/env"

	if [ -f "$rustup_env_file" ]; then
		log "Sourcing rustup environment from $rustup_env_file"
		# shellcheck disable=SC1090,SC1091
		source "$rustup_env_file"
	elif [ -f "${HOME}/.cargo/env" ]; then
		log "Sourcing rustup environment from ${HOME}/.cargo/env (default location)"
		# shellcheck disable=SC1090,SC1091
		source "${HOME}/.cargo/env"
	else
		warn_message "Could not find a Rust environment file. Subsequent cargo commands may fail."
	fi
}

info_message "Installing Rust (rustup) to $CARGO_HOME and $RUSTUP_HOME..."

export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"

CRATES=(
	"ast-grep" "bacon" "bat" "bottom" "cargo-info" "cargo-update" "cargo-cache"
	"du-dust" "dysk" "eza" "fd-find" "git-delta" "hyperfine" "procs" "ripgrep"
	"rusty-man" "sd" "tealdeer" "tokei" "topgrade" "xplr" "zellij" "zoxide"
)

# Crates whose installed binary name differs from the crate name
declare -A CRATE_BIN_OVERRIDES=(
	["du-dust"]="dust"
	["ripgrep"]="rg"
	["fd-find"]="fd"
	["git-delta"]="delta"
	["tealdeer"]="tldr"
	["bottom"]="btm"
)

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

info_message "Installing cargo-binstall for faster Rust binary installs..."
if cargo install cargo-binstall; then
	okay_message "cargo-binstall installed."
	INSTALL_BINSTALL=true
else
	warn_message "Failed to install cargo-binstall. Falling back to 'cargo install' for crates."
	INSTALL_BINSTALL=false
fi

info_message "Installing common Rust crates..."
if [ "$INSTALL_BINSTALL" = true ]; then
	# Parallel binstall — saturates your download bandwidth
	printf '%s\n' "${CRATES[@]}" | xargs -P "$(nproc)" -I{} \
		cargo binstall --no-confirm --no-symlinks {} 2>>"$LOG_FILE" ||
		warn_message "Some crates failed, check log"
else
	# No prebuilt binaries available — compile from source one at a time
	printf '%s\n' "${CRATES[@]}" | xargs -P 1 -I{} \
		cargo install {} 2>>"$LOG_FILE" ||
		warn_message "Some crates failed, check log"
fi

FAILED_CRATES=()
for crate in "${CRATES[@]}"; do
	bin_name="${CRATE_BIN_OVERRIDES[$crate]:-$crate}"
	if ! has_cmd "$bin_name"; then
		FAILED_CRATES+=("$crate")
	fi
done
if [[ ${#FAILED_CRATES[@]} -gt 0 ]]; then
	warn_message "These crates may not have installed: ${FAILED_CRATES[*]}"
fi

finish "Rust installation complete!"
