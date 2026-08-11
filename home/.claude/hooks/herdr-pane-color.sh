#!/bin/sh
# Rotate herdr pane color on Claude SessionStart.
# Lives beside managed herdr-agent-state.sh (do not edit that file).
# Replaces the launch-time `sleep 3` + send-text race in coding_agent_herdr.sh.
set -eu

[ "${HERDR_ENV:-}" = "1" ] || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0
[ -n "${HERDR_SOCKET_PATH:-}" ] || exit 0
command -v herdr >/dev/null 2>&1 || exit 0

hook_input_file="$(mktemp "${TMPDIR:-/tmp}/herdr-pane-color.XXXXXX")" || exit 0
trap 'rm -f "$hook_input_file"' EXIT HUP INT TERM
cat >"$hook_input_file" 2>/dev/null || true

# Skip subagent sessions — only color the parent pane.
if command -v python3 >/dev/null 2>&1; then
  if python3 - "$hook_input_file" <<'PY'
import json, sys
try:
    with open(sys.argv[1], encoding="utf-8") as f:
        raw = f.read().strip()
    if not raw:
        raise SystemExit(0)
    payload = json.loads(raw)
except Exception:
    raise SystemExit(0)
if payload.get("agent_id"):
    raise SystemExit(1)
raise SystemExit(0)
PY
  then
    :
  else
    exit 0
  fi
fi

colors="red blue green yellow purple orange pink cyan"
state_file="${XDG_STATE_HOME:-$HOME/.local/state}/claude_color_index"
idx=$(($(cat "$state_file" 2>/dev/null || echo 0) % 8 + 1))
printf '%s\n' "$idx" >"$state_file"
color=$(printf '%s\n' $colors | sed -n "${idx}p")

# SessionStart runs after the TUI is up — no launch-time sleep needed.
herdr pane send-text "$HERDR_PANE_ID" "/color $color" >/dev/null 2>&1 || true
herdr pane send-keys "$HERDR_PANE_ID" enter >/dev/null 2>&1 || true
# Dismiss any leftover slash UI the same way the old launcher did.
herdr pane send-keys "$HERDR_PANE_ID" esc >/dev/null 2>&1 || true
herdr pane send-keys "$HERDR_PANE_ID" enter >/dev/null 2>&1 || true

exit 0
