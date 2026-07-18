#!/bin/sh
# Toggle a coding-agent sessions sidebar: a split to the right that lists every
# running Claude Code / Cursor Agent session with its status, refreshes live,
# and lets you jump.

. "$HOME/.tmux/scripts/claude_lib.sh"

existing=$(tmux show-option -gqv @claude_panel)

if [ -n "$existing" ] && pane_exists "$existing"; then
  tmux kill-pane -t "$existing"
  tmux set-option -gu @claude_panel
else
  pane=$(tmux split-window -h -l 100 -P -F '#{pane_id}' "sh $HOME/.tmux/scripts/claude_panel.sh")
  tmux set-option -g @claude_panel "$pane"
fi
