#!/usr/bin/env python3
"""CLI: query session-log JSONL for spend / duration / routing audit.

Usage:
  session_cost.py [--since 24h|7d|yesterday|ISO] [--routing]
  session_cost.py --since 24h --routing

Claude rows use cost_usd_estimate; Cursor rows use duration_ms only (never fake USD).
"""

from __future__ import annotations

import argparse
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

# Allow `python3 ~/session_log/session_cost.py` when home is symlinked to ~.
_HERE = Path(__file__).resolve().parent
if str(_HERE.parent) not in sys.path:
    sys.path.insert(0, str(_HERE.parent))

from session_log import core  # noqa: E402


def _parse_since(raw: str) -> datetime:
    now = datetime.now(timezone.utc)
    s = raw.strip().lower()
    if s in ("yesterday",):
        return now - timedelta(days=1)
    if s.endswith("h") and s[:-1].isdigit():
        return now - timedelta(hours=int(s[:-1]))
    if s.endswith("d") and s[:-1].isdigit():
        return now - timedelta(days=int(s[:-1]))
    if s.endswith("w") and s[:-1].isdigit():
        return now - timedelta(weeks=int(s[:-1]))
    # ISO date or datetime
    try:
        dt = datetime.fromisoformat(s.replace("Z", "+00:00"))
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc)
    except ValueError as e:
        raise SystemExit(f"unrecognized --since value: {raw!r}") from e


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument(
        "--since",
        default="24h",
        help="Lookback window (24h, 7d, yesterday, or ISO). Default: 24h",
    )
    p.add_argument(
        "--routing",
        action="store_true",
        help="Highlight sessions with builtin explorer spawns",
    )
    args = p.parse_args(argv)

    since = _parse_since(args.since)
    until = datetime.now(timezone.utc)

    paths = [
        Path.home() / ".claude" / "logs" / "sessions.jsonl",
        Path.home() / ".cursor" / "logs" / "sessions.jsonl",
    ]

    missing = [str(x) for x in paths if not x.is_file()]
    records = core.load_session_records(paths, since=since, until=until)
    rollup = core.rollup_sessions(records)

    print(f"session-cost since {since.strftime('%Y-%m-%dT%H:%M:%SZ')} ({len(records)} sessions)")
    if missing:
        print(f"missing logs (ok if unused): {', '.join(missing)}")
    print()

    for tool, stats in sorted(rollup["by_tool"].items()):
        print(f"## {tool}")
        print(f"  sessions: {stats['sessions']}")
        if tool == "claude" or stats.get("cost_usd") is not None:
            cost = stats.get("cost_usd")
            if cost is not None:
                print(f"  cost_usd_estimate: ${cost:.4f}")
            else:
                print("  cost_usd_estimate: (none)")
        if tool == "cursor" or (tool != "claude" and stats.get("cost_usd") is None):
            dur = stats.get("duration_ms")
            if dur is not None:
                print(f"  duration_ms_total: {dur} ({dur / 1000 / 60:.1f} min)")
            else:
                print("  duration_ms_total: (none)")
        print()

    if rollup["by_command"]:
        print("## by command stem")
        for stem, n in sorted(rollup["by_command"].items(), key=lambda x: (-x[1], x[0])):
            print(f"  /{stem}: {n}")
        print()

    if args.routing:
        print("## routing audit (builtin explorer spawns)")
        hits = core.routing_audit_hits(records)
        if not hits:
            print("  (none)")
        else:
            for hit in hits:
                print(
                    f"  {hit['ts']} {hit['tool']} session={hit['session_id']} "
                    f"builtins={','.join(hit['builtins'])}"
                )
        print()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
