#!/bin/sh
# Claude Code SessionStart hook: label this herdr-core terminal with the session's
# id and transcript path, so the native Herdr app's Outputs panel can read what the
# session wrote. Only acts inside an hc terminal (HC_TERMINAL_ID); never fails the hook.
set -u
[ -n "${HC_TERMINAL_ID:-}" ] || exit 0
hc=$(command -v hc 2>/dev/null || true)
[ -n "$hc" ] || { [ -x "$HOME/.local/bin/hc" ] && hc="$HOME/.local/bin/hc"; }
[ -n "$hc" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0
input=$(cat 2>/dev/null || true)
[ -n "$input" ] || exit 0
labels=$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    hook = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if hook.get("hook_event_name", "SessionStart") != "SessionStart" or hook.get("agent_id"):
    sys.exit(0)
session, transcript = hook.get("session_id"), hook.get("transcript_path")
if not isinstance(session, str) or not session or not isinstance(transcript, str) or not transcript:
    sys.exit(0)
if any(c in session + transcript for c in "\n\r\0"):
    sys.exit(0)
sys.stdout.write("agent.kind=claude\nagent.session=%s\nagent.transcript=%s\n" % (session, transcript))
' 2>/dev/null) || exit 0
[ -n "$labels" ] || exit 0
set -- "$HC_TERMINAL_ID"
while IFS= read -r label; do [ -n "$label" ] && set -- "$@" "$label"; done <<EOT
$labels
EOT
"$hc" label "$@" >/dev/null 2>&1 || true
exit 0
