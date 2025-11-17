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

for cmd in git cargo; do
	if ! command -v "$cmd" &>/dev/null; then
		warn_message "Command '$cmd' not found. Installing..."
		sudo dnf install -y "$cmd" || {
			fail_message "Failed to install $cmd. Please install it manually."
		}
	fi
done

spinner "Installing/Updating Helix and LSPs..."

mkdir -p "$HELIXDIR"
if [ ! -d "$HELIXDIR/.git" ]; then
	spinner "Cloning Helix repository..."
	git clone https://github.com/helix-editor/helix "$HELIXDIR"
else
	spinner "Updating Helix repository..."
	cd "$HELIXDIR"
	git checkout master
	git fetch --all --prune
	git pull --rebase
	git submodule update --init --recursive
fi

if [ -d "$HELIXDIR/helix-term" ]; then
	spinner "Building helix-term..."
	cd "$HELIXDIR"
	if ! cargo install --path helix-term --locked; then
		warn_message "cargo install (helix-term) failed or already installed; continuing."
	fi
fi

if command -v hx &>/dev/null; then
	spinner "Fetching/building Helix grammars..."
	hx --grammar fetch
	hx --grammar build
else
	warn_message "hx binary not found; skipping grammar fetch/build."
fi

cd "$HELIXDIR"
if [ -d "runtime" ]; then
	ln -sfn "$PWD/runtime" "${HOME}/.config/helix/runtime"
fi

spinner "Select languages to install LSPs..."

CHOICES=$(
	gum choose --no-limit \
		--header "Select languages to install LSPs for Helix" \
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

DNF_LSP_DEPS=()
declare -A NEEDED_PKG_CHECK=(["npm"]=false ["clang"]=false ["golang"]=false ["lldb"]=false)

# First pass: identify and collect all DNF dependencies
while IFS= read -r CHOICE; do
	case "$CHOICE" in
	"Bash" | "CSS, HTML, JSON, JSONC, SCSS" | "Docker, Docker Compose" | "GraphQL" | "JavaScript, TypeScript" | "SQL" | "YAML")
		if [ "${NEEDED_PKG_CHECK["npm"]}" = false ] && ! has_cmd npm; then
			DNF_LSP_DEPS+=("npm")
			NEEDED_PKG_CHECK["npm"]=true
		fi
		;;
	"C/C++")
		if [ "${NEEDED_PKG_CHECK["clang"]}" = false ] && ! has_cmd clang; then
			DNF_LSP_DEPS+=("clang")
			NEEDED_PKG_CHECK["clang"]=true
		fi
		;;
	"Go")
		if [ "${NEEDED_PKG_CHECK["golang"]}" = false ] && ! has_cmd go; then
			DNF_LSP_DEPS+=("golang")
			NEEDED_PKG_CHECK["golang"]=true
		fi
		;;
	"Rust")
		if [ "${NEEDED_PKG_CHECK["lldb"]}" = false ] && ! has_cmd lldb; then
			DNF_LSP_DEPS+=("lldb")
			NEEDED_PKG_CHECK["lldb"]=true
		fi
		;;
	esac
done <<<"$CHOICES"

if [ ${#DNF_LSP_DEPS[@]} -gt 0 ]; then
	spinner "Installing consolidated DNF dependencies for LSPs: ${DNF_LSP_DEPS[*]}..."
	sudo dnf install -y "${DNF_LSP_DEPS[@]}" || warn_message "Failed to install some DNF LSP dependencies. Continuing with LSP installs."
fi

spinner "Starting individual LSP installations..."
while IFS= read -r CHOICE; do
	case "$CHOICE" in
	"Bash")
		npm i -g bash-language-server || true
		;;
	"C/C++")
		info_message "C/C++ dependencies (clang) installation attempted."
		;;
	"CSS, HTML, JSON, JSONC, SCSS")
		npm i -g vscode-langservers-extracted || true
		;;
	"Docker, Docker Compose")
		npm install -g dockerfile-language-server-nodejs @microsoft/compose-language-service || true
		;;
	"Go")
		if has_cmd go; then
			go install golang.org/x/tools/gopls@latest || true
			go install github.com/go-delve/delve/cmd/dlv@latest || true
			go install golang.org/x/tools/cmd/goimports@latest || true
			go install github.com/nametake/golangci-lint-langserver@latest || true
			go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest || true
			info_message "Go LSPs installation attempted."
		else
			warn_message "Go LSPs selected, but 'go' command not found after dependency install. Skipping Go tools."
		fi
		;;
	"GraphQL")
		npm i -g graphql-language-service-cli || true
		;;
	"JavaScript, TypeScript")
		npm install -g typescript typescript-language-server || true
		;;
	"Markdown")
		cargo binstall --no-confirm --git 'https://github.com/feel-ix-343/markdown-oxide' markdown-oxide || true
		;;
	"Rust")
		info_message "Rust dependencies (lldb) installation attempted."
		;;
	"SQL")
		npm i -g sql-language-server || true
		;;
	"TOML")
		cargo binstall --no-confirm taplo-cli || true
		;;
	"YAML")
		npm i -g yaml-language-server@next || true
		;;
	esac
done <<<"$CHOICES"

finish "Helix LSP installation complete!"
