#!/bin/bash

if [ -z "$1" ]; then
    echo "no session name provided"
    exit 1
fi

tmux has-session -t $1 2>/dev/null

if [ $? != 0 ]; then
    HAS_TARGET_SESSION=0
else
    HAS_TARGET_SESSION=1
fi

CURRENT_SESSION_NAME=$(tmux display-message -p '#S')

if [ -n "$TMUX" ] && [ $CURRENT_SESSION_NAME = $1 ]; then
    tmux display-message -d 1000 "Already in [$CURRENT_SESSION_NAME]"
    exit 0;
fi

if [ -z "$TMUX" ]; then
    if [ $HAS_TARGET_SESSION = 0 ]; then
        tmux new -s $1
    else
        tmux attach -t $1
    fi
    exit 0;
fi

if [ $CURRENT_SESSION_NAME != $1 ]; then
    if [ $HAS_TARGET_SESSION = 0 ]; then
        TMUX= tmux new -d -s $1
    fi
    tmux switch -t $1
    tmux display-message -d 1000 "Workspace [$CURRENT_SESSION_NAME] -> [$1]"
else
    if [ $HAS_TARGET_SESSION = 0 ]; then
        tmux new -s $1
    else
        tmux attach -d -t $1
    fi
    tmux display-message "Workspace [$1]"
fi
