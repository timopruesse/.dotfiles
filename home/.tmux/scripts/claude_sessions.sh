#!/bin/sh
# List running Claude Code panes, one per line, tagged with a status marker.
#
# Output is tab-separated: <marker>\t<target>\t<window-name>\t<dir>
#   marker  - human-readable status (shown)
#   target  - session:window.pane, used to jump (hidden in the picker)
#
# Status meanings:
#   🔴 input   - waiting for your confirmation/permission (needs you now)
#   🟢 idle    - finished, awaiting your next prompt (your turn)
#   ⚪ working - busy, no action needed

# Claude Code reports its pane command either as "claude" or as its bare
# version string (e.g. 2.1.168 on macOS), so accept both.
is_claude() {
  case "$1" in
  claude) return 0 ;;
  esac
  printf '%s' "$1" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+'
}

status_of() {
  content=$(tmux capture-pane -p -t "$1" 2>/dev/null)
  # Working: the live spinner/token-meter footer, e.g.
  #   ✳ Warping… (6m 17s · ↓ 24.7k tokens)   /   (esc to interrupt)
  if printf '%s' "$content" | grep -qE 'esc to interrupt|[0-9]s · |tokens\)'; then
    printf 'working'
  elif printf '%s' "$content" | grep -qE '❯ [0-9]+\.|Do you want|Yes, and don|\(y/n\)|Would you like to proceed'; then
    printf 'input'
  else
    printf 'idle'
  fi
}

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

    is_claude "$cmd" || continue

    case "$(status_of "$pane")" in
    working) marker='⚪ working' ;;
    input) marker='🔴 input  ' ;;
    idle) marker='🟢 idle   ' ;;
    esac

    printf '%s\t%s\t%s\t%s\n' "$marker" "$target" "$wname" "${path##*/}"
  done
