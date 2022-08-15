#!/bin/bash

if [ -n "$TMUX" ]; then
    exit 0
fi

tmux has-session -t $TMUX_SESSION 2>/dev/null

if [ $? != 0 ]; then
    tmux new -s $TMUX_SESSION
else
    tmux attach -d -t $TMUX_SESSION
fi

