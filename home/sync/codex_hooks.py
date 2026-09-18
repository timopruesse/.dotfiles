"""Repair a Claude-only async handshake in Codex's security-guidance cache.

Codex expects one SessionStart JSON response. Plugin 2.0.8 prints an async
handshake followed by the response, which fails with "invalid session start
JSON output". Keep the bootstrap, metrics, and context; remove only that
handshake in Codex's private cache. Reapply after plugin updates via sync.
"""

from __future__ import annotations

import sys
from pathlib import Path

HANDSHAKE = '    print(json.dumps({"async": True, "asyncTimeout": 180000}), flush=True)'
REPLACEMENT = '    # Dotfiles: Codex consumes one JSON response; omit the Claude async handshake.'


def repair_source(source: str) -> str:
    """Match the known bug narrowly; never rewrite unfamiliar plugin code."""
    if source.count(HANDSHAKE) != 1:
        return source
    if '    print(json.dumps(response), flush=True)' not in source:
        return source
    return source.replace(HANDSHAKE, REPLACEMENT, 1)


def repair_codex_hooks(codex_home: Path | None = None) -> int:
    root = codex_home or Path.home() / ".codex"
    count = 0
    for path in sorted(root.glob(
        "plugins/cache/claude-plugins-official/security-guidance/*/hooks/ensure_agent_sdk.py"
    )):
        original = path.read_text(encoding="utf-8")
        repaired = repair_source(original)
        if repaired != original:
            backup = path.with_suffix(".py.before-codex-json-fix")
            if not backup.exists():
                backup.write_text(original, encoding="utf-8")
            path.write_text(repaired, encoding="utf-8")
            print(f"  repaired Codex SessionStart JSON → {path}")
            count += 1
    return count


if __name__ == "__main__":
    repair_codex_hooks(Path(sys.argv[1]) if len(sys.argv) > 1 else None)
