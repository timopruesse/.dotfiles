#!/bin/sh
# Launch the path-appropriate coding agent (claude | agent) in this pane.
# Used by tmux binds so #{pane_current_path} is already the cwd.
#
# Usage: coding_agent_launch.sh [resume|continue] [extra args...]

. "$(dirname "$0")/coding_agent_resolve.sh"

mode=
case "${1:-}" in
resume | continue)
  mode=$1
  shift
  ;;
esac

cli=$(coding_agent_resolve "$PWD")
command -v "$cli" >/dev/null 2>&1 || {
  printf '%s not found in PATH\n' "$cli" >&2
  sleep 2
  exit 1
}

case "$mode" in
resume) exec "$cli" --resume "$@" ;;
continue) exec "$cli" --continue "$@" ;;
*) exec "$cli" "$@" ;;
esac
