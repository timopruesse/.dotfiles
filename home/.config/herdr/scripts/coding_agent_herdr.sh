#!/bin/sh
# Deep herdr coding-agent launch module: split/tab, pane-id parse, pane run.
# Adapters (bind.sh, zsh c*, nvim) stay thin.
#
# Usage:
#   coding_agent_herdr.sh <layout> [resume|continue] [--claude|--agent|--cursor]
#                         [--prompt-file PATH] [extra launch args...]
#
# layout: right|down|tab  (aliases: hsplit→right, vsplit→down, window→tab)
# stdout: pane_id (for last-pane tracking / optional post-launch hooks)
# cwd: HERDR_ACTIVE_PANE_CWD or PWD

set -eu

layout=${1:-}
[ -n "$layout" ] || {
  printf 'usage: %s right|down|tab|hsplit|vsplit|window [resume|continue] [flags...]\n' "${0##*/}" >&2
  exit 1
}
shift

case "$layout" in
hsplit) layout=right ;;
vsplit) layout=down ;;
window) layout=tab ;;
right | down | tab) ;;
*)
  printf 'usage: %s right|down|tab|hsplit|vsplit|window [resume|continue] [flags...]\n' "${0##*/}" >&2
  exit 1
  ;;
esac

cwd=${HERDR_ACTIVE_PANE_CWD:-${PWD}}
scripts=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
launch="$scripts/coding_agent_launch.sh"

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
esac

pane=$(printf '%s\n' "$resp" | pane_id_from_json)
if [ -z "$pane" ]; then
  printf 'coding_agent_herdr: failed to create pane\n%s\n' "$resp" >&2
  exit 1
fi

# Run launch in the new pane (policy + resolve). Silence pane-run JSON so
# stdout stays a single pane_id for adapters (nvim / zsh hooks).
# herdr pane run passes extra argv through to the command (same as old bind.sh).
if [ "$#" -eq 0 ]; then
  herdr pane run "$pane" "$launch" >/dev/null
else
  herdr pane run "$pane" "$launch" "$@" >/dev/null
fi

printf '%s\n' "$pane"
