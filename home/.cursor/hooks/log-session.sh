#!/usr/bin/env bash
# Cursor sessionStart / subagentStop / sessionEnd → ~/.cursor/logs/sessions.jsonl
# Working directory for user hooks is ~/.cursor/; this script lives in ./hooks/.
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/log_session.py" || true
exit 0
