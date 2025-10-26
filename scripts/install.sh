#!/usr/bin/env bash

# Parse arguments
INSTALL_GO=false
INSTALL_RUST=true
while getopts "h-:r-:g" opt; do
  case $opt in
  h)
    echo "Usage: $0 [--help] [--install-go] [--install-rust]"
    echo "Options:"
    echo "--help, -h: Print this help message"
    echo "--install-go, -g: Install Go toolchain and lazygit after regular installation"
    echo "--install-rust, -r: Install Rust toolchain and packages after regular installation"
    exit 0
    ;;
  g)
    INSTALL_GO=true
    ;;
  r)
    INSTALL_RUST=true
    ;;
  -) case $OPTARG in
    help)
      echo "Usage: $0 [--help] [--install-go] [--install-rust]"
      echo "Options:"
      echo "--help, -h: Print this help message"
      echo "--install-go, -g: Install Go toolchain and lazygit after regular installation"
      echo "--install-rust, -r: Install Rust toolchain and packages after regular installation"
      exit 0
      ;;
    install-go) INSTALL_GO=true ;;
    install-rust) INSTALL_RUST=true ;;
    esac ;;
  esac
done

echo "Installing package dependencies."
sudo dnf install zsh autojump-zsh perl jq fastfetch alsa-lib-devel entr fzf git-all neovim openssl-devel python3-pip protobuf protobuf-c protobuf-compiler protobuf-devel cmake zlib-ng zlib-ng-devel oniguruma-devel luarocks wget -y

echo "Add RPMFusion."
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
sudo dnf update -y

pip install neovim

echo "Installing package group dependencies."
sudo dnf group install "C Development Tools and Libraries" "Development Tools" "Fonts" -y

echo "Set alias for dotfiles repo."
function config {
  /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
}

echo "Clone dotfiles repo."
git clone --bare https://github.com/anthony81799/dotfiles.git $HOME/.cfg

echo "Checkout dotfiles repo and hide untracked files from git status."
config checkout
# config config --local status.showUntrackedFiles no

echo "Update /etc/zshenv to use .cofig/zsh."
sudo sh -c 'echo '"'"'ZDOTDIR=$HOME/.config/zsh'"'"' >> /etc/zshenv'

echo "Change default shell to ZSH."
chsh -s /bin/zsh

echo "Install Oh My Posh."
if [ ! -d ~/.local/bin ]; then
  mkdir -p ~/.local/bin
fi
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin

echo "Install and configure npm."
sudo dnf install nodejs-npm -y
sudo npm config set prefix=${XDG_DATA_HOME}/npm
sudo npm config set cache=${XDG_CACHE_HOME}/npm
sudo npm config set init-module=${XDG_CONFIG_HOME}/npm/config/npm-init.js

echo "Install Docker"
sudo dnf remove docker \
  docker-client \
  docker-client-latest \
  docker-common \
  docker-latest \
  docker-latest-logrotate \
  docker-logrotate \
  docker-selinux \
  docker-engine-selinux \
  docker-engine

sudo dnf -y install dnf-plugins-core
sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable --now docker

sudo chmod 777 '.cache'
sudo chown -R 1000:1000 "/home/amason/.cache/npm"

echo "Install XDG Ninja"
git clone https://github.com/b3nj5m1n/xdg-ninja ~/.local/share/xdg-ninja

if $INSTALL_GO; then
  echo "Installing Go and lazygit"
  bash ~/scripts/golang.sh
  go install github.com/jesseduffield/lazygit@latest
else
  echo "I also program in Go. See https://go.dev/doc/install for instructions on how to install Go."
fi
if $INSTALL_RUST; then
  bash ~/scripts/rust.sh
else
  echo "To install Rust and cargo run ~/scripts/rust.sh"
fi
echo "The Installation is finished!"
fastfetch
