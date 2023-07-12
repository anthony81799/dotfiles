#!/bin/zsh

echo "Installing package group dependencies."
sudo dnf group install "C Development Tools and Libraries" "Development Tools" "Fonts" "Hardware Suppotrt" -y 

echo "Installing package dependencies."
sudo dnf install autojump-zsh perl jq neofetch -y

echo "Set alias for dotfiles repo."
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

echo "Clone dotfiles repo."
git clone --bare https://github.com/anthony81799/dotfiles.git $HOME/.cfg

echo "Redefine alias."
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

echo "Checkout dotfiles repo and hide untracked files from git status."
config checkout

echo "Update /etc/zshenv to use .cofig/zsh."
echo "export ZDOTDIR="$HOME"/.config/zsh" > /etc/zshenv

echo "Pull down repos for Helix and XDG-Ninja."
mkdir repos
git clone https://github.com/b3nj5m1n/xdg-ninja.git ~/repos/xdg-ninja
git clone https://github.com/anthony81799/helix.git ~/repos/helix

echo "Install Oh-My-ZSH."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Add custom ZSH plugins and theme."
cd $ZSH_CUSTOM/plugins
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

echo "Switch to ZSH."
source ~/.config/zsh/.zshrc

echo "Install Rust and desired crates."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install bacon bat bottom cargo-update exa fd-find gitui ripgrep sd tealdeer topgrade zoxide
cargo instal --locked zellij
./scripts/update-helix.sh

echo "Install and configure npm."
sudo dnf install nodejs-npm -y
npm config set prefix=${XDG_DATA_HOME}/npm;
npm config set cache=${XDG_CACHE_HOME}/npm;
npm config set init-module=${XDG_CONFIG_HOME}/npm/config/npm-init.js;

echo "Install language servers helix languages."

echo "Bash"
npm i -g bash-language-server

echo "CSS, HTML and JSON"
npm i -g vscode-langservers-extracted

echo "Go"
go install golang.org/x/tools/gopls@latest
dnf install delve -y

echo "JavaScript and TypeScript"
npm install -g typescript typescript-language-server

echo "Rust"
dnf install lldb -y

echo "TOML"
cargo install taplo-cli --locked --features lsp

echo "The Installation is finished!"
echo "I also program in Go. See https://go.dev/doc/install for instructions on how to install Go."
neofetch