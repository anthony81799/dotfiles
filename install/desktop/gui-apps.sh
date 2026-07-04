#!/usr/bin/env bash
# ===============================================
# GUI Applications Installer (Optimized)
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library and initialize logging
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "${DOTFILES_DIR}/install/lib.sh"

LOG_FILE="${LOG_DIR}/gui-apps-install.log"
init_log "$LOG_FILE"

ensure_gum

banner "GUI Applications Installation"

# --- 1. DNF Package Installation ---
DNF_PACKAGES=(
	"dolphin"          # Dolphin File Manager
	"thunderbird"      # Thunderbird Email Client
	"discord"          # Discord
	"dnf-plugins-core" # Required for config-manager used in Brave setup
	"xdg-utils"        # Required for xdg-settings
)

info_message "Installing core GUI applications..."
if ! sudo dnf install -y "${DNF_PACKAGES[@]}"; then
	warn_message "Some core DNF packages failed to install. Check $LOG_FILE for details."
else
	okay_message "Core GUI applications installed successfully."
fi

# --- 2. Brave Browser Installation ---
if ! has_cmd brave-browser; then
	info_message "Starting Brave Browser installation..."

	sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo

	BRAVE_INSTALLED=false
	info_message "Installing Brave Browser..."
	if sudo dnf install -y brave-browser; then
		BRAVE_INSTALLED=true
		okay_message "Brave Browser installed."
	else
		warn_message "Failed to install Brave Browser. Check $LOG_FILE for details."
	fi
else
	info_message "Brave Browser already installed."
	BRAVE_INSTALLED=true
fi

if [[ "$BRAVE_INSTALLED" == true ]]; then
	info_message "Attempting to set Brave Browser as default web browser..."
	if has_cmd xdg-settings; then
		if xdg-settings set default-web-browser brave-browser.desktop; then
			okay_message "Brave Browser set as default web browser."
		else
			warn_message "Failed to set Brave Browser as default using xdg-settings (requires active graphical session)."
		fi
	else
		warn_message "xdg-settings not found. Cannot set Brave Browser as default."
	fi
fi

# --- 3. LocalSend File Sharing ---
# Installed as a native binary straight from upstream's GitHub release (not
# Flatpak or AppImage). The Flatpak sandboxes UDP broadcast/multicast, which
# breaks LocalSend's mDNS-based device discovery; a native binary has full,
# unsandboxed network access and just works.
LOCALSEND_INSTALL_DIR="/usr/share/localsend_app"
LOCALSEND_BIN="/usr/bin/localsend_app"

if has_cmd flatpak && flatpak info org.localsend.localsend_app &>/dev/null; then
	info_message "Removing broken Flatpak build of LocalSend..."
	sudo flatpak uninstall -y org.localsend.localsend_app || warn_message "Failed to remove the Flatpak build of LocalSend."
fi

info_message "Checking for the latest LocalSend release..."
LOCALSEND_LATEST_TAG="$(curl -fsSL https://api.github.com/repos/localsend/localsend/releases/latest 2>/dev/null | grep -m1 '"tag_name"' | cut -d '"' -f4 || true)"

if [[ -z "$LOCALSEND_LATEST_TAG" ]]; then
	warn_message "Could not reach GitHub to determine the latest LocalSend version. Skipping LocalSend installation."
