"""Shared parse / link / prune helpers for agent + command sync."""

from __future__ import annotations

import json
import os
import re
from pathlib import Path
from typing import Any

FRONTMATTER_RE = re.compile(r"\A---\n(.*?)\n---\n(.*)\Z", re.DOTALL)

# Placeholder in shared sources → expanded per platform by adapters.
# Example in a command body: pass the strong pin ({{pin:strong}})
PIN_TOKEN_RE = re.compile(r"\{\{pin:(cheap|mid|strong)\}\}")


def repo_home() -> Path:
    """Return the repo's `home/` directory (parent of this package)."""
    return Path(__file__).resolve().parent.parent


def parse_model_map(path: Path) -> dict[str, dict[str, str]]:
    """Parse the small fixed-shape model-map.yaml without PyYAML."""
    tiers: dict[str, dict[str, str]] = {}
    current: str | None = None
    in_tiers = False
    for raw in path.read_text().splitlines():
        line = raw.split("#", 1)[0].rstrip()
        if not line.strip():
            continue
        if line.strip() == "tiers:":
            in_tiers = True
            continue
        if not in_tiers:
            continue
        tier_m = re.match(r"^  (\w+):\s*$", line)
        if tier_m:
            current = tier_m.group(1)
            tiers[current] = {}
            continue
        pin_m = re.match(r"^    (claude|cursor):\s+(\S+)\s*$", line)
        if pin_m and current:
            tiers[current][pin_m.group(1)] = pin_m.group(2)
            continue
        raise SystemExit(f"unrecognized line in {path}: {raw!r}")
    for name, pins in tiers.items():
        if set(pins) != {"claude", "cursor"}:
            raise SystemExit(f"tier {name!r} missing claude/cursor pins: {pins}")
    return tiers


def link_into(target: Path, link: Path, *, replace_file: bool = False) -> None:
    """Symlink `link` → `target`, replacing a prior symlink; refuse to clobber files.

    Uses a path relative to `link`'s parent so in-repo links stay portable across
    machines (e.g. macOS /Users/... vs WSL /home/...).
    """
    link.parent.mkdir(parents=True, exist_ok=True)
    rel = Path(os.path.relpath(target.resolve(), start=link.parent.resolve()))
    if link.is_symlink() or not link.exists():
        link.unlink(missing_ok=True)
        link.symlink_to(rel)
        return
    if replace_file and link.is_file() and not link.is_symlink():
        link.unlink()
        link.symlink_to(rel)
        return
    raise SystemExit(f"refusing to replace non-symlink {link} (would install {target})")


def deep_merge(base: dict[str, Any], overlay: dict[str, Any]) -> dict[str, Any]:
    """Merge overlay into base; nested dicts recurse, other values overwrite."""
    out = dict(base)
    for key, value in overlay.items():
        if isinstance(value, dict) and isinstance(out.get(key), dict):
            out[key] = deep_merge(out[key], value)
        else:
            out[key] = value
    return out


def prune_stale_md(out_dir: Path, keep: set[str], *, relative_to: Path | None = None) -> None:
    """Remove generated *.md whose stem is not in keep."""
    if not out_dir.is_dir():
        return
    for stale in out_dir.glob("*.md"):
        if stale.stem not in keep:
            stale.unlink()
            label = stale.relative_to(relative_to) if relative_to else stale
            print(f"  removed stale {label}")


def expand_pin_tokens(body: str, tiers: dict[str, dict[str, str]], platform: str) -> str:
    """Replace {{pin:tier}} with the concrete model slug for this platform.

    Claude escalate wording prefers `model: "<slug>"`; Cursor prefers
    `` `<slug>` or `auto` `` so rate-limit fallback stays visible.
    """

    def repl(m: re.Match[str]) -> str:
        tier = m.group(1)
        if tier not in tiers:
            raise SystemExit(f"unknown pin tier in token: {tier!r}")
        slug = tiers[tier][platform]
        if platform == "claude":
            return f'`model: "{slug}"`'
        return f"`{slug}` or `auto`"

    return PIN_TOKEN_RE.sub(repl, body)


def replace_marked_section(path: Path, begin: str, end: str, body: str) -> bool:
    """Replace content between HTML comment markers. Returns True if updated."""
    text = path.read_text()
    start = text.find(begin)
    stop = text.find(end)
    if start < 0 or stop < 0 or stop < start:
        return False
    start_end = start + len(begin)
    new = text[:start_end] + "\n" + body.rstrip() + "\n" + text[stop:]
    if new != text:
        path.write_text(new)
        return True
    return False


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n")
