#!/bin/sh
session=$(tmux display-message -p '#{session_name}' 2>/dev/null)
if [ -z "$session" ]; then
  exit 0
fi

state_file="${XDG_STATE_HOME:-$HOME/.local/state}/aws_profile_${session}"
if [ -f "$state_file" ]; then
  profile=$(cat "$state_file")
  if [ -n "$profile" ]; then
    printf '[aws: %s]' "$profile"
  fi
fi
