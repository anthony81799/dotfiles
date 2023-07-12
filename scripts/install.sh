#!/bin/zsh

echo "Installing package dependencies."
sudo dnf install autojump-zsh perl jq neofetch -y

echo "Add RPMFusion."
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
sudo dnf update -y

echo "Installing package group dependencies."
sudo dnf group install "C Development Tools and Libraries" "Development Tools" "Fonts" "Hardware Suppotrt" -y 

echo "Set alias for dotfiles repo."
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

echo "Clone dotfiles repo."
git clone --bare https://github.com/anthony81799/dotfiles.git $HOME/.cfg

echo "Checkout dotfiles repo and hide untracked files from git status."
config checkout

echo "Update /etc/zshenv to use .cofig/zsh."
sudo zsh -c 'echo '"'"'ZDOTDIR=$HOME/.config/zsh'"'"' >> /etc/zshenv'

echo "Pull down repos for Helix and XDG-Ninja."
mkdir repos
git clone https://github.com/b3nj5m1n/xdg-ninja.git ~/repos/xdg-ninja
git clone https://github.com/anthony81799/helix.git ~/repos/helix

echo "Source ZSH."
source ~/.config/zsh/.zshrc

echo "Install Rust and desired crates."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install bacon bat bottom cargo-update exa fd-find gitui ripgrep sd tealdeer topgrade zoxide
cargo instal --locked zellij
./scripts/update-helix.sh

echo "Install and configure npm."
sudo dnf install nodejs-npm -y
sudo npm config set prefix=${XDG_DATA_HOME}/npm;
sudo npm config set cache=${XDG_CACHE_HOME}/npm;
sudo npm config set init-module=${XDG_CONFIG_HOME}/npm/config/npm-init.js;

echo "Install language servers helix languages."

echo "Bash"
sudo npm i -g bash-language-server

echo "CSS, HTML and JSON"
sudo npm i -g vscode-langservers-extracted

echo "Go"
go install golang.org/x/tools/gopls@latest
sudo dnf install delve -y

echo "JavaScript and TypeScript"
sudo npm install -g typescript typescript-language-server

echo "Rust"
sudo dnf install lldb -y

echo "TOML"
cargo install taplo-cli --locked --features lsp

echo "The Installation is finished!"
echo "I also program in Go. See https://go.dev/doc/install for instructions on how to install Go."
neofetch
