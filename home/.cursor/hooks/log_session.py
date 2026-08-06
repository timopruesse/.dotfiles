#!/usr/bin/env python3
"""Cursor session cost/debug logger (CLI + IDE).

Hooks (via hooks.json):
  sessionStart  — create scratch state
  subagentStop  — append subagent summary to scratch
  sessionEnd    — flush one JSONL line to ~/.cursor/logs/sessions.jsonl

Always exits 0. Cursor does not expose USD/token billing in hooks; cost_usd_estimate
is null. On sessionEnd, also parses the transcript for Task spawns + slash commands
when scratch subagents are empty or incomplete.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

# home/session_log — hooks live at home/.cursor/hooks/
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from session_log.core import (  # noqa: E402
    append_jsonl,
    classify_subagent_kind,
    extract_commands_from_transcript,
    extract_spawns_from_transcript,
    log_err,
    merge_subagent_lists,
    now_iso,
    read_hook_payload,
)

LOG_DIR = Path.home() / ".cursor" / "logs"
SCRATCH_DIR = LOG_DIR / "scratch"
LOG_FILE = LOG_DIR / "sessions.jsonl"


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
            "commands": [],
        }
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return data if isinstance(data, dict) else {}
    except (OSError, json.JSONDecodeError):
        return {"session_id": sid, "subagents": [], "models": [], "commands": []}


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
        "commands": [],
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
    agent_type = payload.get("subagent_type") or payload.get("subagent_id")
    state.setdefault("subagents", []).append(
        {
            "type": agent_type,
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
            "kind": classify_subagent_kind(
                str(agent_type) if agent_type else None
            ),
            "source": "hook",
        }
    )
    append_model(state, payload.get("subagent_model"))
    append_model(state, payload.get("model") or payload.get("model_id"))
    write_scratch(sid, state)


def _enrich_from_transcript(
    state: dict[str, Any], transcript_raw: str | None
) -> None:
    if not transcript_raw:
        return
    path = Path(transcript_raw).expanduser()
    if not path.is_file():
        return
    transcript_subs = extract_spawns_from_transcript(
        path, tool_names=frozenset({"Task", "Agent", "task", "agent"})
    )
    state["subagents"] = merge_subagent_lists(
        list(state.get("subagents") or []), transcript_subs
    )
    cmds = extract_commands_from_transcript(path)
    existing = list(state.get("commands") or [])
    for c in cmds:
        if c not in existing:
            existing.append(c)
    state["commands"] = existing


def handle_session_end(payload: dict[str, Any]) -> None:
    sid = session_key(payload)
    state = read_scratch(sid)
    append_model(state, payload.get("model") or payload.get("model_id"))

    transcript = payload.get("transcript_path") or state.get("transcript_path")
    _enrich_from_transcript(state, transcript)

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
        "is_background_agent": payload.get(
            "is_background_agent", state.get("is_background_agent")
        ),
        "models": state.get("models") or [],
        "subagents": state.get("subagents") or [],
        "commands": state.get("commands") or [],
        "usage": None,
        "cost_usd_estimate": None,
        "transcript_path": transcript,
        "workspace_roots": state.get("workspace_roots") or payload.get("workspace_roots"),
    }

    append_jsonl(LOG_FILE, record)

    try:
        scratch_path(sid).unlink(missing_ok=True)
    except OSError:
        pass


def main() -> int:
    try:
        raw = sys.stdin.read()
        if not raw.strip():
            log_err(LOG_DIR, "empty stdin (hook fired with no payload)")
            return 0
        payload = read_hook_payload(raw)
        event = (
            payload.get("hook_event_name")
            or payload.get("event")
            or payload.get("hook_event")
            or ""
        ).strip()
        key = event.replace("-", "").replace("_", "").lower()
        if key in ("sessionstart",):
            handle_session_start(payload)
        elif key in ("subagentstop",):
            handle_subagent_stop(payload)
        elif key in ("sessionend",):
            handle_session_end(payload)
        else:
            # Heuristic fallback when Cursor omits hook_event_name
            if "duration_ms" in payload and (
                "reason" in payload or "final_status" in payload
            ):
                handle_session_end(payload)
            elif payload.get("subagent_type") or payload.get("status") in (
                "completed",
                "error",
                "aborted",
            ):
                handle_subagent_stop(payload)
            elif payload.get("session_id") or payload.get("conversation_id"):
                handle_session_start(payload)
            else:
                log_err(
                    LOG_DIR,
                    f"unrecognized hook payload keys={sorted(payload.keys())[:20]}",
                )
    except Exception as exc:  # noqa: BLE001
        log_err(LOG_DIR, str(exc))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
