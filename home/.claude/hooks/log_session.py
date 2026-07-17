#!/usr/bin/env python3
"""Claude Code SessionEnd logger — append one JSONL record per session.

Reads hook JSON from stdin, parses the transcript for token usage / subagents,
estimates USD from a local pricing table, and appends to
~/.claude/logs/sessions.jsonl. Always exits 0.
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

LOG_DIR = Path.home() / ".claude" / "logs"
LOG_FILE = LOG_DIR / "sessions.jsonl"

# USD per million tokens. Approximate API list prices (Jul 2026); estimates only.
# Matched by substring against message.model (first hit wins).
# cache_write_5m / cache_write_1h / cache_read are prompt-caching rates.
PRICING: list[tuple[str, dict[str, float]]] = [
    (
        "opus",
        {
            "input": 5.0,
            "output": 25.0,
            "cache_write_5m": 6.25,
            "cache_write_1h": 10.0,
            "cache_read": 0.50,
        },
    ),
    (
        "sonnet",
        {
            "input": 3.0,
            "output": 15.0,
            "cache_write_5m": 3.75,
            "cache_write_1h": 6.0,
            "cache_read": 0.30,
        },
    ),
    (
        "haiku",
        {
            "input": 1.0,
            "output": 5.0,
            "cache_write_5m": 1.25,
            "cache_write_1h": 2.0,
            "cache_read": 0.10,
        },
    ),
]

NORMAL_REASONS = frozenset(
    {"other", "prompt_input_exit", "clear", "resume", "logout"}
)


def empty_usage() -> dict[str, int]:
    return {
        "input_tokens": 0,
        "output_tokens": 0,
        "cache_creation_input_tokens": 0,
        "cache_creation_5m_tokens": 0,
        "cache_creation_1h_tokens": 0,
        "cache_read_input_tokens": 0,
    }


def add_usage(dst: dict[str, int], src: dict[str, Any]) -> None:
    dst["input_tokens"] += int(src.get("input_tokens") or 0)
    dst["output_tokens"] += int(src.get("output_tokens") or 0)
    dst["cache_creation_input_tokens"] += int(
        src.get("cache_creation_input_tokens") or 0
    )
    dst["cache_read_input_tokens"] += int(src.get("cache_read_input_tokens") or 0)
    cc = src.get("cache_creation") or {}
    if isinstance(cc, dict):
        dst["cache_creation_5m_tokens"] += int(cc.get("ephemeral_5m_input_tokens") or 0)
        dst["cache_creation_1h_tokens"] += int(cc.get("ephemeral_1h_input_tokens") or 0)


def price_for(model: str | None) -> dict[str, float] | None:
    if not model:
        return None
    low = model.lower().strip()
    if not low or low.startswith("<") or low == "synthetic":
        return None
    for needle, rates in PRICING:
        if needle in low:
            return rates
    return None


def estimate_cost(model: str | None, usage: dict[str, int]) -> tuple[float | None, bool]:
    """Return (cost, incomplete). incomplete=True only for real unknown models with usage."""
    rates = price_for(model)
    tokens = (
        usage["input_tokens"]
        + usage["output_tokens"]
        + usage["cache_creation_input_tokens"]
        + usage["cache_read_input_tokens"]
    )
    if rates is None:
        # Ignore zero-usage / synthetic placeholders.
        if not model or model.startswith("<") or tokens == 0:
            return None, False
        return None, True
    m = 1_000_000.0
    cost = 0.0
    cost += usage["input_tokens"] * rates["input"] / m
    cost += usage["output_tokens"] * rates["output"] / m
    cost += usage["cache_read_input_tokens"] * rates["cache_read"] / m

    w5 = usage["cache_creation_5m_tokens"]
    w1 = usage["cache_creation_1h_tokens"]
    if w5 or w1:
        cost += w5 * rates["cache_write_5m"] / m
        cost += w1 * rates["cache_write_1h"] / m
    else:
        # Fallback when breakdown is absent: treat all cache writes as 5m.
        cost += usage["cache_creation_input_tokens"] * rates["cache_write_5m"] / m
    return round(cost, 6), False


def is_real_model(model: str | None) -> bool:
    if not model:
        return False
    low = model.lower().strip()
    return bool(low) and not low.startswith("<") and low != "synthetic"


def parse_ts(raw: str | None) -> datetime | None:
    if not raw:
        return None
    try:
        return datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        return None


def collect_api_calls(
    path: Path, *, skip_sidechain: bool = True
) -> tuple[list[dict[str, Any]], datetime | None, datetime | None]:
    """Dedupe assistant usage by requestId; keep max output_tokens per call."""
    by_req: dict[str, dict[str, Any]] = {}
    orphan_list: list[dict[str, Any]] = []
    first_ts: datetime | None = None
    last_ts: datetime | None = None

    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return [], None, None

    for line in text.splitlines():
        if not line.strip():
            continue
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue

        ts = parse_ts(entry.get("timestamp"))
        if ts is not None:
            if first_ts is None or ts < first_ts:
                first_ts = ts
            if last_ts is None or ts > last_ts:
                last_ts = ts

        if entry.get("type") != "assistant":
            continue
        if skip_sidechain and entry.get("isSidechain"):
            continue
        msg = entry.get("message") or {}
        usage = msg.get("usage")
        if not isinstance(usage, dict):
            continue
        model = msg.get("model")
        req = entry.get("requestId") or msg.get("id")
        rec = {
            "model": model,
            "usage": usage,
            "output_tokens": int(usage.get("output_tokens") or 0),
        }
        if not req:
            orphan_list.append(rec)
            continue
        prev = by_req.get(req)
        if prev is None or rec["output_tokens"] >= prev["output_tokens"]:
            by_req[req] = rec

    return list(by_req.values()) + orphan_list, first_ts, last_ts


def summarize_calls(
    calls: list[dict[str, Any]],
) -> tuple[dict[str, int], list[str], float | None, bool]:
    usage = empty_usage()
    by_model: dict[str, dict[str, int]] = {}
    incomplete = False
    total_cost = 0.0
    any_cost = False

    for call in calls:
        model = call.get("model") or "unknown"
        u = empty_usage()
        add_usage(u, call.get("usage") or {})
        add_usage(usage, call.get("usage") or {})
        if is_real_model(model):
            bucket = by_model.setdefault(model, empty_usage())
            add_usage(bucket, call.get("usage") or {})
        cost, miss = estimate_cost(model if model != "unknown" else None, u)
        if miss:
            incomplete = True
        elif cost is not None:
            total_cost += cost
            any_cost = True

    models = sorted(by_model.keys())
    return usage, models, (round(total_cost, 6) if any_cost else None), incomplete


def load_subagents(transcript_path: Path, session_id: str) -> list[dict[str, Any]]:
    """Scan sibling subagents/ dir for agent types + per-agent usage."""
    # Layout: .../<sessionId>.jsonl  and  .../<sessionId>/subagents/*.jsonl
    parent = transcript_path.parent
    candidates = [
        parent / session_id / "subagents",
        parent / transcript_path.stem / "subagents",
    ]
    sub_dir = next((p for p in candidates if p.is_dir()), None)
    if sub_dir is None:
        return []

    out: list[dict[str, Any]] = []
    for jsonl in sorted(sub_dir.glob("*.jsonl")):
        meta_path = jsonl.with_suffix(".meta.json")
        agent_type = None
        description = None
        if meta_path.is_file():
            try:
                meta = json.loads(meta_path.read_text(encoding="utf-8"))
                agent_type = meta.get("agentType")
                description = meta.get("description")
            except (OSError, json.JSONDecodeError):
                pass
        if not agent_type:
            # Fallback: agent-a<label>-<hash>.jsonl
            name = jsonl.stem
            agent_type = name.removeprefix("agent-")

        calls, first_ts, last_ts = collect_api_calls(jsonl, skip_sidechain=False)
        usage, models, cost, incomplete = summarize_calls(calls)
        duration_ms = None
        if first_ts and last_ts:
            duration_ms = int((last_ts - first_ts).total_seconds() * 1000)

        out.append(
            {
                "type": agent_type,
                "description": description,
                "status": "completed",
                "duration_ms": duration_ms,
                "models": models,
                "usage": {
                    k: usage[k]
                    for k in (
                        "input_tokens",
                        "output_tokens",
                        "cache_creation_input_tokens",
                        "cache_read_input_tokens",
                    )
                },
                "cost_usd_estimate": cost,
                "cost_estimate_incomplete": incomplete or None,
            }
        )
    return out


def build_record(payload: dict[str, Any]) -> dict[str, Any]:
    session_id = payload.get("session_id") or ""
    transcript_path_raw = payload.get("transcript_path") or ""
    cwd = payload.get("cwd") or ""
    reason = payload.get("reason") or "other"

    transcript = Path(transcript_path_raw).expanduser() if transcript_path_raw else None
    main_calls: list[dict[str, Any]] = []
    first_ts: datetime | None = None
    last_ts: datetime | None = None
    if transcript and transcript.is_file():
        main_calls, first_ts, last_ts = collect_api_calls(transcript)

    usage, models, main_cost, incomplete = summarize_calls(main_calls)
    subagents = load_subagents(transcript, session_id) if transcript else []

    # Roll subagent usage + cost into session totals (matches /cost including agents).
    for sub in subagents:
        for k in (
            "input_tokens",
            "output_tokens",
            "cache_creation_input_tokens",
            "cache_read_input_tokens",
        ):
            usage[k] += int((sub.get("usage") or {}).get(k) or 0)
        for m in sub.get("models") or []:
            if m not in models:
                models.append(m)
        if sub.get("cost_estimate_incomplete"):
            incomplete = True
        sc = sub.get("cost_usd_estimate")
        if sc is not None:
            main_cost = (main_cost or 0.0) + float(sc)

    if main_cost is not None:
        main_cost = round(main_cost, 6)

    duration_ms = None
    if first_ts and last_ts:
        duration_ms = int((last_ts - first_ts).total_seconds() * 1000)

    public_usage = {
        "input_tokens": usage["input_tokens"],
        "output_tokens": usage["output_tokens"],
        "cache_creation_input_tokens": usage["cache_creation_input_tokens"],
        "cache_read_input_tokens": usage["cache_read_input_tokens"],
    }

    return {
        "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "tool": "claude",
        "session_id": session_id,
        "cwd": cwd,
        "success": reason in NORMAL_REASONS,
        "ended_reason": reason,
        "duration_ms": duration_ms,
        "models": models,
        "subagents": [
            {
                "type": s.get("type"),
                "description": s.get("description"),
                "status": s.get("status"),
                "duration_ms": s.get("duration_ms"),
                "models": s.get("models"),
            }
            for s in subagents
        ],
        "usage": public_usage,
        "cost_usd_estimate": main_cost,
        "cost_estimate_incomplete": incomplete or None,
        "transcript_path": transcript_path_raw or None,
    }


def main() -> int:
    try:
        raw = sys.stdin.read()
        payload = json.loads(raw) if raw.strip() else {}
        if not isinstance(payload, dict):
            payload = {}
        record = build_record(payload)
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        with LOG_FILE.open("a", encoding="utf-8") as f:
            f.write(json.dumps(record, separators=(",", ":")) + "\n")
    except Exception as exc:  # noqa: BLE001 — never fail the session
        try:
            LOG_DIR.mkdir(parents=True, exist_ok=True)
            with (LOG_DIR / "sessions.errors.log").open("a", encoding="utf-8") as f:
                f.write(f"{datetime.now(timezone.utc).isoformat()} {exc}\n")
        except OSError:
            pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
