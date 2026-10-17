#!/usr/bin/env bash
# ===============================================
# Claude Code global config installer
# ===============================================
set -euo pipefail
IFS=$'\n\t'

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "${DOTFILES_DIR}/install/lib.sh"

LOG_FILE="${LOG_DIR}/claude-install.log"
init_log "$LOG_FILE"

banner "Linking Claude Code config"
readonly REPO_CLAUDE_DIR="${DOTFILES_DIR}/config/claude"
readonly CLAUDE_DIR="${HOME}/.claude"

for item in CLAUDE.md settings.json agents; do
	_link "${REPO_CLAUDE_DIR}/${item}" "${CLAUDE_DIR}/${item}"
done

okay_message "Claude Code config linked into ${CLAUDE_DIR}"
