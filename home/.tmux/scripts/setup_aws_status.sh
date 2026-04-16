#!/bin/sh
# Ensure exactly one aws_profile entry in tmux status-right (reload-safe)
entry=' #[fg=#f9e2af] #(~/.tmux/scripts/aws_profile.sh)'
current=$(tmux show -gv status-right 2>/dev/null || echo '')

# Strip all existing aws_profile entries, then append exactly one
cleaned=$(printf '%s' "$current" | sed 's| *#\[fg=#f9e2af\] #(~/\.tmux/scripts/aws_profile\.sh)||g')
tmux set -g status-right "${cleaned}${entry}"
