export ZDOTDIR="$HOME/.config/zsh"
[[ -f "${CARGO_HOME:-$HOME/.local/share/cargo}/env" ]] && \
	. "${CARGO_HOME:-$HOME/.local/share/cargo}/env"
