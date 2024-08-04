#!/usr/bin/env bash

version=$1
wget https://download.oracle.com/java/$version/latest/jdk-${version}_linux-x64_bin.rpm
sudo rpm -ivh jdk-22*.rpm
java -version
