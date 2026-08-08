"""Shared session JSONL append + error logging for Claude and Cursor hooks."""

from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from functools import lru_cache
from pathlib import Path
from typing import Any

# Builtin host explorers (not pinned agents under home/agents/).
BUILTIN_SUBAGENT_TYPES = frozenset(
    {
        "explore",
        "Explore",
        "generalPurpose",
        "general-purpose",
        "general_purpose",
        "Plan",
        "plan",
        "Bash",
        "bash",
    }
)

_HOME = Path(__file__).resolve().parent.parent
_COMMANDS_DIR = _HOME / "commands"
_AGENTS_DIR = _HOME / "agents"
_EXCLUDE_MD = frozenset({"README.md"})


def home_dir() -> Path:
    """Repo `home/` (parent of session_log)."""
    return _HOME


@lru_cache(maxsize=1)
def command_stems() -> frozenset[str]:
    """Slash-command stems from authored `home/commands/*.md` (runtime glob)."""
    if not _COMMANDS_DIR.is_dir():
        return frozenset()
    return frozenset(
        p.stem
        for p in _COMMANDS_DIR.glob("*.md")
        if p.name not in _EXCLUDE_MD and p.is_file()
    )


@lru_cache(maxsize=1)
def pinned_agent_names() -> frozenset[str]:
    """Pinned agent names from authored `home/agents/*.md` (runtime glob)."""
    if not _AGENTS_DIR.is_dir():
        return frozenset()
    return frozenset(
        p.stem
        for p in _AGENTS_DIR.glob("*.md")
        if p.name not in _EXCLUDE_MD and p.is_file()
    )


def _command_token_re(stems: frozenset[str]) -> re.Pattern[str] | None:
    if not stems:
        return None
    # Longer stems first so e.g. ship-digest wins over ship.
    alt = "|".join(re.escape(s) for s in sorted(stems, key=len, reverse=True))
    return re.compile(
        rf"(?:^|[\s`])/({alt})(?=$|[\s`\"'])",
        re.MULTILINE,
    )


def __getattr__(name: str) -> Any:
    """Lazy aliases for older imports (`KNOWN_COMMAND_STEMS`, `COMMAND_TOKEN_RE`)."""
    if name == "KNOWN_COMMAND_STEMS":
        return command_stems()
    if name == "COMMAND_TOKEN_RE":
        return _command_token_re(command_stems())
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")


def now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def log_err(log_dir: Path, msg: str, *, err_name: str = "sessions.errors.log") -> None:
    try:
        log_dir.mkdir(parents=True, exist_ok=True)
        with (log_dir / err_name).open("a", encoding="utf-8") as f:
            f.write(f"{now_iso()} {msg}\n")
    except OSError:
        pass


def append_jsonl(log_file: Path, record: dict[str, Any]) -> None:
    log_file.parent.mkdir(parents=True, exist_ok=True)
    with log_file.open("a", encoding="utf-8") as f:
        f.write(json.dumps(record, separators=(",", ":")) + "\n")


def read_hook_payload(raw: str) -> dict[str, Any]:
    if not raw.strip():
        return {}
    data = json.loads(raw)
    return data if isinstance(data, dict) else {}


def classify_subagent_kind(agent_type: str | None) -> str | None:
    """Derive kind from spawn type: pinned | builtin | unknown (never trust adapters)."""
    if not agent_type or agent_type == "untyped":
        return None
    builtin_lower = {x.lower() for x in BUILTIN_SUBAGENT_TYPES}
    if agent_type in BUILTIN_SUBAGENT_TYPES or agent_type.lower() in builtin_lower:
        return "builtin"
    if agent_type in pinned_agent_names():
        return "pinned"
    return "unknown"


def _iter_jsonl_objects(path: Path):
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return
    for line in text.splitlines():
        if not line.strip():
            continue
        try:
            yield json.loads(line)
        except json.JSONDecodeError:
            continue


