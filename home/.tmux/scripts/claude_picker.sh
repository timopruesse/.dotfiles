#!/bin/sh
# Popup picker (bound to prefix + C): pick a running Claude session and jump.
SCRIPTS="$HOME/.tmux/scripts"
. "$SCRIPTS/claude_lib.sh"

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
  claude_jump "$(printf '%s' "$selected" | cut -f2)"
fi
