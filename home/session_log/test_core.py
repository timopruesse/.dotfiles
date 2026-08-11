"""Tests for session_log core — kind classification + command stems."""

from __future__ import annotations

import sys
import tempfile
import unittest
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "home"))

from session_log import core  # noqa: E402


class SessionLogCoreTests(unittest.TestCase):
    def setUp(self) -> None:
        core.command_stems.cache_clear()
        core.pinned_agent_names.cache_clear()

    def test_command_stems_include_wrap_up(self) -> None:
        stems = core.command_stems()
        self.assertIn("wrap-up", stems)
        self.assertIn("dispatch", stems)
        self.assertIn("triage-security", stems)
        self.assertIn("session-cost", stems)
        self.assertNotIn("README", stems)

    def test_pinned_agents_include_scout(self) -> None:
        names = core.pinned_agent_names()
        self.assertIn("scout", names)
        self.assertIn("worker", names)
        self.assertIn("security-triage", names)
        self.assertNotIn("README", names)

    def test_classify_kind_three_way(self) -> None:
        self.assertEqual(core.classify_subagent_kind("Explore"), "builtin")
        self.assertEqual(core.classify_subagent_kind("general-purpose"), "builtin")
        self.assertEqual(core.classify_subagent_kind("scout"), "pinned")
        self.assertEqual(core.classify_subagent_kind("scoutt"), "unknown")
        self.assertIsNone(core.classify_subagent_kind(None))
        self.assertIsNone(core.classify_subagent_kind("untyped"))

    def test_merge_always_reclassifies_kind(self) -> None:
        primary = [
            {
                "type": "Explore",
                "description": "map",
                "kind": "pinned",  # lie from adapter
                "source": "subagents_dir",
            }
        ]
        merged = core.merge_subagent_lists(primary, [])
        self.assertEqual(merged[0]["kind"], "builtin")

    def test_extract_commands_finds_wrap_up(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "t.jsonl"
            path.write_text(
                '{"type":"user","message":{"role":"user","content":"please /wrap-up now"}}\n',
                encoding="utf-8",
            )
            cmds = core.extract_commands_from_transcript(path)
            self.assertEqual(cmds, ["wrap-up"])

    def test_rollup_and_routing_audit(self) -> None:
        records = [
            {
                "ts": "2026-08-11T12:00:00Z",
                "tool": "claude",
                "session_id": "c1",
                "cost_usd_estimate": 1.5,
                "duration_ms": 1000,
                "commands": ["land", "open-pr"],
                "subagents": [{"type": "scout", "kind": "pinned"}],
            },
            {
                "ts": "2026-08-11T13:00:00Z",
                "tool": "cursor",
                "session_id": "u1",
                "cost_usd_estimate": None,
                "duration_ms": 60000,
                "commands": ["my-work"],
                "subagents": [{"type": "Explore", "kind": None}],
            },
        ]
        rollup = core.rollup_sessions(records)
        self.assertEqual(rollup["by_tool"]["claude"]["sessions"], 1)
        self.assertEqual(rollup["by_tool"]["claude"]["cost_usd"], 1.5)
        self.assertEqual(rollup["by_tool"]["cursor"]["duration_ms"], 60000)
        self.assertIsNone(rollup["by_tool"]["cursor"]["cost_usd"])
        self.assertEqual(rollup["by_command"]["land"], 1)
        hits = core.routing_audit_hits(records)
        self.assertEqual(len(hits), 1)
        self.assertEqual(hits[0]["builtins"], ["Explore"])

    def test_load_session_records_filters_since(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "sessions.jsonl"
            path.write_text(
                '{"ts":"2026-08-01T00:00:00Z","tool":"claude","session_id":"old"}\n'
                '{"ts":"2026-08-11T12:00:00Z","tool":"claude","session_id":"new"}\n',
                encoding="utf-8",
            )
            since = datetime(2026, 8, 10, tzinfo=timezone.utc)
            rows = core.load_session_records([path], since=since)
            self.assertEqual(len(rows), 1)
            self.assertEqual(rows[0]["session_id"], "new")


if __name__ == "__main__":
    unittest.main()
