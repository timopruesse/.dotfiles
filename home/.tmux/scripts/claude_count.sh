#!/bin/sh
# Status-bar counter: total running Claude sessions, with a ⚠ marker and the
# number of sessions currently waiting on your input.
list=$("$HOME/.tmux/scripts/claude_sessions.sh")
[ -z "$list" ] && exit 0

total=$(printf '%s\n' "$list" | grep -c .)
needs=$(printf '%s\n' "$list" | grep -c '🔴')

if [ "$needs" -gt 0 ]; then
  printf '[claude: %d ⚠ %d]' "$total" "$needs"
else
  printf '[claude: %d]' "$total"
fi
