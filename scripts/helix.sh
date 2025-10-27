#!/usr/bin/env bash
# ===============================================
# Helix set installer/updater
# ===============================================

# Ensure gum is installed
if ! command -v gum &>/dev/null; then
    echo "The 'gum' package is required but not installed. Installing it now..."
    sudo dnf install gum -y
fi

HELIXDIR="$HOME/.local/share/helix"

gum spin --title "Installing/Updating Helix and LSPs..." -- sleep 1

# Step 1: Install Helix
gum spin --title "Cloning Helix repository..." -- sleep 1
mkdir -p "$HELIXDIR"
if [ ! -d "$HELIXDIR/.git" ]; then
    git clone https://github.com/helix-editor/helix "$HELIXDIR"
else
    gum style --foreground 244 "Helix repository already exists in $HELIXDIR. Updating existing installation."
    cd "$HELIXDIR"
    git checkout master
    git fetch
    git pull
    cargo install --path helix-term --locked
    hx --grammar fetch
    hx --grammar build
    ln -Ts "$PWD/runtime" ~/.config/helix/runtime
fi

gum spin --title "Select languages to install LSPs..." -- sleep 1
# Step 2: Main menu for installation options
CHOICES=$(
    gum choose --no-limit \
        "Bash" \
        "C/C++" \
        "CSS, HTML, JSON, JSONC, SCSS" \
        "Docker, Docker Compose" \
        "Go" \
        "GraphQL" \
        "JavaScript, TypeScript" \
        "Markdown" \
        "Rust" \
        "SQL" \
        "TOML" \
        "YAML"
)

# Parse choices
while IFS= read -r CHOICE; do
    case $CHOICE in
    "Bash") npm i -g bash-language-server ;;
    "C/C++") sudo dnf install clang ;;
    "CSS, HTML, JSON, JSONC, SCSS") npm i -g vscode-langservers-extracted ;;
    "Docker, Docker Compose") npm install -g dockerfile-language-server-nodejs @microsoft/compose-language-service ;;
    "Go")
        go install golang.org/x/tools/gopls@latest
        go install github.com/go-delve/delve/cmd/dlv@latest
        go install golang.org/x/tools/cmd/goimports@latest
        go install github.com/nametake/golangci-lint-langserver@latest
        go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
        ;;
    "GraphQL") npm i -g graphql-language-service-cli ;;
    "JavaScript, TypeScript") npm install -g typescript typescript-language-server && npm install --save-dev --save-exact @biomejs/biome ;;
    "Markdown") cargo install --git https://github.com/Feel-ix-343/markdown-oxide.git markdown-oxide ;;
    "Rust") sudo dnf install lldb ;;
    "SQL") npm i -g sql-language-server ;;
    "TOML") cargo install taplo-cli --locked --features lsp ;;
    "YAML") npm i -g yaml-language-server@next ;;
    esac
done <<<"$CHOICES"

# Final message
gum style --border normal --margin "1" --padding "1" \
    --align center --foreground 212 "Helix LSP installation complete!"
