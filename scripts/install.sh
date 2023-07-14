#!/usr/bin/env bash

echo "Installing package dependencies."
sudo dnf install zsh autojump-zsh perl jq neofetch -y

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
config config --local status.showUntrackedFiles no

echo "Update /etc/zshenv to use .cofig/zsh."
sudo sh -c 'echo '"'"'ZDOTDIR=$HOME/.config/zsh'"'"' >> /etc/zshenv'

echo "Change default shell to ZSH."
chsh -s $(which zsh)

echo "Pull down repos for Helix and XDG-Ninja."
mkdir repos
git clone https://github.com/b3nj5m1n/xdg-ninja.git ~/repos/xdg-ninja
git clone https://github.com/anthony81799/helix.git ~/repos/helix

echo "Install Oh My ZSH."
ZDOTDIR=~/.config/zsh ZSH=~/.local/share/oh-my-zsh sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --keep-zshrc --unattended
ZSH_CUSTOM=$ZSH/custom

echo "Install custom ZSH plugins and theme."
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
./~/scripts/rust-and-helix-setup.sh
