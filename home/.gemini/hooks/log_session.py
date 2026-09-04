#!/usr/bin/env python3
"""Antigravity (agy) session cost/performance logger.

Hook (via hooks.json):
  Stop — flush one JSONL line to ~/.gemini/logs/sessions.jsonl

Always exits 0 and prints `{}` on stdout as required by Antigravity Stop contract.
Antigravity does not expose token billing in hooks; cost_usd_estimate is null.
Parses the transcript for session duration, subagents, models, and slash commands.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

# home/session_log — hooks live at home/.gemini/hooks/
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from session_log.core import (  # noqa: E402
    append_jsonl,
    extract_agy_transcript_data,
    log_err,
    now_iso,
    read_hook_payload,
)

LOG_DIR = Path.home() / ".gemini" / "logs"
LOG_FILE = LOG_DIR / "sessions.jsonl"


def _resolve_transcript_path(payload: dict[str, Any], sid: str) -> Path | None:
    raw = payload.get("transcriptPath") or payload.get("transcript_path")
    if raw:
        p = Path(raw).expanduser()
        if p.is_file():
            return p
    # Fallback to standard CLI brain location
    brain_path = (
        Path.home()
        / ".gemini"
        / "antigravity-cli"
        / "brain"
        / sid
        / ".system_generated"
        / "logs"
        / "transcript.jsonl"
    )
    if brain_path.is_file():
        return brain_path
    return None


def handle_stop(payload: dict[str, Any]) -> None:
    sid = (
        payload.get("conversationId")
        or payload.get("conversation_id")
        or payload.get("sessionId")
        or payload.get("session_id")
        or "unknown"
    )
    workspace_paths = (
        payload.get("workspacePaths")
        or payload.get("workspace_paths")
        or []
    )
    cwd = (
        workspace_paths[0]
        if isinstance(workspace_paths, list) and workspace_paths
        else None
    )

    reason = (
        payload.get("terminationReason")
        or payload.get("termination_reason")
        or "model_stop"
    )
    error = payload.get("error") or ""
    success = not error and reason in ("model_stop", "completed", "")

    transcript_path = _resolve_transcript_path(payload, sid)
    transcript_data = (
        extract_agy_transcript_data(transcript_path)
        if transcript_path
        else {"duration_ms": None, "models": [], "subagents": [], "commands": []}
    )

    models = list(transcript_data.get("models") or [])
    model_name = payload.get("modelName") or payload.get("model_name")
    if model_name and model_name != "auto" and model_name not in models:
        models.insert(0, model_name)

    record = {
        "ts": now_iso(),
        "tool": "agy",
        "session_id": sid,
        "cwd": cwd,
        "success": success,
        "ended_reason": reason,
        "final_status": payload.get("finalStatus") or payload.get("final_status"),
        "error_message": error or None,
        "duration_ms": transcript_data.get("duration_ms"),
        "is_background_agent": False,
        "models": models,
        "subagents": transcript_data.get("subagents") or [],
        "commands": transcript_data.get("commands") or [],
        "usage": None,
        "cost_usd_estimate": None,
        "transcript_path": str(transcript_path) if transcript_path else None,
        "workspace_roots": workspace_paths,
    }

    append_jsonl(LOG_FILE, record)


def main() -> int:
    try:
        raw = sys.stdin.read()
        payload = read_hook_payload(raw) if raw.strip() else {}
        if payload:
            handle_stop(payload)
        else:
            log_err(LOG_DIR, "empty stdin (hook fired with no payload)")
    except Exception as exc:  # noqa: BLE001
        log_err(LOG_DIR, str(exc))
    finally:
        # Stop hook expects a JSON response on stdout
        sys.stdout.write("{}\n")
        sys.stdout.flush()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
