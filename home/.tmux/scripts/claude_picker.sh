#!/bin/sh
panes=$(tmux list-panes -a -F '#{pane_current_command} #{session_name}:#{window_index}.#{pane_index}  tab #{window_index}: #{pane_title}  #{pane_current_path}' 2>/dev/null | grep -i '^claude ' | sed 's/^[^ ]* //')

if [ -z "$panes" ]; then
  echo "No Claude agents running"
  sleep 1
  exit 0
fi

selected=$(echo "$panes" | fzf --reverse --prompt="Jump to Claude > ")

if [ -n "$selected" ]; then
  target=$(echo "$selected" | awk '{print $1}')
  tmux switch-client -t "$target"
fi
