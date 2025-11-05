# --- XDG Directories ---
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# --- Environment Variables ---
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
export GIT_CONFIG_GLOBAL="$XDG_CONFIG_HOME/git/config"
export XCOMPOSEFILE="$XDG_CONFIG_HOME/x11/xcompose"

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# --- Start Zellij automatically ---
eval "$(zellij setup --generate-auto-start zsh)"

# --- Zinit setup ---
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[[ ! -d "$ZINIT_HOME" ]] && mkdir -p "$(dirname $ZINIT_HOME)" && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# --- Zinit plugins ---
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit snippet OMZP::colorize
zinit snippet OMZP::command-not-found
zinit snippet OMZP::dnf
zinit snippet OMZP::git
zinit snippet OMZP::sudo
autoload -Uz compinit
compinit -u -d "${XDG_CACHE_HOME}/zsh/zcompdump"
zinit cdreplay -q

# --- Docker completions ---
if command -v docker &>/dev/null && docker info &>/dev/null; then
  completion_output=$(docker completion zsh 2>/dev/null)
  [[ -n "$completion_output" ]] && source <(echo "$completion_output")
fi
if command -v docker-compose &>/dev/null && docker-compose info &>/dev/null; then
  completion_output=$(docker-compose completion zsh 2>/dev/null)
  [[ -n "$completion_output" ]] && source <(echo "$completion_output")
fi

# --- History ---
HISTSIZE=5000
HISTFILE="$XDG_STATE_HOME/zsh/history"
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups hist_save_no_dups hist_ignore_dups hist_find_no_dups

# --- Completion styling ---
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# --- Aliases ---
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
alias wget='wget --hsts-file='"${XDG_DATA_HOME}"'/wget-hsts'
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
alias nv='nvim'
alias omadora='uwsm check may-start -v && uwsm start hyprland-uwsm.desktop'

# --- Zoxide & Atuin ---
eval "$(zoxide init zsh)"
eval "$(atuin init zsh)"

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

# --- PNPM ---
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# --- Local environment ---
[ -f "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"

# --- Google Cloud SDK ---
[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ] && source "$HOME/google-cloud-sdk/path.zsh.inc"
[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ] && source "$HOME/google-cloud-sdk/completion.zsh.inc"

# --- Turso ---
export PATH="$PATH:$HOME/.turso"

# --- OSC7 / precmd ---
osc7() {
  local LC_ALL=C
  export LC_ALL
  local uri="file://$HOSTNAME${PWD//[^A-Za-z0-9_.!~*'()\/]/%}"
  printf '\e]7;%s\a' "$uri"
}
precmd() {
  printf '\e]133;A\a'
}
autoload -Uz add-zsh-hook
add-zsh-hook -Uz chpwd osc7
precmd_functions+=(precmd)

# --- Oh My Posh theme ---
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/theme.json)"

# YAZELIX START v4 - Yazelix managed configuration (do not modify this comment)
# delete this whole section to re-generate the config, if needed
if [ -n "$IN_YAZELIX_SHELL" ]; then
  source "$HOME/.config/yazelix/shells/zsh/yazelix_zsh_config.sh"
fi
# yzx command - always available for launching/managing yazelix
yzx() {
    nu -c "use ~/.config/yazelix/nushell/scripts/core/yazelix.nu *; yzx $*"
}
# YAZELIX END v4 - Yazelix managed configuration (do not modify this comment)