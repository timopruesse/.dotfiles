"""Tests for sync frontmatter parse + catalog emit helpers."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "home"))

from sync.catalog import (  # noqa: E402
    pinned_agents_csv,
    render_cursor_mdc,
    render_workflows_agent_roster,
)
from sync.common import parse_frontmatter, parse_model_map  # noqa: E402
from sync.conveyor import main as conveyor_main  # noqa: E402


class FrontmatterTests(unittest.TestCase):
    def test_flat_command_style(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "cmd.md"
            path.write_text(
                "---\ntier: cheap\ndescription: hello\n---\n\nbody\n",
                encoding="utf-8",
            )
            fields, body = parse_frontmatter(path, require={"tier", "description"})
            self.assertEqual(fields["tier"], "cheap")
            self.assertEqual(fields["description"], "hello")
            self.assertIn("body", body)

    def test_multiline_agent_style(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "agent.md"
            path.write_text(
                "---\n"
                "name: scout\n"
                "tier: cheap\n"
                "description: >-\n"
                "  line one\n"
                "  line two\n"
                "---\n\nprompt\n",
                encoding="utf-8",
            )
            fields, body = parse_frontmatter(path, require={"tier", "name"})
            self.assertEqual(fields["name"], "scout")
            self.assertIn("line one", fields["description"])
            self.assertIn("prompt", body)

    def test_require_missing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "bad.md"
            path.write_text("---\nname: x\n---\n\n", encoding="utf-8")
            with self.assertRaises(SystemExit):
                parse_frontmatter(path, require={"tier"})


class CatalogHelperTests(unittest.TestCase):
    def test_model_map_parses(self) -> None:
        path = ROOT / "home" / "agents" / "model-map.yaml"
        tiers = parse_model_map(path)
        self.assertEqual(set(tiers), {"cheap", "mid", "strong"})
        self.assertIn("claude", tiers["cheap"])
        self.assertIn("cursor", tiers["cheap"])
        self.assertIn("agy", tiers["cheap"])

    def test_workflows_roster_rows(self) -> None:
        tiers = {
            "cheap": {"claude": "haiku", "cursor": "c1", "agy": "a1"},
            "mid": {"claude": "sonnet", "cursor": "c2", "agy": "a2"},
            "strong": {"claude": "opus", "cursor": "c3", "agy": "a3"},
        }
        agents = {"cheap": ["scout"], "mid": ["worker"], "strong": ["verifier"]}
        table = render_workflows_agent_roster(tiers, agents)
        self.assertIn("| `scout` | cheap | `haiku` | `c1` | `a1` |", table)
        self.assertIn("| `verifier` | strong | `opus` | `c3` | `a3` |", table)

    def test_model_fallback_tokens_expand(self) -> None:
        tiers = parse_model_map(ROOT / "home" / "agents" / "model-map.yaml")
        agents = {
            "cheap": ["scout"],
            "mid": ["worker"],
            "strong": ["verifier"],
        }
        mdc = render_cursor_mdc(tiers, agents)
        self.assertIn("`scout`", mdc)
        self.assertIn(tiers["strong"]["cursor"], mdc)
        self.assertNotIn("{{PINNED_AGENTS}}", mdc)
        self.assertNotIn("{{TIER_TABLE}}", mdc)
        self.assertNotIn("{{STRONG_CURSOR}}", mdc)
        self.assertEqual(pinned_agents_csv(agents), "`scout`, `worker`, `verifier`")

    def test_conveyor_rejects_args(self) -> None:
        self.assertEqual(conveyor_main(["--no-live"]), 2)


class LiveCursorTests(unittest.TestCase):
    def test_merge_json_file(self) -> None:
        import json
        from sync.live_cursor import _merge_json_file

        with tempfile.TemporaryDirectory() as tmp:
            managed = Path(tmp) / "managed.json"
            live = Path(tmp) / "live.json"

            managed.write_text(
                json.dumps({"mcpServers": {"svelte": {"url": "https://mcp.svelte.dev/mcp"}}})
            )
            # Case 1: live does not exist
            _merge_json_file(managed, live, "test")
            self.assertTrue(live.is_file())
            data = json.loads(live.read_text())
            self.assertIn("svelte", data["mcpServers"])

            # Case 2: live has local server, managed has svelte
            live.write_text(
                json.dumps({"mcpServers": {"custom": {"url": "http://localhost:8080"}}})
            )
            _merge_json_file(managed, live, "test")
            data = json.loads(live.read_text())
            self.assertIn("custom", data["mcpServers"])
            self.assertIn("svelte", data["mcpServers"])


if __name__ == "__main__":
    unittest.main()

