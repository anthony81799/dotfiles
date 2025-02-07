#!/usr/bin/env bash

echo "Rust"
sudo dnf install lldb

echo "Bash"
npm i -g bash-language-server

echo "CSS, HTML, JSON, JSONC, SCSS"
npm i -g vscode-langservers-extracted

echo "Docker"
npm install -g dockerfile-language-server-nodejs

echo "Docker Compose"
npm install -g @microsoft/compose-language-service

echo "JavaScript and TypeScript"
npm install -g typescript typescript-language-server
npm install --save-dev --save-exact @biomejs/biome

echo "Markdown"
cargo install --git https://github.com/Feel-ix-343/markdown-oxide.git markdown-oxide

echo "SQL"
npm i -g sql-language-server

echo "TOML"
cargo install taplo-cli --locked --features lsp

echo "YAML"
npm i -g yaml-language-server@next
