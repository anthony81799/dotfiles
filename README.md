# Fedora Linux Dotfiles for Anthony Mason

## Dependencies

This repository reqires zsh and assumes that the user is on Fedora Linux.

You can install zsh on Fedora like this:
```sudo dnf install zsh```

Oh-My-Zsh is also required and cna be installed with this command:

```sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"```

Then add the required custom plugins and theme.

```
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

## Installation
To install this repo run the follow command in a terminal:
```sh -c "$(curl -fsSL https://raw.githubusercontent.com/anthony81799/dotfiles/master/scripts/install.sh)"```
