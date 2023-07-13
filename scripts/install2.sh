#!/bin/zsh

ZSH_CUSTOM=$ZSH/custom

echo "Install custom ZSH plugins and theme."
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

echo "Install Rust and desired crates."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install bacon bat bottom cargo-update exa fd-find gitui ripgrep sd tealdeer topgrade zoxide
cargo instal --locked zellij
./scripts/update-helix.sh

echo "Install and configure npm."
sudo dnf install nodejs-npm -y
sudo npm config set prefix=${XDG_DATA_HOME}/npm;
sudo npm config set cache=${XDG_CACHE_HOME}/npm;
sudo npm config set init-module=${XDG_CONFIG_HOME}/npm/config/npm-init.js;

echo "Install language servers helix languages."

echo "Bash"
sudo npm i -g bash-language-server

echo "CSS, HTML and JSON"
sudo npm i -g vscode-langservers-extracted

echo "Go"
go install golang.org/x/tools/gopls@latest
sudo dnf install delve -y

echo "JavaScript and TypeScript"
sudo npm install -g typescript typescript-language-server

echo "Rust"
sudo dnf install lldb -y

echo "TOML"
cargo install taplo-cli --locked --features lsp

echo "The Installation is finished!"
echo "I also program in Go. See https://go.dev/doc/install for instructions on how to install Go."
neofetch
