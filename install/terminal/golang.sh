#!/usr/bin/env bash
# ===============================================
# Golang installer / updater
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "${DOTFILES_DIR}/install/lib.sh"

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
  local golatesturl="https://go.dev/VERSION?m=text"
  local golatest
  local archive

  info_message "Finding latest Go version..."
  golatest=$(curl -sL "$golatesturl" | head -n1) || {
    fail_message "Failed to fetch latest Go version."
  }
  log "Latest Go version found: $golatest"

  archive="${golatest}.linux-amd64.tar.gz"
  trap 'rm -f "$archive"' RETURN

  info_message "Downloading Go $golatest..."
  wget "https://go.dev/dl/$archive" || {
    fail_message "Failed to download Go archive."
  }

  info_message "Extracting Go archive to /usr/local/..."
  sudo tar -C /usr/local -xzf "$archive" || fail_message "Failed to extract Go archive."

  rm -f "$archive"

  # Refresh PATH for current session and disable telemetry
  export PATH="/usr/local/go/bin:$PATH"
  log "Updated PATH for current session: $PATH"

  if has_cmd go; then
    go version
    info_message "Disabling Go telemetry..."
    go telemetry off || warn_message "Failed to disable Go telemetry."
  fi

  okay_message "Go installation completed successfully."
}

update_go_binary() {
  banner "Go Update"
  info_message "Running go-up script to update Go..."
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

  local go_tools=(
    "lazygit (Git TUI, for use with Git)"
    "shfmt (Shell script formatter)"
    "glow (Markdown renderer, for use with 'bat')"
    "gopls (Go Language Server, for use with Helix/neovim)"
    "goimports (Go Imports Formatter)"
    "dlv (Go Debugger)"
    "golangci-lint (Fast Go Linter)"
  )

  local go_ver=$(go version | awk '{print $3}')

  local install_choices=$(
    gum choose --no-limit \
      --header "Select optional Go tools to install (Go version: $go_ver)" \
      "${go_tools[@]}" ||
      true # Allow user to exit without selection
  )

  if [ -z "$install_choices" ]; then
    info_message "No optional Go tools selected."
    return 0
  fi

  local failed_tools=()
  local tool_name=""
  local tool_path=""

  while IFS= read -r CHOICE; do
    tool_name=$(echo "$CHOICE" | awk '{print $1}') # Get just the tool name (e.g., lazygit)

    case "$CHOICE" in
    "lazygit (Git TUI, for use with Git)") tool_path="github.com/jesseduffield/lazygit@latest" ;;
    "shfmt (Shell script formatter)") tool_path="mvdan.cc/sh/v3/cmd/shfmt@latest" ;;
    "glow (Markdown renderer, for use with 'bat')") tool_path="github.com/charmbracelet/glow/v2@latest" ;;
    "gopls (Go Language Server, for use with Helix/neovim)") tool_path="golang.org/x/tools/gopls@latest" ;;
    "goimports (Go Imports Formatter)") tool_path="golang.org/x/tools/cmd/goimports@latest" ;;
    "dlv (Go Debugger)") tool_path="github.com/go-delve/delve/cmd/dlv@latest" ;;
    "golangci-lint (Fast Go Linter)") tool_path="github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest" ;;
    *)
      warn_message "Unknown selection: $CHOICE"
      continue
      ;;
    esac

    info_message "Installing $tool_name..."
    go install "$tool_path" || failed_tools+=("$tool_name")
  done <<<"$install_choices"

  if [ "${#failed_tools[@]}" -ne 0 ]; then
    warn_message "Failed to install some Go tools: ${failed_tools[*]}"
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
  info_message "Checking for existing Go installation..."

  if has_cmd go; then
    EXISTING_VER=$(go version | awk '{print $3}')
    info_message "Existing Go installation detected: $EXISTING_VER"

    if gum confirm "Skip fresh install and update Go instead?"; then
      info_message "Skipping full installation — proceeding to update..."
      INSTALL_GO=false
      UPDATE_GO=true
    else
      info_message "Reinstalling Go from scratch. Removing /usr/local/go..."
      info_message "Removing existing Go installation..."
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
  export PATH="/usr/local/go/bin:$PATH"
fi

if [ "$UPDATE_GO" = true ]; then
  update_go_binary
  export PATH="/usr/local/go/bin:$PATH"
fi

# Step 4: Tool installation menu (only if an install or update was performed)
if [ "$INSTALL_GO" = true ] || [ "$UPDATE_GO" = true ]; then
  install_go_tools
fi

finish "Go Toolchain setup complete."
