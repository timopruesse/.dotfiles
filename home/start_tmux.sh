#!/bin/bash

if [ -z "$1" ]; then
  echo "no session name provided"
  exit 1
fi

if [ -n "$TMUX" ]; then
  tmux switch -t $1
  exit 0
fi

tmux new -A -s $1
