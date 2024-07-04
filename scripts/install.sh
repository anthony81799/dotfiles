#!/usr/bin/env bash

echo "Installing package dependencies."
sudo dnf install zsh autojump-zsh perl jq fastfetch alsa-lib-devel entr fzf git neovim openssl-devel python3-pip protobuf protobuf-c protobuf-compiler protobuf-devel -y

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
chsh -s $(which zsh)

echo "Install Oh My Posh."
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin

echo "Install and configure npm."
sudo dnf install nodejs-npm -y
sudo npm config set prefix=${XDG_DATA_HOME}/npm
sudo npm config set cache=${XDG_CACHE_HOME}/npm
sudo npm config set init-module=${XDG_CONFIG_HOME}/npm/config/npm-init.js

sudo chmod 777 '.cache'
sudo chown -R 1000:1000 "/home/amason/.cache/npm"

echo "The Installation is finished!"
echo "I also program in Go. See https://go.dev/doc/install for instructions on how to install Go."
echo "To install Rust and cargo run ~/scripts/rust.sh"
fastfetch
