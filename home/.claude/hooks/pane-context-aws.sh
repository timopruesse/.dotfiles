#!/usr/bin/env bash
# Claude pane-context AWS hooks — beside managed herdr-agent-state.sh (do not edit that file).
# pre:  PreToolUse/Bash — inject AWS_PROFILE via updatedInput when needed
# post: PostToolUse/PostToolUseFailure/Bash — parse profile from completed command
set -u

PANE_CONTEXT="${HOME}/.config/herdr/scripts/pane_context.sh"
action="${1:-}"

[ "${HERDR_ENV:-}" = "1" ] || exit 0
[ -n "${HERDR_SOCKET_PATH:-}" ] || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0
[ -x "$PANE_CONTEXT" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

hook_input_file="$(mktemp "${TMPDIR:-/tmp}/pane-context-claude.XXXXXX")" || exit 0
trap 'rm -f "$hook_input_file"' EXIT HUP INT TERM
cat >"$hook_input_file" 2>/dev/null || true

python3 - "$action" "$PANE_CONTEXT" "$hook_input_file" <<'PY'
import json
import subprocess
import sys

action = sys.argv[1]
pane_context = sys.argv[2]
hook_input_file = sys.argv[3]

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

if payload.get("agent_id"):
    raise SystemExit(0)

tool_name = payload.get("tool_name") or ""
if tool_name != "Bash":
    raise SystemExit(0)

tool_input = payload.get("tool_input") or {}
command = tool_input.get("command")
if not isinstance(command, str) or not command.strip():
    raise SystemExit(0)

def run_cli(*args):
    proc = subprocess.run(
        [pane_context, *args],
        capture_output=True,
        text=True,
        check=False,
    )
    return proc.stdout.strip()

if action == "pre":
    injected = run_cli("inject-prefix", command)
    if injected == command:
        raise SystemExit(0)
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "updatedInput": {
                **tool_input,
                "command": injected,
            },
        }
    }))
    raise SystemExit(0)

if action in ("post", "post-failure"):
    profile = run_cli("parse-aws-from-command", command)
    if profile:
        subprocess.run(
            [pane_context, "set-aws", profile],
            check=False,
        )
    raise SystemExit(0)

raise SystemExit(0)
PY
