# --- XDG Directories ---
set -gx XDG_DATA_HOME (string replace --regex '^$' $HOME/.local/share $XDG_DATA_HOME)
set -gx XDG_CONFIG_HOME (string replace --regex '^$' $HOME/.config $XDG_CONFIG_HOME)
set -gx XDG_CACHE_HOME (string replace --regex '^$' $HOME/.cache $XDG_CACHE_HOME)
set -gx XDG_STATE_HOME (string replace --regex '^$' $HOME/.local/state $XDG_STATE_HOME)

# --- Environment variables ---
set -gx CARGO_HOME "$XDG_DATA_HOME/cargo"
set -gx RUSTUP_HOME "$XDG_DATA_HOME/rustup"
set -gx GOROOT /usr/local/go
set -gx GOPATH "$XDG_DATA_HOME/go"
set -gx GTK2_RC_FILES "$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
set -gx LESSHISTFILE "$XDG_STATE_HOME/less/history"
set -gx MYSQL_HISTFILE "$XDG_DATA_HOME/mysql_history"
set -gx NPM_CONFIG_USERCONFIG "$XDG_CONFIG_HOME/npm/npmrc"
set -gx _JAVA_OPTIONS "-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java"
set -gx DOTNET_CLI_TELEMETRY_OPTOUT 1
set -gx AZURE_CONFIG_DIR "$XDG_DATA_HOME/azure"
set -gx DOCKER_CONFIG "$XDG_CONFIG_HOME/docker"
set -gx DOTNET_CLI_HOME "$XDG_DATA_HOME/dotnet"
set -gx GIT_CONFIG_GLOBAL "$XDG_CONFIG_HOME/git/config"
set -gx XCOMPOSEFILE "$XDG_CONFIG_HOME/x11/xcompose"

# --- Path Management ---
fish_add_path \
    $HOME/bin \
    /usr/local/bin \
    $GOPATH/bin \
    $GOROOT/bin \
    $HOME/.local/bin \
    $CARGO_HOME/bin \
    $XDG_DATA_HOME/npm/bin \

# --- Start Zellij automatically ---
zellij setup --generate-auto-start fish | source

# --- Disable the Fish shell greeting message ---
set -g fish_greeting

# --- Set color for command validation ---
set -g fish_color_command green

# --- EDITOR selection based on SSH connection ---
if test -n "$SSH_CONNECTION"
    set -gx EDITOR vim
else
    set -gx EDITOR nvim
    set -gx VISUAL nvim
end

# --- Pager ---
if type -q bat
    set -gx MANPAGER "bat -l man -p"
end

# --- GPG ---
set -gx GPG_TTY (tty)

# --- History ---
set -gx fish_history_file "$XDG_STATE_HOME/fish/history"

# --- Aliases ---
abbr ls 'eza --color=always --icons --group-directories-first'
abbr ll 'eza -lh --icons --git --group-directories-first'
abbr la 'eza -lah --icons --git --group-directories-first'
abbr tree 'eza --tree --icons'
abbr cat bat
abbr diff 'diff --color=auto'
function mv
    command mv -i $argv
end
function rm
    command rm -i $argv
end
function cp
    command cp -i $argv
end
abbr grep rg
abbr c clear
abbr sed sd
abbr find fd
abbr tg topgrade
function wget
    command wget --hsts-file="$XDG_DATA_HOME/wget-hsts" $argv
end
abbr df dysk
abbr du dust
abbr ps procs

abbr dnfc 'sudo dnf clean all'
abbr dnfgi 'sudo dnf groupinstall'
abbr dnfgl 'dnf grouplist'
abbr dnfgr 'sudo dnf groupremove'
abbr dnfi 'sudo dnf install'
abbr dnfl 'dnf list'
abbr dnfli 'dnf list installed'
abbr dnfmc 'dnf makecache'
abbr dnfp 'dnf info'
abbr dnfr 'sudo dnf remove'
abbr dnfs 'dnf search'
abbr dnfu 'sudo dnf upgrade'

abbr ca 'cargo add'
abbr ci 'cargo install'
abbr crm 'cargo remove'
abbr cu 'cargo uninstall'
abbr cr 'cargo run'
abbr cb 'cargo build'
abbr cc 'cargo clean'
abbr cl 'cargo clippy'
abbr cf 'cargo fmt'
abbr ct 'cargo test'

abbr vim nvim
abbr nv nvim

abbr ga 'git add'
abbr gap 'ga --patch'
abbr gb 'git branch'
abbr gba 'gb --all'
abbr gc 'git commit'
abbr gca 'gc --amend --no-edit'
abbr gce 'gc --amend'
abbr gco 'git checkout'
abbr gcl 'git clone --recursive'
abbr gd 'git diff --output-indicator-new=" " --output-indicator-old=" "'
abbr gds 'gd --staged'
abbr gi 'git init'
abbr gl 'git log --graph --all --pretty=format:"%C(orange)%h %C(white) %an  %ar%C(auto)  %D%n%s%n"'
abbr gm 'git merge'
abbr gn 'git checkout -b'
abbr gp 'git push'
abbr gr 'git reset'
abbr gs 'git status --short'
abbr gu 'git pull'

# --- Zoxide & Atuin ---
zoxide init fish | source
atuin init fish | source

# --- Yazi wrapper ---
function ya
    set tmp (mktemp -t 'yazi-cwd.XXXXX')
    yazi $argv --cwd-file="$tmp"
    set cwd (cat -- "$tmp")
    if test -n "$cwd"
        if test "$cwd" != "$PWD"
            cd -- "$cwd"
        end
    end
    rm -f -- "$tmp"
end

# -- FZF Tab Completion ---
if type -q fzf
    fzf --fish | source
end

# --- Docker completions ---
if type -q docker
    if docker completion fish &>/dev/null
        docker completion fish | source
    end
end
if type -q docker-compose
    if docker-compose completion fish &>/dev/null
        docker-compose completion fish | source
    end
end

# --- OSC7 / precmd ---
function osc7 --on-variable PWD
    set -l uri (printf 'file://%s%s' $HOSTNAME (string replace -a -r '/' '%2F' $PWD))
    printf '\e]7;%s\a' "$uri"
end

function precmd --on-event fish_prompt
    printf '\e]133;A\a'
end

# --- Oh My Posh theme  ---
oh-my-posh init fish --config ~/.config/oh-my-posh/theme.json | source
