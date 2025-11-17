#!/usr/bin/env bash
# ===============================================
# Desktop Environment installer
# ===============================================
set -euo pipefail
IFS=$'\n\t'

export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

if ! command -v git &>/dev/null; then
	echo "--- Git is required but not installed. Installing it now... ---"
	if ! sudo dnf install -y git; then
		echo "!!! ERROR: Failed to install Git. Aborting. !!!"
		exit 1
	fi
	echo "--- Git installed successfully. ---"
fi

config() {
	/usr/bin/git --git-dir="$HOME/.cfg/" --work-tree="$HOME" "$@"
}

if [ ! -d "$HOME/.cfg" ]; then
	echo "--- Cloning dotfiles repository... ---"
	if ! git clone --bare --depth=1 https://github.com/anthony81799/dotfiles.git "$HOME/.cfg"; then
		echo "!!! ERROR: Failed to clone dotfiles repo. Aborting. !!!"
		exit 1
	fi

	if ! config checkout --force; then
		echo "!!! ERROR: Failed to checkout dotfiles. Aborting. !!!"
		exit 1
	fi
	echo "--- Dotfiles cloned and checked out. ---"
else
	echo "--- Dotfiles repository already exists. Updating... ---"
	if ! config pull --ff-only; then
		echo "!!! WARNING: Failed to pull latest dotfiles. Continuing. !!!"
	fi
	if ! config checkout --force; then
		echo "!!! WARNING: Failed to force checkout dotfiles. Continuing. !!!"
	fi
fi

source "${HOME}/install/lib.sh"

LOG_FILE="${LOG_DIR}/setup.log"
init_log "$LOG_FILE"

ensure_gum

banner "Starting dotfiles setup and installation"

# Variables for user choices
INSTALL_DESKTOP=false
INSTALL_TERMINAL=false

# --- 1. Installation Type Menu ---
INSTALL_TYPE=$(
	gum choose \
		--header "Select installation type" \
		"Full Desktop" \
		"Terminal Only"
)

case "$INSTALL_TYPE" in
"Full Desktop") INSTALL_DESKTOP=true ;;
"Terminal Only") INSTALL_TERMINAL=true ;;
esac

# --- 2. DNF Performance Tweaks ---
spinner "Optimizing DNF configuration for faster downloads..."

DNF_CONFIG="/etc/dnf/dnf.conf"

if [ -f "$DNF_CONFIG" ]; then
	log "Updating $DNF_CONFIG under [main]."

	# 1. Delete existing lines (consolidated for efficiency)
	sudo sed -i '/^gpgcheck=/d;/^installonly_limit=/d;/^clean_requirements_on_remove=/d;/^max_parallel_downloads=/d;/^fastestmirror=/d;/^skip_if_unavailable=/d;/^defaultyes=/d' "$DNF_CONFIG"

	# 2. Insert new lines after [main] (consolidated for efficiency)
	sudo sed -i '/\[main\]/a defaultyes=True\nskip_if_unavailable=True\nfastestmirror=True\nmax_parallel_downloads=10\nclean_requirements_on_remove=True\ninstallonly_limit=3\ngpgcheck=0' "$DNF_CONFIG"

	okay_message "DNF optimized for faster downloads."
else
	warn_message "DNF configuration file ($DNF_CONFIG) not found. Skipping DNF optimization."
fi

# --- 3. Run Installations ---
if [ "$INSTALL_DESKTOP" = true ]; then
	spinner "Starting Desktop installation script..."
	bash "${HOME}/install/desktop/install-desktop.sh" || fail_message "Desktop installation script failed. Check log for details."

	INSTALL_TERMINAL=true
fi

if [ "$INSTALL_TERMINAL" = true ]; then
	spinner "Starting Terminal utilities installation script..."
	bash "${HOME}/install/terminal/install-terminal.sh" || fail_message "Terminal installation script failed. Check log for details."
fi

finish "The installation is finished!"

fastfetch