def _tool_uses_from_entry(entry: dict[str, Any]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    msg = entry.get("message")
    content = None
    if isinstance(msg, dict):
        content = msg.get("content")
    elif isinstance(entry.get("content"), list):
        content = entry.get("content")
    if not isinstance(content, list):
        return out
    for block in content:
        if isinstance(block, dict) and block.get("type") == "tool_use":
            out.append(block)
        elif isinstance(block, dict) and block.get("name") and block.get("input") is not None:
            # Cursor sometimes omits type
            out.append(block)
    return out


def extract_spawns_from_transcript(
    path: Path,
    *,
    tool_names: frozenset[str],
    type_keys: tuple[str, ...] = ("subagent_type", "agent_type", "type"),
) -> list[dict[str, Any]]:
    """Parse parent transcript for Agent/Task tool_use spawns."""
    found: list[dict[str, Any]] = []
    seen: set[tuple[str | None, str | None]] = set()
    for entry in _iter_jsonl_objects(path) or []:
        if not isinstance(entry, dict):
            continue
        for block in _tool_uses_from_entry(entry):
            name = block.get("name")
            if name not in tool_names:
                continue
            inp = block.get("input") or {}
            if not isinstance(inp, dict):
                continue
            agent_type = None
            for key in type_keys:
                if inp.get(key):
                    agent_type = str(inp.get(key))
                    break
            description = inp.get("description") or inp.get("task")
            if isinstance(description, str):
                description = description.strip() or None
            else:
                description = None
            key = (agent_type, description)
            if key in seen:
                continue
            seen.add(key)
            found.append(
                {
                    "type": agent_type or "untyped",
                    "description": description,
                    "status": "completed",
                    "duration_ms": None,
                    "models": [],
                    "kind": classify_subagent_kind(agent_type),
                    "source": "transcript",
                }
            )
    return found


def extract_commands_from_transcript(path: Path) -> list[str]:
    """Detect slash-command stems mentioned in user-facing transcript lines."""
    stems = command_stems()
    token_re = _command_token_re(stems)
    if not token_re:
        return []
    found: list[str] = []
    seen: set[str] = set()
    for entry in _iter_jsonl_objects(path) or []:
        if not isinstance(entry, dict):
            continue
        texts: list[str] = []
        role = None
        msg = entry.get("message")
        if isinstance(msg, dict):
            role = msg.get("role") or entry.get("role")
            content = msg.get("content")
            if isinstance(content, str):
                texts.append(content)
            elif isinstance(content, list):
                for block in content:
                    if isinstance(block, dict) and block.get("type") == "text":
                        texts.append(str(block.get("text") or ""))
                    elif isinstance(block, str):
                        texts.append(block)
        elif entry.get("role") == "user" and isinstance(entry.get("content"), str):
            role = "user"
            texts.append(entry["content"])
        # Prefer user/system; also scan tool results that echo command bodies
        if role not in (None, "user", "system") and entry.get("type") not in (
            "user",
            "system",
            "prompt",
        ):
            continue
        for text in texts:
            for m in token_re.finditer(text):
                stem = m.group(1)
                if stem in stems and stem not in seen:
                    seen.add(stem)
                    found.append(stem)
    return found


def merge_subagent_lists(
    primary: list[dict[str, Any]], extra: list[dict[str, Any]]
) -> list[dict[str, Any]]:
    """Prefer primary (e.g. subagents/ folder) entries; append transcript-only.

    Always reclassifies `kind` from `type` — inbound kind is ignored.
    """
    out = []
    seen: set[tuple[str | None, str | None]] = set()
    for item in primary + extra:
        t = item.get("type")
        d = item.get("description")
        key = (t, d)
        if key in seen and t not in (None, "untyped"):
            continue
        if key in seen:
            continue
        seen.add(key)
        merged = dict(item)
        merged["kind"] = classify_subagent_kind(
            t if isinstance(t, str) and t != "untyped" else None
        )
        out.append(merged)
    return out
