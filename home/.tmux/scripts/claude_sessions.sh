#!/bin/sh
# List running Claude Code panes, one per line, tagged with a status marker.
#
# Output is tab-separated: <marker>\t<target>\t<window-name>\t<dir>
#   marker  - human-readable status (shown)
#   target  - session:window.pane, used to jump (hidden in the picker)
#
# Status markers are defined in claude_status.sh.

. "$(dirname "$0")/claude_status.sh"

tmux list-panes -a -F '#{pane_id}|@|#{pane_current_command}|@|#{session_name}:#{window_index}.#{pane_index}|@|#{window_name}|@|#{pane_current_path}' 2>/dev/null |
  while IFS= read -r line; do
    pane=${line%%|@|*}
    rest=${line#*|@|}
    cmd=${rest%%|@|*}
    rest=${rest#*|@|}
    target=${rest%%|@|*}
    rest=${rest#*|@|}
    wname=${rest%%|@|*}
    rest=${rest#*|@|}
    path=$rest

    is_claude_cmd "$cmd" || continue

    printf '%s\t%s\t%s\t%s\n' "$(claude_status_marker "$pane")" "$target" "$wname" "${path##*/}"
  done
