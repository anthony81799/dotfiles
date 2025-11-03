# Dotfiles Installation Scripts

This repository contains a set of modular shell scripts designed to install and configure a modern Linux environment. It is primarily built for a **DNF-based distribution (like Fedora)**, featuring the **Hyprland** Wayland compositor and extensive **Terminal** customization.

The installer uses the interactive command-line tool `gum` to guide the user through the setup process.

-----

## Installation

### Prerequisites

1. **Operating System:** A distribution using the DNF package manager (e.g., Fedora, RHEL, CentOS).
2. **Tools:** `git` and `sudo` access must be available.
3. **Core Dependency:** The installer will automatically attempt to install the **`gum`** package, which is required for the interactive menus.

### Running the Installer

To install this repo run the follow command in a terminal:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/anthony81799/dotfiles/master/setup.sh)
```

Then after the machine restarts run:

```bash
./install/install.sh
```

-----

## Installation Options & Components

The installation process is split into two main phases, with the "Full Desktop" option automatically including the "Terminal Only" steps.

### 1\. Full Desktop Environment Setup

The desktop environment is centered around the **Hyprland** Wayland compositor, managed via the **omadora** project.

| Step | Component | Description |
| :--- | :--- | :--- |
| **Drivers** | NVIDIA/RPMFusion | Sets up **RPMFusion** repositories and offers optional installation of **NVIDIA drivers** and Vulkan support (`akmod-nvidia`, `vulkan-loader`). |
| **Gaming/Perf**| Bazzite/Nobara Tweaks | Installs common gaming tools (`gamescope`, `steam`, Vulkan drivers, `xpad`) and applies performance-focused kernel tweaks (`irqbalance`, low `vm.swappiness`, high `fs.inotify.max_user_watches`). |
| **omadora** | Hyprland Config | Clones and builds the **omadora** repository (which contains Hyprland dependencies and configurations) into `$HOME/.local/share/omadora`. |
| **Files** | Configuration Copy | Copies or symlinks configuration files (dotfiles) from the install directory to their respective `XDG_CONFIG_HOME` paths. |
| **Storage** | Snapper | Checks for a **Btrfs** root filesystem and offers to install and configure **Snapper** for automatic snapshot management. |
| **GUI Apps** | Applications | Installs essential graphical applications: **Brave Browser** (set as default), **VS Code**, **Dolphin** file manager, and the **Zed Editor** (via Flatpak). |
| **Boot** | SDDM & GRUB | Configures **SDDM** for automatic login to the Hyprland session and modifies **GRUB** to skip the boot menu prompt for instant startup. |

-----

### 2\. Terminal Only Setup (User Choices)

The terminal setup is highly customizable, allowing the user to select which toolchains and utilities to install.

| Category | Option | Components Installed |
| :--- | :--- | :--- |
| **Shell** | **Zsh**, **Bash**, or **Fish** | **Zsh:** Configured to use **XDG Base Directory** structure (`ZDOTDIR`) **Bash:** Installs **ble.sh** for enhancements. Installs **Oh My Posh** for prompt customization. |
| **Toolchain**| **Go** Toolchain | Installs the latest Go toolchain, sets up `GOPATH` to follow XDG standards, and installs global utilities like **`lazygit`** and **`shfmt`**. |
| **Toolchain**| **Rust** Toolchain | Installs **`rustup`** and a comprehensive list of useful **Cargo crates** (see "Key Terminal Utilities" below). Also offers optional installation/update of **Helix Editor** and its Language Servers (LSPs). |
| **Utility** | **Docker** | Installs and enables the Docker service. |
| **Utility** | **Node.js/npm** | Installs Node.js and configures **npm** to use the XDG Base Directory specification. |
| **Utility** | **XDG Ninja** | Installs the `xdg-ninja` tool for checking XDG compliance. |

-----

## Key Terminal Utilities & Configuration

The dotfiles configure several core utilities for an optimized terminal experience, primarily revealed through the environment variables and aliases in the `.zshrc`, `.bashrc`, or `config.fish` file:

### Core Tools

* **Shells:** **Zsh** (default), **Bash**, **Fish**.
* **Multiplexer:** **Zellij** is configured to auto-start upon opening the terminal.
* **History:** **Atuin** is used as a history manager.
* **File Manager:** **Yazi** is used as a terminal file manager, with a custom wrapper function (`ya()`) to allow changing the current working directory upon exit.
* **Directory Jumper:** **Zoxide** is configured for smart directory navigation.
* **Prompt:** **Oh My Posh**

### Installed Rust Crates

If the Rust option is selected, the following popular command-line utilities are installed via `cargo install`:

* **`atuin`**: History manager
* **`eza`**: `ls` replacement
* **`fd-find`**: `find` replacement
* **`ripgrep`**: `grep` replacement
* **`zoxide`**: Directory jumper
* **`bat`**: `cat` replacement
* **`bottom`**: Process viewer
* **`tealdeer`**: Simplified man pages
* **`topgrade`**: System and package updater
* **`wallust`**: Color scheme generation
* **`yazi-fm`** / **`yazi-cli`**: Terminal file manager
* **`zellij`**: Terminal multiplexer
* **`dysk`**: Disk usage analyzer
* **`ast-grep`**: Structural code search
* **`bacon`**: File watcher / code runner for Rust
* **`cargo-update`**: Allows cargo to update itself and installed crates
* **`sd`** `sed` replacement

### Environment

* **XDG Base Directory:** All scripts enforce the XDG Base Directory specification, redirecting config, data, cache, and state files away from the `$HOME` directory (`$HOME/.config`, `$HOME/.local/share`, etc.).
* **Path:** Includes essential paths for Go, Rust, npm, and custom local binaries.
* **Aliases:** Common aliases are configured, such as `ls='eza'`, `find='fd'`, `c='clear'`, `omadora='uwsm...'`, and `nv='nvim'`.
