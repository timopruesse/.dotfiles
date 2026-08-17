"""Keep herdr integration SessionStart hooks portable and deduped.

`herdr integration install claude|cursor` appends hook entries with absolute
paths on every run. Dotfiles already declares the same hooks with $HOME paths.
Because home/ and ~/.cursor/hooks.json symlink into this repo, those duplicates
land as uncommitted working-tree edits. Run after integration install.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

from sync.common import repo_home, write_text_if_changed

HERDR_AGENT_STATE = "herdr-agent-state.sh"

CANONICAL: dict[str, str] = {
    "claude": 'bash "$HOME/.claude/hooks/herdr-agent-state.sh" session',
    "cursor": 'bash "$HOME/.cursor/herdr-agent-state.sh" session',
}

HERDR_SESSION_CMD_RE = re.compile(
    r"herdr-agent-state\.sh['\"]?\s+session\b",
)


def is_herdr_session_command(command: str) -> bool:
    return bool(HERDR_SESSION_CMD_RE.search(command))


def normalize_claude_settings(data: dict[str, Any]) -> tuple[dict[str, Any], bool]:
    hooks = data.get("hooks")
    if not isinstance(hooks, dict):
        return data, False

    session_start = hooks.get("SessionStart")
    if not isinstance(session_start, list):
        return data, False

    changed = False
    had_herdr = False
    cleaned: list[Any] = []

    for block in session_start:
        if not isinstance(block, dict):
            cleaned.append(block)
            continue

        block_hooks = block.get("hooks")
        if not isinstance(block_hooks, list):
            cleaned.append(block)
            continue

        kept: list[Any] = []
        for hook in block_hooks:
            if not isinstance(hook, dict):
                kept.append(hook)
                continue
            command = hook.get("command")
            if isinstance(command, str) and is_herdr_session_command(command):
                had_herdr = True
                if command != CANONICAL["claude"]:
                    changed = True
                continue
            kept.append(hook)

        if kept != block_hooks:
            changed = True

        if kept:
            new_block = dict(block)
            new_block["hooks"] = kept
            cleaned.append(new_block)
        else:
            changed = True

    if not had_herdr:
        return data, changed

    canonical_hook = {
        "type": "command",
        "command": CANONICAL["claude"],
        "timeout": 10,
    }

    for block in cleaned:
        if isinstance(block, dict) and block.get("matcher") == "*":
            block_hooks = block.setdefault("hooks", [])
            if not isinstance(block_hooks, list):
                block_hooks = []
                block["hooks"] = block_hooks
            block_hooks.append(canonical_hook)
            hooks["SessionStart"] = cleaned
            return data, True

    cleaned.append({"matcher": "*", "hooks": [canonical_hook]})
    hooks["SessionStart"] = cleaned
    return data, True


def normalize_cursor_hooks(data: dict[str, Any]) -> tuple[dict[str, Any], bool]:
    hooks = data.get("hooks")
    if not isinstance(hooks, dict):
        return data, False

    session_start = hooks.get("sessionStart")
    if not isinstance(session_start, list):
        return data, False

    changed = False
    had_herdr = False
    cleaned: list[Any] = []

    for entry in session_start:
        if not isinstance(entry, dict):
            cleaned.append(entry)
            continue
        command = entry.get("command")
        if isinstance(command, str) and is_herdr_session_command(command):
            had_herdr = True
            if command != CANONICAL["cursor"]:
                changed = True
            continue
        cleaned.append(entry)

    if not had_herdr:
        return data, changed

    cleaned.append({"command": CANONICAL["cursor"]})
    hooks["sessionStart"] = cleaned
    return data, True


def normalize_file(path: Path, *, kind: str) -> bool:
    if not path.is_file():
        print(f"  skip missing {path}", file=sys.stderr)
        return False

    try:
        data = json.loads(path.read_text())
    except json.JSONDecodeError as exc:
        print(f"  skip invalid JSON {path}: {exc}", file=sys.stderr)
        return False

    if not isinstance(data, dict):
        print(f"  skip non-object JSON {path}", file=sys.stderr)
        return False

    if kind == "claude":
        normalized, changed = normalize_claude_settings(data)
    elif kind == "cursor":
        normalized, changed = normalize_cursor_hooks(data)
    else:
        raise ValueError(f"unknown kind: {kind}")

    if not changed:
        return False

    text = json.dumps(normalized, indent=2) + "\n"
    if write_text_if_changed(path, text):
        print(f"  normalized {path}")
        return True
    return False


def normalize_all(*, repo: Path | None = None) -> int:
    root = repo or repo_home()
    changed = 0
    if normalize_file(root / ".claude" / "settings.json", kind="claude"):
        changed += 1
    if normalize_file(root / ".cursor" / "hooks.json", kind="cursor"):
        changed += 1
    return changed


def main() -> int:
    count = normalize_all()
    if count:
        print(f"normalize-herdr-hooks: updated {count} file(s)")
    else:
        print("normalize-herdr-hooks: already canonical")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
