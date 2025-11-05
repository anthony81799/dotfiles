# ==================================
# XDG Directories
# ==================================
# Fish uses 'set -gx' for global, exported environment variables
set -gx XDG_DATA_HOME (string replace --regex '^$' $HOME/.local/share $XDG_DATA_HOME)
set -gx XDG_CONFIG_HOME (string replace --regex '^$' $HOME/.config $XDG_CONFIG_HOME)
set -gx XDG_CACHE_HOME (string replace --regex '^$' $HOME/.cache $XDG_CACHE_HOME)
set -gx XDG_STATE_HOME (string replace --regex '^$' $HOME/.local/state $XDG_STATE_HOME)

# ==================================
# Start Zellij automatically
# ==================================
zellij setup --generate-auto-start fish | source

# ==================================
# Environment Variables
# ==================================
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

# Disable the Fish shell greeting message
set -g fish_greeting

# Set color for command validation
set -g fish_color_command green

# EDITOR selection based on SSH connection
if test -n "$SSH_CONNECTION"
    set -gx EDITOR vim
else
    set -gx EDITOR nvim
end

# PNPM configuration
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
fish_add_path "$PNPM_HOME"

# ==================================
# Path Management
# ==================================
# Use fish_add_path to manage PATH components easily and avoid duplicates
fish_add_path \
    $HOME/bin \
    /usr/local/bin \
    $GOPATH/bin \
    $GOROOT/bin \
    $HOME/.local/bin \
    $HOME/Projects/apache-maven-3.9.2/bin \
    $CARGO_HOME/bin \
    $XDG_DATA_HOME/npm/bin \
    $HOME/.config/emacs/bin \
    "$HOME/winhome/AppData/Local/Programs/Microsoft VS Code/bin/" \
    "$HOME/.local/share/omadora/bin/" \
    $PNPM_HOME \
    $HOME/.turso

# ==================================
# History
# ==================================
set -gx fish_history_file "$XDG_STATE_HOME/zsh/history"

# ==================================
# Aliases (using 'abbr' for simple substitutions and 'function' for wrappers)
# ==================================
abbr ls 'eza --color=always --icons=always --group-directories-first'
abbr l 'eza --color=always --icons=always --group-directories-first -alF'
abbr tree 'eza --color=always --icons=always --tree'
# Use functions for interactive commands
function mv
    command mv -i $argv
end
function rm
    command rm -i $argv
end
function cp
    command cp -i $argv
end
abbr dnfc 'sudo dnf5 clean all'
abbr dnfgi 'sudo dnf5 groupinstall'
abbr dnfgl 'dnf5 grouplist'
abbr dnfgr 'sudo dnf5 groupremove'
abbr dnfi 'sudo dnf5 install'
abbr dnfl 'dnf5 list'
abbr dnfli 'dnf5 list installed'
abbr dnfmc 'dnf5 makecache'
abbr dnfp 'dnf5 info'
abbr dnfr 'sudo dnf5 remove'
abbr dnfs 'dnf5 search'
abbr dnfu 'sudo dnf5 upgrade'
abbr grep rg
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
abbr c clear
abbr sed sd
abbr find fd
abbr tg topgrade
function wget
    command wget --hsts-file="$XDG_DATA_HOME/wget-hsts" $argv
end
abbr config '/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
abbr nv nvim
abbr omadora 'uwsm check may-start -v && uwsm start hyprland-uwsm.desktop'

# ==================================
# Zoxide & Atuin
# ==================================
zoxide init fish | source
atuin init fish | source

# ==================================
# Yazi wrapper
# ==================================
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

# ==================================
# FZF Completion (fzf-tab replacement)
# ==================================
if type -q fzf
    # fzf --fish outputs the necessary key-bindings and completion code
    fzf --fish | source
end

# ==================================
# OSC7 / Prompt Signaling
# ==================================
# Function to send OSC7 CWD signal (runs on directory change)
function osc7 --on-variable PWD
    set -l uri (printf 'file://%s%s' $HOSTNAME (string replace -a -r '/' '%2F' $PWD))
    printf '\e]7;%s\a' "$uri"
end

# Function to send OSC 133;A (start-of-prompt) signal (runs before prompt)
function precmd --on-event fish_prompt
    printf '\e]133;A\a'
end

# ==================================
# Hooks and Completions
# ==================================

# --- Local environment ---
if test -f "$HOME/.local/bin/env"
    source "$HOME/.local/bin/env"
end

# --- Google Cloud SDK ---
if test -f "$HOME/google-cloud-sdk/path.fish.inc"
    source "$HOME/google-cloud-sdk/path.fish.inc"
end
if test -f "$HOME/google-cloud-sdk/completion.fish.inc"
    source "$HOME/google-cloud-sdk/completion.fish.inc"
end

# --- Docker/Docker-Compose Completions ---
if type -q docker
    # Source Docker V2 completion
    if docker completion fish &>/dev/null
        docker completion fish | source
    end
end
if type -q docker-compose
    # Source Docker Compose V1 completion
    if docker-compose completion fish &>/dev/null
        docker-compose completion fish | source
    end
end

# ==================================
# Oh My Posh theme (MUST BE LAST)
# ==================================
oh-my-posh init fish --config ~/.config/oh-my-posh/theme.json | source

# YAZELIX START v4 - Yazelix managed configuration (do not modify this comment)
# delete this whole section to re-generate the config, if needed
if test -n "$IN_YAZELIX_SHELL"
    source "$HOME/.config/yazelix/shells/fish/yazelix_fish_config.sh"
end
# yzx command - always available for launching/managing yazelix
function yzx
    nu -c "use ~/.config/yazelix/nushell/scripts/core/yazelix.nu *; yzx $argv"
end
# YAZELIX END v4 - Yazelix managed configuration (do not modify this comment)
