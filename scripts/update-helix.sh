#!/usr/bin/env bash

cd ~/repos/helix/
git checkout master
git fetch
git pull
git checkout dt-statusline
git pull
cargo install --path helix-term --locked
hx --grammar fetch
hx --grammar build
