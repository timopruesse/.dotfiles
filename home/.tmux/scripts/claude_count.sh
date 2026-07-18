#!/bin/sh
# Status-bar counter: total running coding-agent sessions (Claude + Cursor),
# with a ⚠ marker and the number of sessions currently waiting on your input.
list=$("$HOME/.tmux/scripts/claude_sessions.sh")
[ -z "$list" ] && exit 0

total=$(printf '%s\n' "$list" | grep -c .)
needs=$(printf '%s\n' "$list" | grep -c '🔴')

if [ "$needs" -gt 0 ]; then
  printf '[ai: %d ⚠ %d]' "$total" "$needs"
else
  printf '[ai: %d]' "$total"
fi
