#!/usr/bin/env bash
# ===============================================
# Terminal Editor Installer
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library and initialize logging
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "${DOTFILES_DIR}/install/lib.sh"

LOG_FILE="${LOG_DIR}/terminal-editor.log"
init_log "$LOG_FILE"

ensure_gum

banner "Terminal Editor Installation"

INSTALL_NEOVIM=false
INSTALL_HELIX=false
INSTALL_DOOM=false

# --- Functions ---
install_neovim() {
	banner "Neovim Installation"

	info_message "Installing Neovim via DNF..."
	sudo dnf install -y neovim || {
		fail_message "Failed to install Neovim via DNF. Check $LOG_FILE for details."
	}

	# 2. Install optional Python client (for providers)
	if has_cmd pip; then
		info_message "Installing Python Neovim client (pip install neovim)..."
		pip install --break-system-packages neovim \
		&& pip show neovim | grep ^Version \
		|| warn_message "Failed to install Python Neovim client."
	else
		info_message "pip not found. Skipping Python Neovim client install."
	fi

	# 3. Install optional Node.js client (for providers/LSPs)
	if has_cmd npm; then
		info_message "Installing Node.js Neovim client (npm install -g neovim)..."
		npm install -g neovim || {
			warn_message "Failed to install Node.js Neovim client. Proceeding."
		}
	else
		info_message "npm not found. Skipping Node.js Neovim client install."
	fi

	okay_message "Neovim installed and clients configured."
}

install_helix() {
	banner "Helix Editor Installation"

	if [[ ! -x "${DOTFILES_DIR}/install/terminal/helix.sh" ]]; then
		fail_message "helix.sh not found or not executable."
	fi

	info_message "Running Helix installation script: ${DOTFILES_DIR}/install/terminal/helix.sh"
	bash "${DOTFILES_DIR}/install/terminal/helix.sh" || {
		fail_message "Helix installation script failed. Check $LOG_FILE for details."
	}
	okay_message "Helix installed successfully."
}

install_doom() {
	banner "Doom Emacs Installation"

	info_message "Installing Emacs via DNF..."
	sudo dnf install -y emacs || {
		fail_message "Failed to install Emacs via DNF. Check $LOG_FILE for details."
	}

	local emacs_dir="${XDG_CONFIG_HOME:-$HOME/.config}/emacs"
	if [[ ! -d "${emacs_dir}/.git" ]]; then
		info_message "Cloning Doom Emacs into ${emacs_dir}..."
		git clone --depth 1 https://github.com/doomemacs/doomemacs "$emacs_dir" || {
			fail_message "Failed to clone Doom Emacs."
		}
	fi

	info_message "Installing doom doctor language tools..."
	sudo dnf install -y tidy || warn_message "Failed to install tidy."
	if has_cmd go; then
		go install github.com/fatih/gomodifytags@latest \
		&& go install github.com/cweill/gotests/gotests@latest \
		&& go install github.com/x-motemen/gore/cmd/gore@latest \
		|| warn_message "Failed to install Go tools."
	fi
	if has_cmd npm; then
		npm install -g marked stylelint js-beautify || warn_message "Failed to install npm tools."
	fi
	if has_cmd uv; then
		uv tool install pytest && uv tool install pipenv || warn_message "Failed to install Python tools."
	fi

	info_message "Running doom install (config is symlinked from dotfiles)..."
	"${emacs_dir}/bin/doom" install --no-config --env || {
		fail_message "doom install failed. Check $LOG_FILE for details."
	}

	okay_message "Doom Emacs installed."
}

# --- Step 1: Main menu for installation options ---
CHOICES=$(
	gum choose --no-limit \
		--header "Select editors to install" \
		"Neovim" \
		"Helix" \
		"Doom Emacs"
)

while IFS= read -r CHOICE; do
	case "$CHOICE" in
	"Neovim") INSTALL_NEOVIM=true ;;
	"Helix") INSTALL_HELIX=true ;;
	"Doom Emacs") INSTALL_DOOM=true ;;
	esac
done <<<"$CHOICES"

# --- Step 2: Execution ---
if [ "$INSTALL_NEOVIM" = true ]; then
	install_neovim
fi

if [ "$INSTALL_HELIX" = true ]; then
	install_helix
fi

if [ "$INSTALL_DOOM" = true ]; then
	install_doom
fi

if [[ "$INSTALL_NEOVIM" == false && "$INSTALL_HELIX" == false && "$INSTALL_DOOM" == false ]]; then
    info_message "No editors selected. Skipping editor installation."
fi

finish "Terminal editor setup complete."
