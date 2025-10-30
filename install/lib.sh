#!/usr/bin/env bash
# ===============================================
# Shared library for installer scripts
# ===============================================

set -euo pipefail
IFS=$'\n\t'

# Set environment variables for XDG compliance
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export GOROOT="/usr/local/go"
export GOPATH="$XDG_DATA_HOME/go"
export PATH="$PATH:$HOME/bin:/usr/local/bin:$GOPATH/bin:$GOROOT/bin:$HOME/.local/bin:$HOME/Projects/apache-maven-3.9.2/bin:$CARGO_HOME/bin:$XDG_DATA_HOME/npm/bin:$HOME/.config/emacs/bin:$HOME/winhome/AppData/Local/Programs/Microsoft\ VS\ Code/bin/:$HOME/.local/share/omadora/bin/"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export LESSHISTFILE="$XDG_STATE_HOME/less/history"
export MYSQL_HISTFILE="$XDG_DATA_HOME/mysql_history"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export _JAVA_OPTIONS="-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export AZURE_CONFIG_DIR="$XDG_DATA_HOME/azure"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export DOTNET_CLI_HOME="$XDG_DATA_HOME/dotnet"

# Simple logging setup (optional)
LOG_DIR="${HOME}/.local/logs"
mkdir -p "$LOG_DIR"

# Function: 1. Initializes the log file and opens it on File Descriptor 6 (FD 6)
# IMPORTANT: This must be called once at the start of your main scripts.
init_log() {
    local log_file="$1"
    # Close FD 6 if it's already open, then open the log file for appending on FD 6
    exec 6>&- || true
    exec 6>>"$log_file"
}

# Function: 2. Writes a timestamped message *only* to the log file (via FD 6)
log() {
    # This assumes init_log has been called and FD 6 is open.
    # Use 'command date' for cleanliness, as previously determined.
    local timestamp
    timestamp=$(command date '+%Y-%m-%d %H:%M:%S')

    # Write the log message to File Descriptor 6
    echo "$timestamp [LOG] $*" >&6
}

# Function: Ensure gum is installed
ensure_gum() {
    if ! command -v gum &>/dev/null; then
        echo "The 'gum' package is required but not installed. Installing it now..."
        sudo dnf install -y gum
    fi
}

# Function: Safe command existence check
has_cmd() {
    command -v "$1" &>/dev/null
}

# Function: Simple header banner
banner() {
    local msg="$1"
    log "BANNER: $msg"
    gum style --border double --margin "1" --padding "1" --align center --foreground 212 "$msg"
}

# Function: graceful exit message
finish() {
    local msg="$1"
    log "FINISH: $msg"
    gum style --border normal --margin "1" --padding "1" --align center --foreground 120 "$msg"
    exit 0
}

# Function: Styled messages
style_message() {
    local color="$1"
    local msg="$2"
    gum style --foreground "$color" "$msg"
}

# Styled message variants
info_message() {
    local msg="$1"
    log "INFO: $msg"
    style_message 244 "$msg"
}

fail_message() {
    local msg="$1"
    log "FAIL: $msg"
    style_message 196 "$msg"
}

okay_message() {
    local msg="$1"
    log "OKAY: $msg"
    style_message 120 "$msg"
}

warn_message() {
    local msg="$1"
    log "WARN: $msg"
    style_message 214 "$msg"
}

# Function: Spinner wrapper
spinner() {
    local title="$1"
    log "START SPINNER: $title"
    gum spin --title "$title" -- sleep 2
    log "END SPINNER: $title"
}
