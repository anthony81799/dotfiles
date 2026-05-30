# =========================================================
# Environment Variables
# =========================================================
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export GOROOT="/usr/local/go"
export GOPATH="$XDG_DATA_HOME/go"
export PATH="$PATH:$HOME/bin:/usr/local/bin:$GOPATH/bin:$GOROOT/bin:$HOME/.local/bin:$CARGO_HOME/bin:$XDG_DATA_HOME/npm/bin/"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
export LESSHISTFILE="$XDG_STATE_HOME/less/history"
export MYSQL_HISTFILE="$XDG_DATA_HOME/mysql_history"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export _JAVA_OPTIONS="-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export AZURE_CONFIG_DIR="$XDG_DATA_HOME/azure"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export DOTNET_CLI_HOME="$XDG_DATA_HOME/dotnet"
export GIT_CONFIG_GLOBAL="$XDG_CONFIG_HOME/git/config"
export XCOMPOSEFILE="$XDG_CONFIG_HOME/x11/xcompose"

if [[ -n $SSH_CONNECTION ]]; then
	export EDITOR='vim'
else
	export EDITOR='nvim'
fi

# =========================================================
# History
# =========================================================

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

# =========================================================
# Shell behaviour
# =========================================================

setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT  # sort file10 after file9, not after file1

# =========================================================
# Smart directory navigation & lf
# =========================================================

# Initialize zoxide
eval "$(zoxide init zsh)"

# =========================================================
# Completion
# =========================================================

# Load completion system
autoload -Uz compinit

# Initialize completion with cached metadata file
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

# Enable interactive completion menu selection
zstyle ':completion:*' menu select

# Make completion case-insensitive
# Example: "doc" can complete to "Documents"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # lowercase input matches upper and lower

# Docker completions
if command -v docker &>/dev/null && docker info &>/dev/null; then
	completion_output=$(docker completion zsh 2>/dev/null)
	[[ -n "$completion_output" ]] && source <(echo "$completion_output")
fi
if command -v docker-compose &>/dev/null && docker-compose info &>/dev/null; then
	completion_output=$(docker-compose completion zsh 2>/dev/null)
	[[ -n "$completion_output" ]] && source <(echo "$completion_output")
fi

# =========================================================
# Fuzzy finder
# =========================================================

if [[ -f /usr/share/fzf/shell/key-bindings.zsh ]]; then
	source /usr/share/fzf/shell/key-bindings.zsh
	source /usr/share/fzf/shell/completion.zsh
fi

# =========================================================
# Modular Config Files
# =========================================================

# fzf configuration
source "$ZDOTDIR/fzf.zsh"

# Aliases
source "$ZDOTDIR/aliases.zsh"

# Custom keybindings
source "$ZDOTDIR/bindings.zsh"

# Plugins and plugin manager
source "$ZDOTDIR/plugins.zsh"

# --- yazi wrapper ---
ya() {
	local tmp
	tmp="$(mktemp -t 'yazi-cwd.XXXXX')"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# --- Oh My Posh theme ---
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/theme.json)"
