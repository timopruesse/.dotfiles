#!/bin/sh
pane_pid=$(tmux display-message -p '#{pane_pid}' 2>/dev/null)
if [ -z "$pane_pid" ]; then
  exit 0
fi

# Walk child processes to find the active shell's AWS_PROFILE
profile=""
for child in $(pgrep -P "$pane_pid" 2>/dev/null) "$pane_pid"; do
  val=$(cat "/proc/$child/environ" 2>/dev/null | tr '\0' '\n' | grep '^AWS_PROFILE=' | cut -d= -f2-)
  if [ -n "$val" ]; then
    profile="$val"
    break
  fi
done

if [ -n "$profile" ]; then
  printf '[aws: %s]' "$profile"
fi
