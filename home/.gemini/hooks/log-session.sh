#!/usr/bin/env bash
# Antigravity Stop → ~/.gemini/logs/sessions.jsonl
# Never fails the session.
set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/log_session.py" || { echo "{}"; exit 0; }
exit 0
