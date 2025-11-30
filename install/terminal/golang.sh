#!/usr/bin/env bash
# ===============================================
# Golang installer / updater
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library
source "${HOME}/install/lib.sh"

LOG_FILE="${LOG_DIR}/go-install.log"
init_log "$LOG_FILE"

ensure_gum

banner "Installing or Updating Go Toolchain"

# Default options
INSTALL_GO=false
UPDATE_GO=false

# --- Functions ---
install_go_binary() {
	banner "Go Fresh Installation"
	local GOLATESTURL="https://go.dev/VERSION?m=text"
	local GOLATEST
	local ARCHIVE

	spinner "Finding latest Go version from $GOLATESTURL..."
	GOLATEST=$(curl -sL "$GOLATESTURL" | head -n1) || {
		fail_message "Failed to fetch latest Go version. Aborting installation."
		return 1
	}
	log "Latest Go version found: $GOLATEST"

	ARCHIVE="${GOLATEST}.linux-amd64.tar.gz"

	spinner "Downloading Go $GOLATEST..."
	wget "https://go.dev/dl/$ARCHIVE" || {
		fail_message "Failed to download Go archive."
	}

	spinner "Extracting Go archive to /usr/local/..." -- sudo tar -C /usr/local -xzf "$ARCHIVE" || {
		rm -f "$ARCHIVE"
		fail_message "Failed to extract Go archive."
	}

	rm -f "$ARCHIVE"

	# Refresh PATH for current session and disable telemetry
	export PATH="/usr/local/go/bin:$PATH"
	log "Updated PATH for current session: $PATH"

	if has_cmd go; then
		go version
		spinner "Disabling Go telemetry..."
		go telemetry off || warn_message "Failed to disable Go telemetry."
	fi

	okay_message "Go installation completed successfully."
}

update_go_binary() {
	banner "Go Update"
	spinner "Running go-up script to update Go..."
	curl -sL https://raw.githubusercontent.com/DieTime/go-up/master/go-up.sh | bash || {
		fail_message "Failed to update Go using go-up script."
	}

	if [ -d "/usr/local/go/bin" ]; then
		export PATH="/usr/local/go/bin:$PATH"
	fi

	okay_message "Go updated successfully."
}

install_go_tools() {
	if ! has_cmd go; then
		warn_message "Go command not found. Skipping Go tool installation."
		return 1
	fi

	local GO_TOOLS=(
		"lazygit (Git TUI, for use with Git)"
		"shfmt (Shell script formatter)"
		"glow (Markdown renderer, for use with 'bat')"
		"gopls (Go Language Server, for use with Helix/neovim)"
		"goimports (Go Imports Formatter)"
		"dlv (Go Debugger)"
		"golangci-lint (Fast Go Linter)"
	)

	local INSTALL_CHOICES
	INSTALL_CHOICES=$(
		gum choose --no-limit \
			--header "Select optional Go tools to install (Go version: $(go version | awk '{print $3}'))" \
			"${GO_TOOLS[@]}" ||
			true # Allow user to exit without selection
	)

	if [ -z "$INSTALL_CHOICES" ]; then
		info_message "No optional Go tools selected."
		return 0
	fi

	local FAILED_TOOLS=()
	local TOOL_NAME=""
	local TOOL_PATH=""

	while IFS= read -r CHOICE; do
		TOOL_NAME=$(echo "$CHOICE" | awk '{print $1}') # Get just the tool name (e.g., lazygit)

		case "$CHOICE" in
		"lazygit (Git TUI, for use with Git)") TOOL_PATH="github.com/jesseduffield/lazygit@latest" ;;
		"shfmt (Shell script formatter)") TOOL_PATH="mvdan.cc/sh/v3/cmd/shfmt@latest" ;;
		"glow (Markdown renderer, for use with 'bat')") TOOL_PATH="github.com/charmbracelet/glow/v2@latest" ;;
		"gopls (Go Language Server, for use with Helix/neovim)") TOOL_PATH="golang.org/x/tools/gopls@latest" ;;
		"goimports (Go Imports Formatter)") TOOL_PATH="golang.org/x/tools/cmd/goimports@latest" ;;
		"dlv (Go Debugger)") TOOL_PATH="github.com/go-delve/delve/cmd/dlv@latest" ;;
		"golangci-lint (Fast Go Linter)") TOOL_PATH="github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest" ;;
		*)
			warn_message "Unknown selection: $CHOICE"
			continue
			;;
		esac

		spinner "Installing $TOOL_NAME..."
		go install "$TOOL_PATH" || FAILED_TOOLS+=("$TOOL_NAME")
	done <<<"$INSTALL_CHOICES"

	if [ "${#FAILED_TOOLS[@]}" -ne 0 ]; then
		warn_message "Failed to install some Go tools: ${FAILED_TOOLS[*]}"
	else
		okay_message "All selected Go tools installed successfully."
	fi
}

# Step 1: Options menu
CHOICE=$(
	gum choose \
		--header "Select Go installation option" \
		"Install Go" \
		"Update existing Go installation"
)

case "$CHOICE" in
"Install Go") INSTALL_GO=true ;;
"Update existing Go installation") UPDATE_GO=true ;;
esac

# Step 2: Determine actual course of action (Install/Update/Reinstall)
if [ "$INSTALL_GO" = true ]; then
	spinner "Checking for existing Go installation..."

	if has_cmd go; then
		EXISTING_VER=$(go version | awk '{print $3}')
		info_message "Existing Go installation detected: $EXISTING_VER"

		if gum confirm "Skip fresh install and update Go instead?"; then
			info_message "Skipping full installation — proceeding to update..."
			INSTALL_GO=false
			UPDATE_GO=true
		else
			info_message "Reinstalling Go from scratch. Removing /usr/local/go..."
			spinner "Removing existing Go installation..."
			sudo rm -rf /usr/local/go || {
				fail_message "Failed to remove existing Go installation. Aborting fresh install."
				INSTALL_GO=false
			}
		fi
	else
		info_message "No existing Go installation detected. Proceeding with fresh install."
	fi
fi

# Step 3: Execute installation or update
if [ "$INSTALL_GO" = true ]; then
	install_go_binary
fi

if [ "$UPDATE_GO" = true ]; then
	update_go_binary
fi

# Step 4: Tool installation menu (only if an install or update was performed)
if [ "$INSTALL_GO" = true ] || [ "$UPDATE_GO" = true ]; then
	install_go_tools
fi

finish "Go Toolchain setup complete."
