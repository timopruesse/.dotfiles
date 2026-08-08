#!/bin/sh
# Resolve which coding-agent CLI to launch for a directory.
# Prints one word: claude | agent
#
# Precedence:
#   1. CODING_AGENT=claude|agent (env override)
#   2. Git remote org: chewielabs → claude; timopruesse → agent
#   3. Path: ~/github/chewielabs → claude; everything else → agent
#
# Usage: coding_agent_resolve.sh [dir]
#        . coding_agent_resolve.sh  # defines coding_agent_resolve()

coding_agent_resolve() {
  dir=${1:-.}

  case "${CODING_AGENT:-}" in
  claude | agent)
    printf '%s\n' "$CODING_AGENT"
    return 0
    ;;
  esac

  # Absolute path for path-prefix matching (best-effort if dir is missing).
  abs=
  if abs=$(CDPATH= cd -- "$dir" 2>/dev/null && pwd -P); then
    :
  else
    abs=$dir
  fi

  # Remote-URL wins over path (worktrees live under ~/.cursor or ~/.claude).
  if remotes=$(git -C "$dir" remote -v 2>/dev/null); then
    case "$remotes" in
    *github.com[:/]chewielabs/* | *github.com[:/]chewielabs.git*)
      printf '%s\n' claude
      return 0
      ;;
    *github.com[:/]timopruesse/* | *github.com[:/]timopruesse.git*)
      printf '%s\n' agent
      return 0
      ;;
    esac
  fi

  case "$abs" in
  "$HOME/github/chewielabs" | "$HOME/github/chewielabs"/*)
    printf '%s\n' claude
    ;;
  *)
    printf '%s\n' agent
    ;;
  esac
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
