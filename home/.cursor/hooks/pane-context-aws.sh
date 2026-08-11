#!/usr/bin/env bash
# Cursor pane-context AWS hooks.
# preToolUse/Shell: inject AWS_PROFILE via updated_input when needed
# afterShellExecution: parse profile from completed shell command
set -u

PANE_CONTEXT="${HOME}/.config/herdr/scripts/pane_context.sh"

[ "${HERDR_ENV:-}" = "1" ] || exit 0
[ -n "${HERDR_SOCKET_PATH:-}" ] || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0
[ -x "$PANE_CONTEXT" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

hook_input_file="$(mktemp "${TMPDIR:-/tmp}/pane-context-cursor.XXXXXX")" || exit 0
trap 'rm -f "$hook_input_file"' EXIT HUP INT TERM
cat >"$hook_input_file" 2>/dev/null || true

python3 - "$PANE_CONTEXT" "$hook_input_file" <<'PY'
import json
import subprocess
import sys

pane_context = sys.argv[1]
hook_input_file = sys.argv[2]

try:
    with open(hook_input_file, encoding="utf-8") as handle:
        raw = handle.read().strip()
except OSError:
    raise SystemExit(0)

if not raw:
    raise SystemExit(0)

try:
    payload = json.loads(raw)
except json.JSONDecodeError:
    raise SystemExit(0)

event = payload.get("hook_event_name") or payload.get("hookEventName") or ""

def run_cli(*args):
    proc = subprocess.run(
        [pane_context, *args],
        capture_output=True,
        text=True,
        check=False,
    )
    return proc.stdout.strip()

if event == "preToolUse":
    if payload.get("tool_name") != "Shell":
        raise SystemExit(0)
    tool_input = payload.get("tool_input") or {}
    command = tool_input.get("command")
    if not isinstance(command, str) or not command.strip():
        raise SystemExit(0)
    injected = run_cli("inject-prefix", command)
    if injected == command:
        raise SystemExit(0)
    updated = dict(tool_input)
    updated["command"] = injected
    print(json.dumps({"permission": "allow", "updated_input": updated}))
    raise SystemExit(0)

if event == "afterShellExecution":
    command = payload.get("command")
    if not isinstance(command, str) or not command.strip():
        raise SystemExit(0)
    profile = run_cli("parse-aws-from-command", command)
    if profile:
        subprocess.run([pane_context, "set-aws", profile], check=False)
    raise SystemExit(0)

raise SystemExit(0)
PY
