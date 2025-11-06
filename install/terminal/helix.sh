#!/usr/bin/env bash
# ===============================================
# Helix installer/updater + LSP installations
# ===============================================
set -euo pipefail
IFS=$'\n\t'

# Load shared library
source "${HOME}/install/lib.sh"

init_log "${LOG_DIR}/helix-install.log"

ensure_gum

banner "Helix Editor"

HELIXDIR="${HOME}/.local/share/helix"

# Ensure required commands
for cmd in git cargo; do
    if ! command -v "$cmd" &>/dev/null; then
        warn_message "Command '$cmd' not found. Installing..."
        sudo dnf install -y "$cmd" || {
            fail_message "Failed to install $cmd. Please install it manually."
            return 1
        }
    fi
done

spinner "Installing/Updating Helix and LSPs..."

# Clone or update helix
mkdir -p "$HELIXDIR"
if [ ! -d "$HELIXDIR/.git" ]; then
    spinner "Cloning Helix repository..."
    git clone https://github.com/helix-editor/helix "$HELIXDIR"
else
    spinner "Updating Helix repository..."
    cd "$HELIXDIR" || return 1
    git checkout master
    git fetch --all --prune
    git pull --rebase
    git submodule update --init --recursive || true
fi

# Build/install helix-term if present
if [ -d "$HELIXDIR/helix-term" ]; then
    spinner "Building helix-term..."
    cd "$HELIXDIR" || return 1
    # cargo install --path helix-term --locked may take time; continue on failure but log it
    if ! cargo install --path helix-term --locked || true; then
        warn_message "cargo install (helix-term) failed or already installed; continuing."
    fi
fi

# Ensure hx CLI exists (may be installed as 'hx' by cargo)
if command -v hx &>/dev/null; then
    spinner "Fetching/building Helix grammars..."
    hx --grammar fetch || true
    hx --grammar build || true
else
    warn_message "hx binary not found; skipping grammar fetch/build."
fi

# Link runtime safely
cd "$HELIXDIR" || return 1
if [ -d "runtime" ]; then
    # Use -sfn to force update of symlink atomically
    ln -sfn "$PWD/runtime" "${HOME}/.config/helix/runtime"
fi

spinner "Select languages to install LSPs..."

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

# Installers: check and install package managers only when needed
while IFS= read -r CHOICE; do
    case "$CHOICE" in
    "Bash")
        if ! has_cmd npm; then sudo dnf install -y npm; fi
        npm i -g bash-language-server || true
        ;;
    "C/C++")
        sudo dnf install -y clang || true
        ;;
    "CSS, HTML, JSON, JSONC, SCSS")
        if ! has_cmd npm; then sudo dnf install -y npm; fi
        npm i -g vscode-langservers-extracted || true
        ;;
    "Docker, Docker Compose")
        if ! has_cmd npm; then sudo dnf install -y npm; fi
        npm install -g dockerfile-language-server-nodejs @microsoft/compose-language-service || true
        ;;
    "Go")
        if ! has_cmd go; then sudo dnf install -y golang || true; fi
        if has_cmd go; then
            go install golang.org/x/tools/gopls@latest || true
            go install github.com/go-delve/delve/cmd/dlv@latest || true
            go install golang.org/x/tools/cmd/goimports@latest || true
            go install github.com/nametake/golangci-lint-langserver@latest || true
            go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest || true
        fi
        ;;
    "GraphQL")
        if ! has_cmd npm; then sudo dnf install -y npm; fi
        npm i -g graphql-language-service-cli || true
        ;;
    "JavaScript, TypeScript")
        if ! has_cmd npm; then sudo dnf install -y npm; fi
        npm install -g typescript typescript-language-server || true
        ;;
    "Markdown")
        if ! has_cmd cargo; then sudo dnf install -y cargo || true; fi
        cargo install --git https://github.com/Feel-ix-343/markdown-oxide.git markdown-oxide || true
        ;;
    "Rust")
        sudo dnf install -y lldb || true
        ;;
    "SQL")
        if ! has_cmd npm; then sudo dnf install -y npm; fi
        npm i -g sql-language-server || true
        ;;
    "TOML")
        if ! has_cmd cargo; then sudo dnf install -y cargo || true; fi
        cargo install taplo-cli --locked --features lsp || true
        ;;
    "YAML")
        if ! has_cmd npm; then sudo dnf install -y npm; fi
        npm i -g yaml-language-server@next || true
        ;;
    esac
done <<<"$CHOICES"

finish "Helix LSP installation complete!"
