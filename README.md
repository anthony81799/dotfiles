# Dotfiles

Personal dotfiles for a modern Linux environment, built for **Fedora** (DNF-based). Includes configurations for terminal emulators, editors, shells, and a set of modular install scripts for bootstrapping a new machine.

The installer uses [`gum`](https://github.com/charmbracelet/gum) for interactive menus.

---

## Installation

### Prerequisites

- A DNF-based Linux distribution (Fedora, RHEL, etc.)
- `git` and `sudo` access
- The installer will automatically install `gum` if it is not present

### Running the Installer

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/anthony81799/dotfiles/master/install.sh)
```

The script will:

1. Clone this repo to `~/dotfiles`
2. Symlink all configs from `~/dotfiles/config/` to their correct `~/.config/` locations
3. Prompt for an installation type and run the selected scripts

---

## How Config Symlinking Works

All configurations live under `dotfiles/config/`. The installer creates symlinks so apps find them at their expected XDG paths:

| Source | Symlinked to |
| :--- | :--- |
| `config/<dir>/` | `~/.config/<dir>/` |
| `config/shell_aliases` | `~/.config/shell_aliases` |
| `config/topgrade.toml` | `~/.config/topgrade.toml` |
| `config/.bashrc` | `~/.bashrc` |
| `config/zsh/.zshenv` | `~/.zshenv` (sets `ZDOTDIR` for zsh) |

Existing files are backed up with a `.bak` extension before linking. Re-running `install.sh` on an existing machine will pull the latest changes and refresh all symlinks.

---

## Configurations

| Directory | Application |
| :--- | :--- |
| `config/alacritty/` | [Alacritty](https://alacritty.org/) terminal emulator |
| `config/atuin/` | [Atuin](https://github.com/atuinsh/atuin) shell history |
| `config/fastfetch/` | [Fastfetch](https://github.com/fastfetch-cli/fastfetch) system info |
| `config/fish/` | [Fish](https://fishshell.com/) shell config |
| `config/ghostty/` | [Ghostty](https://ghostty.org/) terminal emulator |
| `config/git/` | Git global config and global gitignore |
| `config/gitui/` | [Gitui](https://github.com/extrawurst/gitui) TUI theme |
| `config/glow/` | [Glow](https://github.com/charmbracelet/glow) markdown renderer |
| `config/helix/` | [Helix](https://helix-editor.com/) editor config and language servers |
| `config/kitty/` | [Kitty](https://sw.kovidgoyal.net/kitty/) terminal emulator |
| `config/npm/` | npm XDG-compliant config (`npmrc`) |
| `config/nvim/` | [Neovim](https://neovim.io/) (LazyVim) config |
| `config/oh-my-posh/` | [Oh My Posh](https://ohmyposh.dev/) prompt theme |
| `config/wezterm/` | [WezTerm](https://wezfurlong.org/wezterm/) terminal emulator |
| `config/xplr/` | [xplr](https://xplr.dev/) file manager config |
| `config/zellij/` | [Zellij](https://zellij.dev/) terminal multiplexer |
| `config/zsh/` | Zsh config (`.zshrc`, `.zprofile`, `.zshenv`) |
| `config/shell_aliases` | Shared aliases sourced by both zsh and fish |
| `config/topgrade.toml` | [Topgrade](https://github.com/topgrade-rs/topgrade) updater config |

---

## Installation Options

The installer is split into two modes. **Full Desktop** runs both.

### Terminal Only

| Script | What it does |
| :--- | :--- |
| `change-shell.sh` | Sets default shell (Zsh / Bash / Fish). Installs `ble.sh` for Bash. |
| `git.sh` | Configures global Git identity and settings (uses `delta` as pager). |
| `golang.sh` | Installs or updates the Go toolchain; optional Go tools (`lazygit`, `gopls`, `dlv`, etc.). |
| `rust.sh` | Installs `rustup` and a set of Cargo crates via `cargo-binstall`. |
| `editor.sh` | Offers Neovim and/or Helix installation. |
| `oh-my-posh.sh` | Installs or updates Oh My Posh to `~/.local/bin`. |
| `helix.sh` | Builds Helix from source and optionally installs LSPs. |
| `docker-services.sh` | Installs Docker and optionally deploys self-hosted services via Compose. |

### Full Desktop (adds)

| Script | What it does |
| :--- | :--- |
| `nvidia.sh` | Detects your NVIDIA GPU generation and installs the correct RPMFusion `akmod` driver. |
| `gui-apps.sh` | Installs Dolphin, Thunderbird, Discord, Brave Browser, and LocalSend (Flatpak). |
| `editor.sh` (desktop) | Offers VS Code, VSCodium, and Zed editor installation. |
| `terminal-emulator.sh` | Choose one of Alacritty, Kitty, WezTerm, or Ghostty to install. |

---

## Key Terminal Utilities

### Shells

- **Zsh** (default): configured via `ZDOTDIR=~/.config/zsh`. Uses `zinit` for plugins (syntax highlighting, autosuggestions, `fzf-tab`).
- **Fish**: full XDG-compliant config with abbreviations, functions, and plugin support.
- **Bash**: enhanced with `ble.sh`.

All shells share aliases via `~/.config/shell_aliases`.

### Core Tools

| Tool | Role |
| :--- | :--- |
| [Zellij](https://zellij.dev/) | Terminal multiplexer (auto-starts on shell open) |
| [Atuin](https://github.com/atuinsh/atuin) | Shell history with sync |
| [Zoxide](https://github.com/ajeetdsouza/zoxide) | Smart `cd` replacement |
| [Yazi](https://github.com/sxyazi/yazi) | Terminal file manager (`ya()` wrapper to `cd` on exit) |
| [Oh My Posh](https://ohmyposh.dev/) | Shell prompt |
| [Eza](https://eza.rocks/) | `ls` replacement |
| [Bat](https://github.com/sharkdp/bat) | `cat` replacement |
| [Ripgrep](https://github.com/BurntSushi/ripgrep) | `grep` replacement |
| [fd](https://github.com/sharkdp/fd) | `find` replacement |
| [Delta](https://github.com/dandavison/delta) | Git diff pager |
| [Lazygit](https://github.com/jesseduffield/lazygit) | Git TUI |

### Rust Crates installed by `rust.sh`

`ast-grep`, `atuin`, `bacon`, `bat`, `bottom`, `broot`, `cargo-info`, `cargo-update`,
`du-dust`, `dysk`, `eza`, `fd-find`, `git-delta`, `hyperfine`, `procs`, `ripgrep`,
`rusty-man`, `sd`, `tealdeer`, `tokei`, `topgrade`, `xplr`, `zellij`, `zoxide`

### XDG Compliance

All configs and tools are redirected away from `$HOME` using the XDG Base Directory spec:

| Variable | Path |
| :--- | :--- |
| `XDG_CONFIG_HOME` | `~/.config` |
| `XDG_DATA_HOME` | `~/.local/share` |
| `XDG_CACHE_HOME` | `~/.cache` |
| `XDG_STATE_HOME` | `~/.local/state` |

Tools affected: Cargo, rustup, Go, npm, Git, Less, MySQL history, Java, .NET, Azure CLI, Docker, X11 compose.
