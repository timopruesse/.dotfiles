#!/bin/sh
# Popup picker (bound to prefix + C): pick a running coding-agent session and jump.
SCRIPTS="$HOME/.tmux/scripts"
. "$SCRIPTS/claude_lib.sh"

panes=$("$SCRIPTS/claude_sessions.sh")

if [ -z "$panes" ]; then
  echo "No coding agents running"
  sleep 1
  exit 0
fi

selected=$(printf '%s\n' "$panes" | fzf \
  --reverse \
  --delimiter='\t' \
  --with-nth='1,3,4' \
  --prompt="Jump to agent > ")

if [ -n "$selected" ]; then
  coding_agent_jump "$(printf '%s' "$selected" | cut -f2)"
fi
