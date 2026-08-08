#!/bin/sh
# Split/tab + launch coding agent for herdr [[keys.command]] binds.
# Usage: coding_agent_bind.sh right|down|tab [resume|continue]
set -eu

layout=${1:-}
mode=${2:-}
cwd=${HERDR_ACTIVE_PANE_CWD:-${PWD}}
scripts=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
launch="$scripts/coding_agent_launch.sh"

# Best-effort project-agents for Cursor Task enum (cwd's git root).
. "$scripts/coding_agent_ensure.sh"
coding_agent_ensure_project_agents "$cwd"

pane_id_from_json() {
  python3 -c '
import json, sys
d = json.load(sys.stdin)
r = d.get("result") or {}
p = r.get("pane") or r.get("root_pane") or {}
if isinstance(p, dict):
    print(p.get("pane_id") or "")
elif isinstance(p, str):
    print(p)
'
}

case "$layout" in
right | down)
  resp=$(herdr pane split --current --direction "$layout" --cwd "$cwd" --focus)
  ;;
tab)
  resp=$(herdr tab create --cwd "$cwd" --focus)
  ;;
*)
  printf 'usage: %s right|down|tab [resume|continue]\n' "${0##*/}" >&2
  exit 1
  ;;
esac

pane=$(printf '%s\n' "$resp" | pane_id_from_json)
if [ -z "$pane" ]; then
  printf 'coding_agent_bind: failed to create pane\n%s\n' "$resp" >&2
  exit 1
fi

if [ -n "$mode" ]; then
  herdr pane run "$pane" "$launch" "$mode"
else
  herdr pane run "$pane" "$launch"
fi
