#!/usr/bin/env bash
# ===============================================
# Dotfiles Installer
# ===============================================
set -euo pipefail
IFS=$'\n\t'

export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
export DOTFILES_REPO="https://github.com/anthony81799/dotfiles.git"

export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# --- 1. Ensure git is available ---
if ! command -v git &>/dev/null; then
	echo "--- Git is required but not installed. Installing it now... ---"
	if ! sudo dnf install -y git; then
		echo "!!! ERROR: Failed to install Git. Aborting. !!!"
		exit 1
	fi
	echo "--- Git installed successfully. ---"
fi

# --- 2. Clone or update dotfiles repo ---
if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
	echo "--- Cloning dotfiles repository to $DOTFILES_DIR... ---"
	if ! git clone --depth=1 "$DOTFILES_REPO" "$DOTFILES_DIR"; then
		echo "!!! ERROR: Failed to clone dotfiles repo. Aborting. !!!"
		exit 1
	fi
	echo "--- Dotfiles cloned successfully. ---"
else
	echo "--- Dotfiles repository already exists. Updating... ---"
	if ! git -C "$DOTFILES_DIR" pull --ff-only; then
		echo "!!! WARNING: Failed to pull latest dotfiles. Continuing with existing version. !!!"
	fi
fi

# --- 3. Source shared library ---
source "${DOTFILES_DIR}/install/lib.sh"

LOG_FILE="${LOG_DIR}/setup.log"
init_log "$LOG_FILE"

ensure_gum

banner "Starting dotfiles setup and installation"

# --- 4. Symlink config files ---
info_message "Linking dotfiles configuration to $XDG_CONFIG_HOME..."

_link() {
	local src="$1"
	local dst="$2"
	if [[ -e "$dst" && ! -L "$dst" ]]; then
		warn_message "Backing up existing $(basename "$dst") → ${dst}.bak"
		mv "$dst" "${dst}.bak"
	fi
	ln -sfn "$src" "$dst"
	log "Linked: $src → $dst"
}

mkdir -p "$XDG_CONFIG_HOME"

# Directories inside config/ to symlink into ~/.config/
CONFIG_DIRS=(
	alacritty atuin fastfetch fish ghostty git gitui glow
	helix kitty npm nvim oh-my-posh wezterm xplr zellij zsh
)

# Standalone files inside config/ to symlink into ~/.config/
CONFIG_FILES=(shell_aliases topgrade.toml)

for dir in "${CONFIG_DIRS[@]}"; do
	[[ -d "${DOTFILES_DIR}/config/${dir}" ]] && \
		_link "${DOTFILES_DIR}/config/${dir}" "${XDG_CONFIG_HOME}/${dir}"
done

for file in "${CONFIG_FILES[@]}"; do
	[[ -e "${DOTFILES_DIR}/config/${file}" ]] && \
		_link "${DOTFILES_DIR}/config/${file}" "${XDG_CONFIG_HOME}/${file}"
done

# .bashrc lives in $HOME
[[ -f "${DOTFILES_DIR}/config/.bashrc" ]] && \
	_link "${DOTFILES_DIR}/config/.bashrc" "${HOME}/.bashrc"

# .zshenv must live at $HOME so zsh sets ZDOTDIR before loading ~/.config/zsh/
[[ -f "${DOTFILES_DIR}/config/zsh/.zshenv" ]] && \
	_link "${DOTFILES_DIR}/config/zsh/.zshenv" "${HOME}/.zshenv"

okay_message "Dotfiles linked successfully."

# --- 5. Installation Type Menu ---
INSTALL_DESKTOP=false
INSTALL_TERMINAL=false

INSTALL_TYPE=$(
	gum choose \
		--header "Select installation type" \
		"Full Desktop" \
		"Terminal Only"
)

case "$INSTALL_TYPE" in
"Full Desktop")
	INSTALL_DESKTOP=true
	INSTALL_TERMINAL=true
	;;
"Terminal Only") INSTALL_TERMINAL=true ;;
esac

# --- 6. DNF Performance Tweaks ---
info_message "Optimizing DNF configuration for faster downloads..."

DNF_CONFIG="/etc/dnf/dnf.conf"
if [[ -f "$DNF_CONFIG" ]]; then
	log "Updating $DNF_CONFIG under [main]."
	sudo sed -i '/^gpgcheck=/d;/^installonly_limit=/d;/^clean_requirements_on_remove=/d;/^max_parallel_downloads=/d;/^fastestmirror=/d;/^skip_if_unavailable=/d;/^defaultyes=/d;/\[main\]/a defaultyes=True\nskip_if_unavailable=True\nfastestmirror=True\nmax_parallel_downloads=10\nclean_requirements_on_remove=True\ninstallonly_limit=3\ngpgcheck=0' "$DNF_CONFIG"
	okay_message "DNF optimized for faster downloads."
else
	warn_message "DNF configuration file ($DNF_CONFIG) not found. Skipping DNF optimization."
fi

# --- 7. Run Installations ---
if [[ "$INSTALL_TERMINAL" = true ]]; then
	info_message "Starting Terminal utilities installation script..."
	bash "${DOTFILES_DIR}/install/terminal/install-terminal.sh" || \
		fail_message "Terminal installation script failed. Check log for details."
fi

if [[ "$INSTALL_DESKTOP" = true ]]; then
	info_message "Starting Desktop installation script..."
	bash "${DOTFILES_DIR}/install/desktop/install-desktop.sh" || \
		fail_message "Desktop installation script failed. Check log for details."
fi

finish "The installation is finished!"
