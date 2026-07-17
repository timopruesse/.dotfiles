#!/usr/bin/env python3
"""Cursor session cost/debug logger (CLI + IDE).

Hooks (via hooks.json):
  sessionStart  — create scratch state
  subagentStop  — append subagent summary to scratch
  sessionEnd    — flush one JSONL line to ~/.cursor/logs/sessions.jsonl

Always exits 0. Cursor does not expose USD/token billing in hooks; cost_usd_estimate
is null.
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

LOG_DIR = Path.home() / ".cursor" / "logs"
SCRATCH_DIR = LOG_DIR / "scratch"
LOG_FILE = LOG_DIR / "sessions.jsonl"
ERR_FILE = LOG_DIR / "sessions.errors.log"


def now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def log_err(msg: str) -> None:
    try:
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        with ERR_FILE.open("a", encoding="utf-8") as f:
            f.write(f"{now_iso()} {msg}\n")
    except OSError:
        pass


def session_key(payload: dict[str, Any]) -> str:
    return (
        payload.get("session_id")
        or payload.get("conversation_id")
        or "unknown"
    )


def scratch_path(sid: str) -> Path:
    safe = "".join(c if c.isalnum() or c in "-_" else "_" for c in sid)
    return SCRATCH_DIR / f"{safe}.json"


def read_scratch(sid: str) -> dict[str, Any]:
    path = scratch_path(sid)
    if not path.is_file():
        return {
            "session_id": sid,
            "started_at": None,
            "models": [],
            "workspace_roots": [],
            "subagents": [],
            "cwd": None,
            "transcript_path": None,
        }
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return data if isinstance(data, dict) else {}
    except (OSError, json.JSONDecodeError):
        return {"session_id": sid, "subagents": [], "models": []}


def write_scratch(sid: str, data: dict[str, Any]) -> None:
    SCRATCH_DIR.mkdir(parents=True, exist_ok=True)
    scratch_path(sid).write_text(
        json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )


def append_model(state: dict[str, Any], model: str | None) -> None:
    if not model:
        return
    models = state.setdefault("models", [])
    if model not in models:
        models.append(model)


def handle_session_start(payload: dict[str, Any]) -> None:
    sid = session_key(payload)
    state = {
        "session_id": sid,
        "started_at": now_iso(),
        "models": [],
        "workspace_roots": payload.get("workspace_roots") or [],
        "subagents": [],
        "cwd": None,
        "transcript_path": payload.get("transcript_path"),
        "is_background_agent": payload.get("is_background_agent"),
        "composer_mode": payload.get("composer_mode"),
    }
    append_model(state, payload.get("model") or payload.get("model_id"))
    roots = state["workspace_roots"]
    if isinstance(roots, list) and roots:
        state["cwd"] = roots[0]
    write_scratch(sid, state)


def handle_subagent_stop(payload: dict[str, Any]) -> None:
    sid = (
        payload.get("parent_conversation_id")
        or payload.get("session_id")
        or payload.get("conversation_id")
        or "unknown"
    )
    state = read_scratch(sid)
    state.setdefault("subagents", []).append(
        {
            "type": payload.get("subagent_type") or payload.get("subagent_id"),
            "status": payload.get("status"),
            "duration_ms": payload.get("duration_ms"),
            "description": payload.get("description") or payload.get("task"),
            "models": (
                [payload.get("subagent_model")]
                if payload.get("subagent_model")
                else []
            ),
            "tool_call_count": payload.get("tool_call_count"),
            "message_count": payload.get("message_count"),
        }
    )
    append_model(state, payload.get("subagent_model"))
    append_model(state, payload.get("model") or payload.get("model_id"))
    write_scratch(sid, state)


def handle_session_end(payload: dict[str, Any]) -> None:
    sid = session_key(payload)
    state = read_scratch(sid)
    append_model(state, payload.get("model") or payload.get("model_id"))

    reason = payload.get("reason") or "unknown"
    success = reason == "completed"

    record = {
        "ts": now_iso(),
        "tool": "cursor",
        "session_id": sid,
        "cwd": state.get("cwd")
        or (
            (payload.get("workspace_roots") or [None])[0]
            if isinstance(payload.get("workspace_roots"), list)
            else None
        ),
        "success": success,
        "ended_reason": reason,
        "final_status": payload.get("final_status"),
        "error_message": payload.get("error_message"),
        "duration_ms": payload.get("duration_ms"),
        "is_background_agent": payload.get("is_background_agent", state.get("is_background_agent")),
        "models": state.get("models") or [],
        "subagents": state.get("subagents") or [],
        "usage": None,
        "cost_usd_estimate": None,
        "transcript_path": payload.get("transcript_path") or state.get("transcript_path"),
        "workspace_roots": state.get("workspace_roots") or payload.get("workspace_roots"),
    }

    LOG_DIR.mkdir(parents=True, exist_ok=True)
    with LOG_FILE.open("a", encoding="utf-8") as f:
        f.write(json.dumps(record, separators=(",", ":")) + "\n")

    try:
        scratch_path(sid).unlink(missing_ok=True)
    except OSError:
        pass


def main() -> int:
    try:
        raw = sys.stdin.read()
        payload = json.loads(raw) if raw.strip() else {}
        if not isinstance(payload, dict):
            return 0
        event = (
            payload.get("hook_event_name")
            or payload.get("event")
            or ""
        ).strip()
        # Cursor may pass camelCase event names.
        key = event.replace("-", "").lower()
        if key in ("sessionstart",):
            handle_session_start(payload)
        elif key in ("subagentstop",):
            handle_subagent_stop(payload)
        elif key in ("sessionend",):
            handle_session_end(payload)
        else:
            # Unknown / missing — if it looks like an end payload, flush.
            if "duration_ms" in payload and "reason" in payload:
                handle_session_end(payload)
            elif payload.get("subagent_type") or payload.get("status") in (
                "completed",
                "error",
                "aborted",
            ):
                handle_subagent_stop(payload)
            else:
                handle_session_start(payload)
    except Exception as exc:  # noqa: BLE001
        log_err(str(exc))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
