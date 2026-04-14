#!/bin/sh
count=$(tmux list-panes -a -F '#{pane_current_command}' 2>/dev/null | grep -ci claude)
if [ "$count" -gt 0 ]; then
  printf '[claude: %d]' "$count"
fi
