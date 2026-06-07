#!/bin/sh
# List running Claude Code panes, one per line, tagged with a status marker.
#
# Output is tab-separated: <marker>\t<target>\t<title>\t<dir>
#   marker  - human-readable status (shown)
#   target  - session:window.pane, used to jump (hidden in the picker)
#   title   - the task summary Claude sets as the pane title
#   dir     - basename of the working directory (context)
#
# Helpers are defined in claude_status.sh.

. "$(dirname "$0")/claude_status.sh"

tmux list-panes -a -F '#{pane_id}|@|#{pane_current_command}|@|#{session_name}:#{window_index}.#{pane_index}|@|#{pane_title}|@|#{pane_current_path}' 2>/dev/null |
  while IFS= read -r line; do
    pane=${line%%|@|*}
    rest=${line#*|@|}
    cmd=${rest%%|@|*}
    rest=${rest#*|@|}
    target=${rest%%|@|*}
    rest=${rest#*|@|}
    ptitle=${rest%%|@|*}
    rest=${rest#*|@|}
    path=$rest

    is_claude_cmd "$cmd" || continue

    dir=${path##*/}
    title=$(clean_title "$ptitle")
    [ -z "$title" ] && title="$dir"

    # Trailing spaces on the dir field widen the gap before the title in the
    # sidebar (fzf joins displayed columns with a single space).
    printf '%s\t%s\t%s\t%s   \n' "$(claude_status_marker "$pane")" "$target" "$title" "$dir"
  done
