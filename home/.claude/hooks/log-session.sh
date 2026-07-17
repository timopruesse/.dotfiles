#!/usr/bin/env bash
# Claude Code SessionEnd → ~/.claude/logs/sessions.jsonl
# Never fails the session.
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/log_session.py" || true
exit 0
