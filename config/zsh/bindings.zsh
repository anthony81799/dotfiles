# =========================================================
# Keybindings
# =========================================================

# Standard (bash-like) line editing; zsh otherwise auto-enables vi mode because $EDITOR contains "vi"
bindkey -e

# Lone Esc does nothing instead of acting as a Meta prefix that eats the next key
KEYTIMEOUT=1
_noop() {}
zle -N _noop
bindkey '^[' _noop

# Ctrl+Right -> move forward one word (^[[1;5C is the terminal escape code)
bindkey '^[[1;5C' forward-word

# Ctrl+Left -> move backward one word (^[[1;5D is the terminal escape code)
bindkey '^[[1;5D' backward-word

# Ctrl+F -> fzf file picker (no hidden files)
bindkey '^F' _fzf_file_no_hidden

# Ctrl+\ -> toggle autosuggestions (useful for screen recordings)
bindkey '^\' autosuggest-toggle

# Up/Down -> history search by substring (^[[A/^[[B are up/down arrow escape codes)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
