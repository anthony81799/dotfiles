# ==================================
# XDG Directories
# ==================================
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# ==================================
# Start Zellij automatically
# ==================================
eval "$(zellij setup --generate-auto-start bash)"

# ==================================
# Environment Variables
# ==================================
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export GOROOT="/usr/local/go"
export GOPATH="$XDG_DATA_HOME/go"

# Set the PATH variable.
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
export GIT_CONFIG_GLOBAL="$XDG_CONFIG_HOME/git/config"
export XCOMPOSEFILE="$XDG_CONFIG_HOME/x11/xcompose"

# Turso CLI path
export PATH="$PATH:$HOME/.turso"

# EDITOR selection based on SSH connection
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# PNPM configuration
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac

# ==================================
# History
# ==================================
HISTSIZE=5000
HISTFILE="$XDG_STATE_HOME/bash/history"
SAVEHIST=$HISTSIZE
shopt -s histappend
shopt -s histreedit
shopt -s histverify
export HISTCONTROL=erasedups:ignorespace

# ==================================
# Aliases
# ==================================
alias dnfc='sudo dnf5 clean all'
alias dnfgi='sudo dnf5 groupinstall'
alias dnfgl='dnf5 grouplist'
alias dnfgr='sudo dnf5 groupremove'
alias dnfi='sudo dnf5 install'
alias dnfl='dnf5 list'
alias dnfli='dnf5 list installed'
alias dnfmc='dnf5 makecache'
alias dnfp='dnf5 info'
alias dnfr='sudo dnf5 remove'
alias dnfs='dnf5 search'
alias dnfu='sudo dnf5 upgrade'
alias ls='eza --color=always --icons=always --group-directories-first'
alias l='eza --color=always --icons=always --group-directories-first -alF'
alias tree='eza --color=always --icons=always --tree'
alias mv='mv -i'
alias rm='rm -i'
alias cp='cp -i'
alias grep='rg'
alias ca='cargo add'
alias ci='cargo install'
alias crm='cargo remove'
alias cu='cargo uninstall'
alias cr='cargo run'
alias cb='cargo build'
alias cc='cargo clean'
alias cl='cargo clippy'
alias cf='cargo fmt'
alias ct='cargo test'
alias c='clear'
alias sed='sd'
alias find='fd'
alias tg='topgrade'
alias wget="wget --hsts-file='${XDG_DATA_HOME}/wget-hsts'"
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
alias nv='nvim'
alias omadora='uwsm check may-start -v && uwsm start hyprland-uwsm.desktop'

# ==================================
# Zoxide & Atuin
# ==================================
eval "$(zoxide init bash)"
eval "$(atuin init bash)"

# ==================================
# FZF Tab completion
# ==================================
if command -v fzf &>/dev/null; then
  eval "$(fzf --bash)"
fi

# ==================================
# Yazi wrapper
# ==================================
ya() {
  local tmp
  tmp="$(mktemp -t 'yazi-cwd.XXXXX')"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# ==================================
# Bash Feature Replacements (ble.sh)
# Must be loaded before hooks/completions/prompt to take effect.
[[ $- == *i* ]] && source -- "$XDG_DATA_HOME/blesh/ble.sh" --attach=none

# ==================================
# OSC7 / precmd
# ==================================
osc7() {
  local LC_ALL=C
  export LC_ALL
  # Fix the substitution for URI encoding
  local uri="file://$HOSTNAME${PWD//\//%2F}"
  printf '\e]7;%s\a' "$uri"
}
precmd() {
  printf '\e]133;A\a'
}
PROMPT_COMMAND="osc7; precmd; $PROMPT_COMMAND"

# ==================================
# Other Files
# ==================================

# Local environment
[ -f "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"

# Google Cloud SDK
[ -f "$HOME/google-cloud-sdk/path.bash.inc" ] && source "$HOME/google-cloud-sdk/path.bash.inc"
[ -f "$HOME/google-cloud-sdk/completion.bash.inc" ] && source "$HOME/google-cloud-sdk/completion.bash.inc"

# Oh My Posh theme (MUST BE LAST)
eval "$(oh-my-posh init bash --config ~/.config/oh-my-posh/theme.json)"
[[ ! ${BLE_VERSION-} ]] || ble-attach

# YAZELIX START v4 - Yazelix managed configuration (do not modify this comment)
# delete this whole section to re-generate the config, if needed
if [ -n "$IN_YAZELIX_SHELL" ]; then
  source "$HOME/.config/yazelix/shells/bash/yazelix_bash_config.sh"
fi
# yzx command - always available for launching/managing yazelix
yzx() {
  nu -c "use ~/.config/yazelix/nushell/scripts/core/yazelix.nu *; yzx $*"
}
# YAZELIX END v4 - Yazelix managed configuration (do not modify this comment)
