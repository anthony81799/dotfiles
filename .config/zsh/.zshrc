# Set up XDG directories
if [ -z "$XDG_DATA_HOME" ] ; then
  export XDG_DATA_HOME="$HOME/.local/share"
fi

if [ -z "$XDG_CONFIG_HOME" ] ; then
  export XDG_CONFIG_HOME="$HOME/.config"
fi

if [ -z "$XDG_CACHE_HOME" ] ; then
  export XDG_CACHE_HOME="$HOME/.cache"
fi

if [ -z "$XDG_STATE_HOME" ] ; then
  export XDG_STATE_HOME="$HOME/.local/state"
fi

# Enable zellij on start up
eval "$(zellij setup --generate-auto-start zsh)"

# Export environment variables
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export RUSTUP_HOME="$XDG_DATA_HOME"/rustup
export GOROOT=/usr/local/go
export GOPATH="$XDG_DATA_HOME"/go
export PATH=$PATH:$HOME/bin:/usr/local/bin:$GOPATH/bin:$GOROOT/bin:$HOME/.local/bin:$HOME/Projects/apache-maven-3.9.2/bin:$CARGO_HOME/bin:$XDG_DATA_HOME/npm/bin:$HOME/.config/emacs/bin:$HOME/winhome/AppData/Local/Programs/Microsoft\ VS\ Code/bin/
export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
export LESSHISTFILE="$XDG_STATE_HOME"/less/history
export MYSQL_HISTFILE="$XDG_DATA_HOME"/mysql_history
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME"/npm/npmrc
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java
export DOTNET_CLI_TELEMETRY_OPTOUT=1
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZP::alias-finder
zinit snippet OMZP::colorize
zinit snippet OMZP::command-not-found
zinit snippet OMZP::dnf
zinit snippet OMZP::git
zinit snippet OMZP::sudo

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# Initialize theme
eval "$(oh-my-posh init zsh --config ~/.config/zsh/theme.json)"

# History
HISTSIZE=5000
HISTFILE="$XDG_STATE_HOME"/zsh/history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='eza --color=always --icons=always --group-directories-first'
alias l='eza --color=always --icons=always --group-directories-first -alF'
alias tree='eza --color=always --icons=always --tree'
alias mv='mv -i'
alias rm='rm -i'
alias cp='cp -i'
alias grep='rg'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gr='git rm'
alias gd='git diff'
alias ca='cargo add'
alias ci='cargo install'
alias cr='cargo remove'
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
alias wget=wget --hsts-file="$XDG_DATA_HOME/wget-hsts"
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
alias nv='nvim'

# Shell integrations
eval "$(zoxide init --cmd cd zsh)"
eval "$(atuin init zsh)"

function osc7 {
  local LC_ALL=C
  export LC_ALL

  setopt localoptions extendedglob
  input=( ${(s::)PWD} )
  uri=${(j::)input/(#b)([^A-Za-z0-9_.\!~*\'\(\)-\/])/%${(l:2::0:)$(([##16]#match))}}
  print -n "\e]7;file://${HOSTNAME}${uri}\e\\"
}
add-zsh-hook -Uz chpwd osc7

precmd() {
  print -Pn "\e]133;A\e\\"
}

function ya() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}