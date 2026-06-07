#!/bin/sh
# Toggle a Claude sessions sidebar: a split to the right that lists every
# running Claude session with its status, refreshes live, and lets you jump.

existing=$(tmux show-option -gqv @claude_panel)

if [ -n "$existing" ] && tmux list-panes -a -F '#{pane_id}' | grep -qx "$existing"; then
  tmux kill-pane -t "$existing"
  tmux set-option -gu @claude_panel
else
  pane=$(tmux split-window -h -l 50 -P -F '#{pane_id}' "sh $HOME/.tmux/scripts/claude_panel.sh")
  tmux set-option -g @claude_panel "$pane"
fi
