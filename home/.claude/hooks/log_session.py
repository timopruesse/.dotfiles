#!/usr/bin/env python3
"""Claude Code SessionEnd logger — thin adapter over session_log.claude_cost.

Reads hook JSON from stdin, builds a cost record via session_log, appends to
~/.claude/logs/sessions.jsonl. Always exits 0.
"""

from __future__ import annotations

import sys
from pathlib import Path

# home/session_log — hooks live at home/.claude/hooks/
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from session_log.claude_cost import build_record  # noqa: E402
from session_log.core import append_jsonl, log_err, read_hook_payload  # noqa: E402

LOG_DIR = Path.home() / ".claude" / "logs"
LOG_FILE = LOG_DIR / "sessions.jsonl"


def main() -> int:
    try:
        payload = read_hook_payload(sys.stdin.read())
        record = build_record(payload)
        append_jsonl(LOG_FILE, record)
    except Exception as exc:  # noqa: BLE001 — never fail the session
        log_err(LOG_DIR, str(exc))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
