"""Codex instructions must not overwrite a user's independent configuration."""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from sync.codex_instructions import install_codex_instructions
from sync.catalog import render_agent_routing_body


class CodexInstructionsTests(unittest.TestCase):
    def test_generated_instructions_share_fallback_contract(self):
        root = Path(__file__).resolve().parents[2]
        generated = (root / 'home/.codex/AGENTS.md').read_text()
        from sync.catalog import load_agent_tiers
        contract = render_agent_routing_body(load_agent_tiers()).strip()
        self.assertIn(contract, generated)
        self.assertIn("continue in the parent within the user's existing authorization", generated)
        self.assertIn("Codex never uses Cursor's `auto` alias", generated)

    def test_install_and_repeat_preserve_managed_link(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "managed.md"
            source.write_text("managed")
            destination = root / "live" / "AGENTS.md"
            install_codex_instructions(source, destination)
            install_codex_instructions(source, destination)
            self.assertTrue(destination.is_symlink())
            self.assertEqual(destination.resolve(), source.resolve())

    def test_preserves_personal_file_and_foreign_link(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "managed.md"
            source.write_text("managed")
            personal = root / "personal.md"
            personal.write_text("personal")
            install_codex_instructions(source, personal)
            self.assertEqual(personal.read_text(), "personal")
            destination = root / "AGENTS.md"
            destination.symlink_to(personal)
            install_codex_instructions(source, destination)
            self.assertEqual(destination.resolve(), personal.resolve())


if __name__ == "__main__":
    unittest.main()
