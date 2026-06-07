#!/bin/sh
# Popup picker (bound to prefix + C): pick a running Claude session and jump.
SCRIPTS="$HOME/.tmux/scripts"

panes=$("$SCRIPTS/claude_sessions.sh")

if [ -z "$panes" ]; then
  echo "No Claude agents running"
  sleep 1
  exit 0
fi

selected=$(printf '%s\n' "$panes" | fzf \
  --reverse \
  --delimiter='\t' \
  --with-nth='1,3,4' \
  --prompt="Jump to Claude > ")

if [ -n "$selected" ]; then
  target=$(printf '%s' "$selected" | cut -f2)
  session=${target%%:*}
  winpane=${target#*:}
  window=${winpane%%.*}
  tmux switch-client -t "$session"
  tmux select-window -t "${session}:${window}" 2>/dev/null
  tmux select-pane -t "$target" 2>/dev/null
fi
