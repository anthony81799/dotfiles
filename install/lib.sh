#!/usr/bin/env bash
# ===============================================
# Shared library for installer scripts
# ===============================================

set -euo pipefail
IFS=$'\n\t'

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
