"""Tests for session_log core — kind classification + command stems."""

from __future__ import annotations

import sys
import tempfile
import unittest
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
        self.assertNotIn("README", stems)

    def test_pinned_agents_include_scout(self) -> None:
        names = core.pinned_agent_names()
        self.assertIn("scout", names)
        self.assertIn("worker", names)
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


if __name__ == "__main__":
    unittest.main()
