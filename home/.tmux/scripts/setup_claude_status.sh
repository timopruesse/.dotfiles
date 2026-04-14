#!/bin/sh
# Ensure exactly one claude_count entry in tmux status-right (reload-safe)
entry=' #[fg=#cba6f7] #(~/.tmux/scripts/claude_count.sh)'
current=$(tmux show -gv status-right 2>/dev/null || echo '')

# Strip all existing claude_count entries, then append exactly one
cleaned=$(printf '%s' "$current" | sed 's| *#\[fg=#cba6f7\] #(~/\.tmux/scripts/claude_count\.sh)||g')
tmux set -g status-right "${cleaned}${entry}"
