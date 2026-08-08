#!/bin/sh
# Best-effort: link pinned Cursor agents into <git-root>/.cursor/agents/
# so Task/CLI can discover them (project-agents). Never fails the launcher.
#
# Usage: . coding_agent_ensure.sh   # defines coding_agent_ensure_project_agents
#        coding_agent_ensure.sh     # runs once when executed

coding_agent_ensure_project_agents() {
  _ensure=
  for _cand in \
    "${DOTFILES:+$DOTFILES/home/sync/ensure-project-agents}" \
    "$HOME/sync/ensure-project-agents" \
    "$HOME/github/timopruesse/.dotfiles/home/sync/ensure-project-agents"; do
    if [ -n "$_cand" ] && [ -x "$_cand" ]; then
      _ensure=$_cand
      break
    fi
  done
  if [ -z "$_ensure" ]; then
    unset _ensure _cand
    return 0
  fi
  "$_ensure" -q "$@" >/dev/null 2>&1 || true
  unset _ensure _cand
  return 0
}

# Under zsh `source`, $0 is this filename (FUNCTION_ARGZERO) — do not use $0 alone.
_coding_agent_ensure_run=1
case ${ZSH_EVAL_CONTEXT:-} in
*:file*) _coding_agent_ensure_run=0 ;;
esac
if [ -n "${BASH_VERSION:-}" ]; then
  # shellcheck disable=SC3054
  [ "${BASH_SOURCE[0]}" != "$0" ] && _coding_agent_ensure_run=0
fi
if [ "$_coding_agent_ensure_run" -eq 1 ]; then
  case ${0##*/} in
  coding_agent_ensure.sh)
    coding_agent_ensure_project_agents "$@"
    ;;
  esac
fi
unset _coding_agent_ensure_run
