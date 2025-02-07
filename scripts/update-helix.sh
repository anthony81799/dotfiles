#!/usr/bin/env bash

cd ~/repos/helix/
git checkout master
git fetch
git pull
git pull
cargo install --path helix-term --locked
hx --grammar fetch
hx --grammar build
ln -Ts $PWD/runtime ~/.config/helix/runtime
