"""Native Codex role schema, preservation, and safe installation regression tests."""

import sys
import tempfile
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "home"))

from sync.agents import CODEX_LEAF, render_codex_agent, split_agent
from sync.common import parse_model_map
from sync.live_codex import install_codex_agents


class CodexAgentTests(unittest.TestCase):
    def test_all_roles_roundtrip_with_pins_and_leaf_guard(self):
        tiers = parse_model_map(ROOT / "home/agents/model-map.yaml")
        expected = {
            "cheap": ("gpt-5.6-luna", "medium"),
            "mid": ("gpt-5.6-terra", "medium"),
            "strong": ("gpt-6-astra", "high"),
        }
        sources = sorted((ROOT / "home/agents").glob("*.md"))
        sources = [p for p in sources if p.name != "README.md"]
        self.assertEqual(len(sources), 12)
        for path in sources:
            with self.subTest(role=path.stem):
                fields, body = split_agent(path)
                result = tomllib.loads(render_codex_agent(fields, body, tiers[fields["tier"]]))
                self.assertRegex(body, r"(?:ADVANCE →|HALT:|VERDICT:|STATUS:)")
                self.assertEqual(result["name"], fields["name"])
                self.assertEqual(result["description"], " ".join(fields["description"].split()))
                self.assertEqual(result["developer_instructions"], CODEX_LEAF + body)
                self.assertEqual((result["model"], result["model_reasoning_effort"]), expected[fields["tier"]])
                self.assertEqual(result["agents"], {"enabled": False})
                self.assertEqual(result.get("sandbox_mode"), "read-only" if fields.get("readonly") == "true" else None)
                self.assertNotIn("disallowedTools", result)
                self.assertNotIn("tier", result)
                self.assertEqual(tomllib.loads((ROOT / f"home/.codex/agents/{path.stem}.toml").read_text()), result)

    def test_toml_escaping_preserves_role_text(self):
        body = '\n"""triple quotes""" \\ backslash\t Unicode →\n\b\f\r\x01'
        fields = {"name": "example", "description": 'a "quote"', "readonly": "true"}
        result = tomllib.loads(render_codex_agent(fields, body, {"codex": "model", "codex_reasoning_effort": "high"}))
        self.assertEqual(result["developer_instructions"], CODEX_LEAF + body)

    def test_install_preserves_unrelated_files_config_and_links(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source, live = root / "source", root / "codex/agents"
            source.mkdir()
            live.mkdir(parents=True)
            (source / "worker.toml").write_text("managed")
            (live.parent / "config.toml").write_text('model = "personal-model"')
            (live / "personal.toml").write_text("personal")
            (root / "external.toml").write_text("external")
            (live / "external.toml").symlink_to(root / "external.toml")
            (live / "stale.toml").symlink_to(source / "stale.toml")
            install_codex_agents(source, live)
            install_codex_agents(source, live)
            self.assertEqual((live / "worker.toml").resolve(), (source / "worker.toml").resolve())
            self.assertEqual((live / "personal.toml").read_text(), "personal")
            self.assertTrue((live / "external.toml").is_symlink())
            self.assertFalse((live / "stale.toml").is_symlink())
            self.assertEqual((live.parent / "config.toml").read_text(), 'model = "personal-model"')

    def test_install_refuses_unmanaged_collisions_before_any_changes(self):
        for kind in ("file", "link"):
            with self.subTest(kind=kind), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                source, live = root / "source", root / "live"
                source.mkdir()
                live.mkdir()
                (source / "a.toml").write_text("managed")
                (source / "z.toml").write_text("managed")
                external = root / "external.toml"
                external.write_text("personal")
                if kind == "link":
                    (live / "z.toml").symlink_to(external)
                else:
                    (live / "z.toml").write_text("personal")
                with self.assertRaises(SystemExit):
                    install_codex_agents(source, live)
                self.assertFalse((live / "a.toml").exists())
                self.assertEqual((live / "z.toml").read_text(), "personal")


if __name__ == "__main__":
    unittest.main()
