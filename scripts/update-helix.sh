#!/usr/bin/env bash

# Default directory
DIR=~/repos/helix/

# Parse arguments
while getopts "d:" opt; do
    case $opt in
        d) DIR="$OPTARG" ;;
        *) echo "Usage: $0 [-d directory]" >&2; exit 1 ;;
    esac
done

cd "$DIR" || { echo "Directory $DIR does not exist."; exit 1; }
git checkout master
git fetch
git pull
cargo install --path helix-term --locked
hx --grammar fetch
hx --grammar build
ln -Ts "$PWD/runtime" ~/.config/helix/runtime