#!/bin/sh
# Create agent layout relative to the caller, never the UI-focused space.
# Usage: coding_agent_create_pane right|down|tab cwd [creation flags...]
coding_agent_create_pane() (
  layout=$1
  cwd=$2
  shift 2

  if [ -z "${HERDR_PANE_ID:-}" ]; then
    printf '%s\n' 'coding_agent: missing caller pane; refusing to use the focused space' >&2
    exit 1
  fi

  # Resolve live context: inherited workspace IDs can be stale after pane moves.
  context=$(herdr pane current --current) || exit 1
  workspace=$(printf '%s\n' "$context" | python3 -c '
import json, sys
pane = json.load(sys.stdin).get("result", {}).get("pane", {})
workspace = pane.get("workspace_id")
if not isinstance(workspace, str) or not workspace:
    sys.exit("coding_agent: caller workspace could not be resolved")
print(workspace)
') || exit 1

  case "$layout" in
  right | down)
    herdr pane split --current --direction "$layout" --cwd "$cwd" "$@"
    ;;
  tab)
    herdr tab create --workspace "$workspace" --cwd "$cwd" "$@"
    ;;
  *)
    printf 'coding_agent: unknown layout: %s\n' "$layout" >&2
    exit 1
    ;;
  esac
)