else
	LOCALSEND_LATEST_VERSION="${LOCALSEND_LATEST_TAG#v}"
	LOCALSEND_INSTALLED_VERSION=""
	[[ -f "${LOCALSEND_INSTALL_DIR}/.version" ]] && LOCALSEND_INSTALLED_VERSION="$(cat "${LOCALSEND_INSTALL_DIR}/.version")"

	if [[ "$LOCALSEND_INSTALLED_VERSION" == "$LOCALSEND_LATEST_VERSION" ]]; then
		info_message "LocalSend v${LOCALSEND_LATEST_VERSION} is already installed."
	else
		info_message "Installing LocalSend v${LOCALSEND_LATEST_VERSION} as a native binary..."

		if ! sudo dnf install -y libayatana-appindicator-gtk3 libayatana-ido-gtk3 xdg-user-dirs; then
			warn_message "Failed to install some LocalSend runtime dependencies. Check $LOG_FILE for details."
		fi

		LOCALSEND_TMP_DIR="$(mktemp -d)"
		LOCALSEND_TARBALL="LocalSend-${LOCALSEND_LATEST_VERSION}-linux-x86-64.tar.gz"
		LOCALSEND_URL="https://github.com/localsend/localsend/releases/download/${LOCALSEND_LATEST_TAG}/${LOCALSEND_TARBALL}"

		if curl -fsSL -o "${LOCALSEND_TMP_DIR}/localsend.tar.gz" "$LOCALSEND_URL" &&
			tar -xzf "${LOCALSEND_TMP_DIR}/localsend.tar.gz" -C "$LOCALSEND_TMP_DIR"; then

			sudo rm -rf "$LOCALSEND_INSTALL_DIR"
			sudo mkdir -p "$LOCALSEND_INSTALL_DIR"
			sudo cp -r "${LOCALSEND_TMP_DIR}/data" "${LOCALSEND_TMP_DIR}/lib" "${LOCALSEND_TMP_DIR}/localsend_app" "$LOCALSEND_INSTALL_DIR/"
			echo "$LOCALSEND_LATEST_VERSION" | sudo tee "${LOCALSEND_INSTALL_DIR}/.version" >/dev/null

			sudo ln -sf "${LOCALSEND_INSTALL_DIR}/localsend_app" "$LOCALSEND_BIN"

			sudo install -Dm644 "${LOCALSEND_INSTALL_DIR}/data/flutter_assets/assets/img/logo-128.png" \
				/usr/share/icons/hicolor/128x128/apps/localsend_app.png
			sudo install -Dm644 "${LOCALSEND_INSTALL_DIR}/data/flutter_assets/assets/img/logo-256.png" \
				/usr/share/icons/hicolor/256x256/apps/localsend_app.png

			sudo tee /usr/share/applications/localsend_app.desktop >/dev/null <<-EOF
				[Desktop Entry]
				Type=Application
				Version=${LOCALSEND_LATEST_VERSION}
				Name=LocalSend
				GenericName=An open source cross-platform alternative to AirDrop
				Icon=localsend_app
				Exec=localsend_app %U
				Categories=GTK;FileTransfer;Utility;
				Keywords=Sharing;LAN;Files;
				StartupNotify=true
			EOF

			has_cmd update-desktop-database && sudo update-desktop-database /usr/share/applications &>/dev/null
			has_cmd gtk-update-icon-cache && sudo gtk-update-icon-cache /usr/share/icons/hicolor &>/dev/null

			okay_message "LocalSend v${LOCALSEND_LATEST_VERSION} installed natively to ${LOCALSEND_INSTALL_DIR}."
		else
			warn_message "Failed to download or extract LocalSend. Check $LOG_FILE for details."
		fi

		rm -rf "$LOCALSEND_TMP_DIR"
	fi
fi

# --- 4. Obsidian Note-Taking App ---
if has_cmd flatpak; then
	if ! flatpak info md.obsidian.Obsidian &>/dev/null; then
		info_message "Installing Obsidian via Flatpak..."

		if sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
			if flatpak install flathub md.obsidian.Obsidian -y; then
				okay_message "Obsidian (Flatpak) installed."
			else
				warn_message "Failed to install Obsidian via Flatpak. Check $LOG_FILE for details."
			fi
		else
			warn_message "Failed to add Flathub repository. Skipping Obsidian installation."
		fi
	else
		info_message "Obsidian (Flatpak) is already installed."
	fi
else
	warn_message "Flatpak not installed. Skipping Obsidian installation. Please install Flatpak/Obsidian manually."
fi

# --- 5. Call Helper Scripts for GUI Editors and Terminal Emulators ---
EDITOR_SCRIPT="${DOTFILES_DIR}/install/desktop/editor.sh"
TERMINAL_SCRIPT="${DOTFILES_DIR}/install/desktop/terminal-emulator.sh"

# Run editor script
if [ -x "$EDITOR_SCRIPT" ]; then
	info_message "Running GUI Editor setup script ($EDITOR_SCRIPT)..."
	if bash "$EDITOR_SCRIPT"; then
		okay_message "GUI Editor setup completed."
	else
		warn_message "GUI Editor setup script failed."
	fi
else
	warn_message "GUI Editor script not found or not executable: $EDITOR_SCRIPT. Skipping."
fi

if [ -x "$TERMINAL_SCRIPT" ]; then
	info_message "Running Terminal Emulator setup script ($TERMINAL_SCRIPT)..."
	if bash "$TERMINAL_SCRIPT"; then
		okay_message "Terminal Emulator setup completed."
	else
		warn_message "Terminal Emulator setup script failed."
	fi
else
	warn_message "Terminal Emulator script not found or not executable: $TERMINAL_SCRIPT. Skipping."
fi

finish "GUI Applications installation complete."
