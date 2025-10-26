#!/usr/bin/env bash
# ===============================================
# Dotfiles installer (gum-based version)
# ===============================================

# Ensure gum is installed
if ! command -v gum &> /dev/null; then
    echo "The 'gum' package is required but not installed. Installing it now..."
    sudo dnf install gum -y
fi

# Variables for user choices
INSTALL_GO=false
INSTALL_RUST=false
DEFAULT_SHELL=""
INSTALL_DOCKER=false
INSTALL_NODE=false
INSTALL_XDG_NINJA=false

# Step 1: Main menu for installation options
CHOICES=$(gum choose --no-limit \
    "Install Go toolchain and lazygit" \
    "Install Rust toolchain and crates" \
    "Install Docker" \
    "Install Node.js and npm" \
    "Install XDG Ninja"
)

# Parse choices
while IFS= read -r CHOICE; do
    case $CHOICE in
        "Install Go toolchain and lazygit") INSTALL_GO=true ;;
        "Install Rust toolchain and crates") INSTALL_RUST=true ;;
        "Install Docker") INSTALL_DOCKER=true ;;
        "Install Node.js and npm") INSTALL_NODE=true ;;
        "Install XDG Ninja") INSTALL_XDG_NINJA=true ;;
    esac
done <<< "$CHOICES"

# Step 2: Shell selection menu
DEFAULT_SHELL=$(gum choose \
    "/bin/zsh (ZSH)" \
    "/bin/bash (Bash)" \
    "/usr/bin/fish (Fish)" \
    "Skip (Keep current shell)"
)

case $DEFAULT_SHELL in
    "/bin/zsh (ZSH)") DEFAULT_SHELL="/bin/zsh" ;;
    "/bin/bash (Bash)") DEFAULT_SHELL="/bin/bash" ;;
    "/usr/bin/fish (Fish)") DEFAULT_SHELL="/usr/bin/fish" ;;
    "Skip (Keep current shell)") DEFAULT_SHELL="" ;;  # Skip changing the shell
esac

# Step 3: Installation progress
gum spin --title "Installing dependencies..." -- sleep 2
sudo dnf install zsh autojump-zsh perl jq fastfetch alsa-lib-devel entr fzf git-all neovim openssl-devel python3-pip protobuf protobuf-c protobuf-compiler protobuf-devel cmake zlib-ng zlib-ng-devel oniguruma-devel luarocks wget fish -y

gum spin --title "Adding RPMFusion..." -- sleep 2
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
sudo dnf update -y


gum spin --title "Installing package group dependencies." -- sleep 2
sudo dnf group install fonts c-development development-tools -y

function config {
    /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
}

gum spin --title "Clone dotfiles repo." -- sleep 2
git clone --bare https://github.com/anthony81799/dotfiles.git $HOME/.cfg

gum spin --title "Checkout dotfiles repo and hide untracked files from git status." -- sleep 2
config checkout

pip install neovim

# Step 4: Git configuration
GIT_NAME=$(gum input --placeholder "Enter your full name for Git")
GIT_EMAIL=$(gum input --placeholder "Enter your email address for Git")

# Configure Git if both name and email are provided
if [[ -n "$GIT_NAME" && -n "$GIT_EMAIL" ]]; then
    gum spin --title "Configuring Git..." -- sleep 2
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.st status
    git config --global pull.rebase true
    git config --global init.defaultBranch master
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
else
    gum confirm "Git name or email not provided. Skip Git configuration?" && echo "Skipping Git configuration."
fi

# Install Go if selected
if [ "$INSTALL_GO" = true ]; then
    gum spin --title "Installing Go and lazygit..." -- sleep 2
    bash ~/scripts/golang.sh
    go install github.com/jesseduffield/lazygit@latest
fi

# Install Rust if selected
if [ "$INSTALL_RUST" = true ]; then
    gum spin --title "Installing Rust..." -- sleep 2
    bash ~/scripts/rust.sh
fi

# Install Docker if selected
if [ "$INSTALL_DOCKER" = true ]; then
    gum spin --title "Installing Docker..." -- sleep 2
    sudo dnf remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine -y
    sudo dnf -y install dnf-plugins-core
    sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    sudo systemctl enable --now docker
fi

# Install Node.js and npm if selected
if [ "$INSTALL_NODE" = true ]; then
    gum spin --title "Installing Node.js and npm..." -- sleep 2
    sudo dnf install nodejs-npm -y
    sudo npm config set prefix=${XDG_DATA_HOME}/npm
    sudo npm config set cache=${XDG_CACHE_HOME}/npm
    sudo npm config set init-module=${XDG_CONFIG_HOME}/npm/config/npm-init.js
    sudo chmod 777 '.cache'
    sudo chown -R 1000:1000 "/home/amason/.cache/npm"
fi

# Install XDG Ninja if selected
if [ "$INSTALL_XDG_NINJA" = true ]; then
    gum spin --title "Installing XDG Ninja..." -- sleep 2
    git clone https://github.com/b3nj5m1n/xdg-ninja ~/.local/share/xdg-ninja
fi

# Change default shell if selected
if [ -n "$DEFAULT_SHELL" ]; then
    gum spin --title "Changing default shell to $DEFAULT_SHELL..." -- sleep 2
    if [ "$DEFAULT_SHELL" == "/bin/zsh" ]; then
        gum spin --title "Update /etc/zshenv to use .config/zsh." -- sleep 2
        sudo sh -c 'echo "ZDOTDIR=$HOME/.config/zsh" >> /etc/zshenv'
        gum spin --title "Install Oh My Posh." -- sleep 2
        if [ ! -d ~/.local/bin ]; then
            mkdir -p ~/.local/bin
        fi
        curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
    fi
    chsh -s "$DEFAULT_SHELL"
else
    echo "Skipping shell change."
fi

# Final message
gum style --border normal --margin "1" --padding "1" --align center --foreground 212 "The installation is finished!"
fastfetch