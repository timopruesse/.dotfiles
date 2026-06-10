#!/bin/sh
# Sourceable helpers shared across the Claude/harpoon tmux scripts: detecting
# Claude panes, reporting their status, checking liveness, and focusing a pane.
# Sourced by claude_sessions.sh (sidebar/picker), claude_panel*.sh, and the
# harpoon scripts.

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
  # Words are padded to a fixed width so the directory column stays aligned
  # regardless of status.
  if printf '%s' "$content" | grep -qE 'esc to interrupt|[0-9]s · |tokens\)'; then
    printf '⚪ working'
  elif printf '%s' "$content" | grep -qE '❯ [0-9]+\.|Do you want|Yes, and don|\(y/n\)|Would you like to proceed'; then
    printf '🔴 input  '
  else
    printf '🟢 idle   '
  fi
}

# clean_title <pane_title> -> the task summary Claude sets, minus its leading
# spinner glyph (e.g. "⠂ Add sidebar" -> "Add sidebar"). Empty if there's no
# usable title. Byte-wise (locale-independent): drop everything up to the first
# ASCII alphanumeric.
clean_title() {
  prefix=${1%%[A-Za-z0-9]*}
  printf '%s' "${1#"$prefix"}"
}

# pane_exists <pane_id> -> succeeds (exit 0) if the pane is still alive.
pane_exists() {
  tmux list-panes -a -F '#{pane_id}' | grep -qx "$1"
}

# claude_jump <target> -> focus a pane: switch to its session, then select its
# window and pane. <target> may be a pane id (e.g. %5, as the harpoon scripts
# use) or a session:window.pane string (as the sidebar/picker use) -- both are
# valid tmux -t targets, so display-message resolves the session either way.
claude_jump() {
  target=$1
  [ -z "$target" ] && return 1
  session=$(tmux display-message -p -t "$target" '#{session_name}' 2>/dev/null)
  [ -z "$session" ] && return 1
  tmux switch-client -t "$session"
  tmux select-window -t "$target" 2>/dev/null
  tmux select-pane -t "$target" 2>/dev/null
}
