#!/usr/bin/env bash

echo "Installing package dependencies."
sudo dnf install zsh autojump-zsh perl jq neofetch alsa-lib-devel entr fzf git neovim -y

echo "Add RPMFusion."
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
sudo dnf update -y

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

# echo "Install Oh My ZSH."
ZDOTDIR=~/.config/zsh # ZSH=~/.local/share/oh-my-zsh sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --keep-zshrc --unattended
ZSH_CUSTOM=$ZSH/custom
XDG_DATA_HOME="$HOME/.local/share"
XDG_CONFIG_HOME="$HOME/.config"
XDG_CACHE_HOME="$HOME/.cache"
XDG_STATE_HOME="$HOME/.local/state"
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export RUSTUP_HOME="$XDG_DATA_HOME"/rustup

# echo "Install custom ZSH plugins and theme."
# sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
# sudo git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete
# sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

echo "Install and configure npm."
sudo dnf install nodejs-npm -y
sudo npm config set prefix=${XDG_DATA_HOME}/npm
sudo npm config set cache=${XDG_CACHE_HOME}/npm
sudo npm config set init-module=${XDG_CONFIG_HOME}/npm/config/npm-init.js

npm config set prefix=${XDG_DATA_HOME}/npm
npm config set cache=${XDG_CACHE_HOME}/npm
npm config set init-module=${XDG_CONFIG_HOME}/npm/config/npm-init.js

# echo "Install language servers helix languages."

# echo "Bash"
# sudo npm i -g bash-language-server

# echo "CSS, HTML and JSON"
# sudo npm i -g vscode-langservers-extracted

# echo "Go"
# go install golang.org/x/tools/gopls@latest
# sudo dnf install delve -y

# echo "JavaScript and TypeScript"
# sudo npm install -g typescript typescript-language-server

# echo "Rust"
# sudo dnf install lldb -y
# rustup compent add rust-analyzer

# echo "TOML"
# cargo install taplo-cli --locked --features lsp

# echo "C/C++"
# sudo dnf install clang clang-tools-extra -y

# echo "Dockerfile"
# sudo npm install -g dockerfile-language-server-nodejs

# echo "Java"
# sudo dnf copr enable freyr/jdtls -y
# sudo dnf install jdtls -y

# echo "WGSL"
# cargo install --git https://github.com/wgsl-analyzer/wgsl-analyzer wgsl_analyzer

# echo "YAML"
# sudo npm i -g yaml-language-server@next

echo "The Installation is finished!"
echo "I also program in Go. See https://go.dev/doc/install for instructions on how to install Go."
echo "To install Rust and cargo run ~/scripts/rust.sh"
neofetch
