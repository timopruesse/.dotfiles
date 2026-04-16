#!/bin/sh
state_file="${XDG_STATE_HOME:-$HOME/.local/state}/aws_profile"
if [ -f "$state_file" ]; then
  profile=$(cat "$state_file")
  if [ -n "$profile" ]; then
    printf '[aws: %s]' "$profile"
  fi
fi
