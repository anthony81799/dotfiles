#!/usr/bin/env bash
# ===============================================
# Golang installer / updater
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library
source "${HOME}/install/lib.sh"

init_log "${LOG_DIR}/go-install.log"

ensure_gum

banner "Installing or Updating Go Toolchain"

# Default options
INSTALL_GO=false
UPDATE_GO=false
SKIPPED=false

# --- Function: Install Go Tools (User Selection) ---
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

    local INSTALL_CHOICES=$(
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

    spinner "Installing selected Go tools..."

    while IFS= read -r CHOICE; do
        local TOOL=""
        case "$CHOICE" in
        "lazygit (Git TUI, for use with Git)") TOOL="github.com/jesseduffield/lazygit@latest" ;;
        "shfmt (Shell script formatter)") TOOL="mvdan.cc/sh/v3/cmd/shfmt@latest" ;;
        "glow (Markdown renderer, for use with 'bat')") TOOL="github.com/charmbracelet/glow/v2@latest" ;;
        "gopls (Go Language Server, for use with Helix/neovim)") TOOL="golang.org/x/tools/gopls@latest" ;;
        "goimports (Go Imports Formatter)") TOOL="golang.org/x/tools/cmd/goimports@latest" ;;
        "dlv (Go Debugger)") TOOL="github.com/go-delve/delve/cmd/dlv@latest" ;;
        "golangci-lint (Fast Go Linter)") TOOL="github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest" ;;
        *)
            warn_message "Unknown selection: $CHOICE"
            continue
            ;;
        esac

        log "Installing tool: $TOOL"
        if ! go install "$TOOL"; then
            FAILED_TOOLS+=("$CHOICE")
        fi

    done <<<"$INSTALL_CHOICES"

    if [ "${#FAILED_TOOLS[@]}" -ne 0 ]; then
        warn_message "Failed to install some Go tools: ${FAILED_TOOLS[*]}"
    else
        okay_message "All selected Go tools installed successfully."
    fi
}

# ------------------------------------------------------------------
# Step 1: Options menu
# ------------------------------------------------------------------
CHOICE=$(
    gum choose \
        --header "Select Go installation option" \
        "Install Go" \
        "Update existing Go installation" \
        "Skip (Do nothing)"
)

# Parse choice
case "$CHOICE" in
"Install Go") INSTALL_GO=true ;;
"Update existing Go installation") UPDATE_GO=true ;;
"Skip (Do nothing)") SKIPPED=true ;;
esac

# ------------------------------------------------------------------
# Step 2: Installation or update
# ------------------------------------------------------------------
if [ "$INSTALL_GO" = true ]; then
    spinner "Checking for existing Go installation..."

    if command -v go &>/dev/null; then
        EXISTING_VER=$(go version | awk '{print $3}')
        info_message "Existing Go installation detected: $EXISTING_VER"
        if gum confirm "Skip fresh install and update Go instead?"; then
            info_message "Skipping full installation — proceeding to update..."
            INSTALL_GO=false
            UPDATE_GO=true
        else
            info_message "Reinstalling Go from scratch..."
            sudo rm -rf /usr/local/go
        fi
    else
        info_message "No existing Go installation detected. Proceeding with fresh install."
    fi
fi

if [ "$INSTALL_GO" = true ]; then
    spinner "Installing Go..."

    GOLATESTURL="https://go.dev/VERSION?m=text"
    GOLATEST=$(curl -sL "$GOLATESTURL" | head -n1)

    wget "https://go.dev/dl/${GOLATEST}.linux-amd64.tar.gz"
    sudo tar -C /usr/local -xzf "${GOLATEST}.linux-amd64.tar.gz"
    rm -f "${GOLATEST}.linux-amd64.tar.gz"

    # Refresh PATH for current session
    export PATH="/usr/local/go/bin:$PATH"
    go version
    go telemetry off

    okay_message "Go installation completed successfully."
fi

if [ "$UPDATE_GO" = true ]; then
    spinner "Updating Go to the latest version..."
    curl -sL https://raw.githubusercontent.com/DieTime/go-up/master/go-up.sh | bash
fi

# ------------------------------------------------------------------
# Step 3: Tool installation menu (only if an install or update was performed)
# ------------------------------------------------------------------
if [ "$INSTALL_GO" = true ] || [ "$UPDATE_GO" = true ]; then
    install_go_tools
fi

finish "Go Toolchain setup complete."
