#!/usr/bin/env bash

WGETCMD="wget -qO-"
CURLCMD="curl -sL"

set +e
GOBIN=$(which go 2>/dev/null)
set -e
GOLATESTURL="https://go.dev/VERSION?m=text"
set +e
GOLATEST=$($WGETCMD "$GOLATESTURL" 2>/dev/null | head -n1 || $CURLCMD "$GOLATESTURL" 2>/dev/null | head -n1)
set -e
GOLATESTPRETTY=${GOLATEST#"go"}

if [[ -z "$GOBIN" ]]; then
  wget https://dl.google.com/go/$GOLATEST.linux-amd64.tar.gz
  sudo tar -C /usr/local -xvf $GOLATEST.linux-amd64.tar.gz
  rm -rf $GOLATEST.linux-amd64.tar.gz
  go version
  go telemetry off
else
  curl -sL https://raw.githubusercontent.com/DieTime/go-up/master/go-up.sh | bash
fi
