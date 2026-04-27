#!/bin/bash

if [ -z "$1" ]; then
    echo "No session name provided"
    exit 1
fi

if [ -n "$TMUX" ]; then
    if ! tmux has-session -t "$1" 2>/dev/null; then
        tmux new-session -d -s "$1"
    fi
    tmux switch-client -t "$1"
else
    tmux new -A -s "$1"
fi
