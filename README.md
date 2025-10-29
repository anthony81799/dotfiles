# Fedora Linux Dotfiles for Anthony Mason

## Dependencies

This repository assumes that the user is on Fedora Linux.

## Installation

To install this repo run the follow commands in a terminal:

```export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
   export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
   export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
   export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
   git clone --bare https://github.com/anthony81799/dotfiles.git "$HOME/.cfg"
   alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
   config checkout
   ./setup.sh
```
