#!/bin/sh
# Sourceable helpers for detecting Claude panes and their status.
# Used by claude_sessions.sh (sidebar/picker) and the harpoon scripts.

# is_claude_cmd <pane_current_command>
# Claude Code reports its command as "claude" or its bare version (e.g. 2.1.168).
is_claude_cmd() {
  case "$1" in
  claude) return 0 ;;
  esac
  printf '%s' "$1" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+'
}

# claude_status_marker <pane_id> -> prints a padded status marker
#   🔴 input   - waiting on your confirmation/permission (needs you now)
#   🟢 idle    - finished, awaiting your next prompt (your turn)
#   ⚪ working - busy, no action needed
claude_status_marker() {
  content=$(tmux capture-pane -p -t "$1" 2>/dev/null)
  # Working: the live spinner/token-meter footer, e.g.
  #   ✳ Warping… (6m 17s · ↓ 24.7k tokens)   /   (esc to interrupt)
  if printf '%s' "$content" | grep -qE 'esc to interrupt|[0-9]s · |tokens\)'; then
    printf '⚪ working'
  elif printf '%s' "$content" | grep -qE '❯ [0-9]+\.|Do you want|Yes, and don|\(y/n\)|Would you like to proceed'; then
    printf '🔴 input  '
  else
    printf '🟢 idle   '
  fi
}
