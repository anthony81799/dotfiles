if [ -z "$XDG_DATA_HOME" ] ; then
    export XDG_DATA_HOME="$HOME/.local/share"
fi

export CARGO_HOME="$XDG_DATA_HOME"/cargo
export GOROOT=/usr/local/go
export GOPATH="$XDG_DATA_HOME"/go
export PATH=$PATH:/usr/local/bin:$GOPATH/bin:$GOROOT/bin:$HOME/.local/bin:$HOME/Projects/apache-maven-3.9.2/bin:$CARGO_HOME/bin:$XDG_DATA_HOME/npm/bin:$HOME/.config/emacs/bin:$HOME/winhome/AppData/Local/Programs/Microsoft\ VS\ Code/bin/

if [ -z "$XDG_CONFIG_HOME" ] ; then
    export XDG_CONFIG_HOME="$HOME/.config"
fi

if [ -z "$XDG_CACHE_HOME" ] ; then
    export XDG_CACHE_HOME="$HOME/.cache"
fi

if [ -z "$XDG_STATE_HOME" ] ; then
    export XDG_STATE_HOME="$HOME/.local/state"
fi

eval "$(zellij setup --generate-auto-start zsh)"
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
export LESSHISTFILE="$XDG_STATE_HOME"/less/history
export MYSQL_HISTFILE="$XDG_DATA_HOME"/mysql_history
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME"/npm/npmrc
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java
export HISTFILE="$XDG_STATE_HOME"/zsh/history
export RUSTUP_HOME="$XDG_DATA_HOME"/rustup
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export ZSH="$XDG_DATA_HOME"/oh-my-zsh
export ZSH_CUSTOM="$ZSH"/custom

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(alias-finder autojump colorize command-not-found dnf git gitfast gitignore history nvm rust sudo zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh
source $ZSH_CUSTOM/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh
[[ ! -r /home/amason/.opam/opam-init/init.zsh ]] || source /home/amason/.opam/opam-init/init.zsh  > /dev/null 2> /dev/null

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

eval "$(zoxide init --cmd cd zsh)"

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

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
