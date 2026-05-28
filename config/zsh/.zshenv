export ZDOTDIR="$HOME/.config/zsh"

# ---------- XDG base directories ----------
# Centralizes config/cache/data locations
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# ---------- Editor ----------
# Default editor used by git, crontab, etc.
export EDITOR="nvim"
export VISUAL="nvim"

# ---------- Pager ----------
if command -v bat >/dev/null 2>&1; then
	export MANPAGER="bat -l man -p"
fi

# ---------- GPG ----------
export GPG_TTY=$(tty)

# ---------- PATH ----------
# Personal binaries/scripts
export PATH="$HOME/.local/bin:$PATH"
[[ -f "${CARGO_HOME:-$HOME/.local/share/cargo}/env" ]] && \
	. "${CARGO_HOME:-$HOME/.local/share/cargo}/env"
