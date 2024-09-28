#!/bin/bash

if [ -z "$1" ]; then
    echo "No session name provided"
    exit 1
fi

create_or_switch_session() {
    if ! tmux has-session -t $1 2>/dev/null; then
        tmux new-session -d -s $1
    fi
    tmux switch-client -t $1
}

if [ -n "$TMUX" ]; then
    create_or_switch_session $1
else
    tmux new -A -s $1
fi
