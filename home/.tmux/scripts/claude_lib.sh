#!/bin/sh
# Sourceable helpers shared across the coding-agent / harpoon tmux scripts:
# detecting Claude Code + Cursor Agent panes, reporting their status, checking
# liveness, and focusing a pane. Sourced by claude_sessions.sh (sidebar/picker),
# claude_panel*.sh, and the harpoon scripts.

# is_coding_agent_cmd <pane_current_command>
# Matches Claude Code ("claude" or bare version e.g. 2.1.168) and Cursor Agent
# ("agent" / "cursor-agent"). caffeinate wrappers are handled via the pane tty
# in is_coding_agent_pane.
is_coding_agent_cmd() {
  case "$1" in
  claude | agent | cursor-agent) return 0 ;;
  esac
  printf '%s' "$1" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+'
}

# Back-compat alias used by older call sites / docs.
is_claude_cmd() {
  is_coding_agent_cmd "$1"
}

# is_coding_agent_pane <pane_id> <pane_current_command>
# True if the pane is running a coding agent, including via caffeinate -i wrap.
is_coding_agent_pane() {
  pane_id=$1
  cmd=$2
  if is_coding_agent_cmd "$cmd"; then
    return 0
  fi
  case "$cmd" in
  caffeinate | zsh | bash | sh) ;;
  *) return 1 ;;
  esac
  tty=$(tmux display-message -p -t "$pane_id" '#{pane_tty}' 2>/dev/null)
  [ -z "$tty" ] && return 1
  # macOS ps wants the tty without /dev/; Linux accepts both.
  tty_arg=${tty#/dev/}
  ps -o comm= -t "$tty_arg" 2>/dev/null | grep -qE '^([0-9]+\.[0-9]+\.[0-9]+|claude|agent|cursor-agent)$'
}

# coding_agent_status_marker <pane_id> -> prints a padded status marker
#   🔴 input   - waiting on your confirmation/permission (needs you now)
#   🟢 idle    - finished, awaiting your next prompt (your turn)
#   ⚪ working - busy, no action needed
#
# Claude Code and Cursor Agent UIs differ; match both, fall back to idle.
coding_agent_status_marker() {
  content=$(tmux capture-pane -p -t "$1" 2>/dev/null)
  # Working: live spinner / token meter / "esc to interrupt" (Claude) or
  # Cursor Agent busy affordances.
  if printf '%s' "$content" | grep -qE 'esc to interrupt|[0-9]s · |tokens\)|Generating…|Thinking…|Running tool|Executing'; then
    printf '⚪ working'
  elif printf '%s' "$content" | grep -qE '❯ [0-9]+\.|Do you want|Yes, and don|\(y/n\)|Would you like to proceed|Allow this|Run this command|Waiting for approval|Needs your approval'; then
    printf '🔴 input  '
  else
    printf '🟢 idle   '
  fi
}

# Back-compat alias.
claude_status_marker() {
  coding_agent_status_marker "$1"
}

# clean_title <pane_title> -> the task summary the agent sets, minus its leading
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

# coding_agent_jump <target> -> focus a pane: switch to its session, then select
# its window and pane. <target> may be a pane id (e.g. %5) or session:window.pane.
coding_agent_jump() {
  target=$1
  [ -z "$target" ] && return 1
  session=$(tmux display-message -p -t "$target" '#{session_name}' 2>/dev/null)
  [ -z "$session" ] && return 1
  tmux switch-client -t "$session"
  tmux select-window -t "$target" 2>/dev/null
  tmux select-pane -t "$target" 2>/dev/null
}

# Back-compat alias.
claude_jump() {
  coding_agent_jump "$1"
}
