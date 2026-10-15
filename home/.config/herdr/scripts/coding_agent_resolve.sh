#!/bin/sh
# Resolve which coding-agent CLI to launch for a directory.
# Prints one word: pi | claude | codex | agent | agy
# Pi is the default everywhere; CODING_AGENT overrides it (cursor -> agent).
#
# Usage: coding_agent_resolve.sh [dir]
#        . coding_agent_resolve.sh  # defines coding_agent_resolve()

coding_agent_resolve() {
  dir=${1:-.}

  case "${CODING_AGENT:-}" in
  pi | claude | codex | agent | agy)
    printf '%s\n' "$CODING_AGENT"
    return 0
    ;;
  cursor)
    printf '%s\n' agent
    return 0
    ;;
  esac

  printf '%s\n' pi
}

# When executed (not sourced), resolve for the given dir / $PWD.
# Under zsh `source`, $0 is this filename (FUNCTION_ARGZERO) — do not use $0 alone.
_coding_agent_resolve_run=1
case ${ZSH_EVAL_CONTEXT:-} in
*:file*) _coding_agent_resolve_run=0 ;;
esac
if [ -n "${BASH_VERSION:-}" ]; then
  # shellcheck disable=SC3054
  [ "${BASH_SOURCE[0]}" != "$0" ] && _coding_agent_resolve_run=0
fi
if [ "$_coding_agent_resolve_run" -eq 1 ]; then
  case ${0##*/} in
  coding_agent_resolve.sh)
    coding_agent_resolve "${1:-.}"
    ;;
  esac
fi
unset _coding_agent_resolve_run
