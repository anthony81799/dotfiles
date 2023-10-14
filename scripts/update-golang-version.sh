#!/usr/bin/env bash

version=$1
sudo rm -rvf /usr/local/go
wget https://dl.google.com/go/go$version.linux-amd64.tar.gz
sudo tar -C /usr/local -xvf go$version.linux-amd64.tar.gz
rm -rf go$version.linux-amd64.tar.gz
go version
