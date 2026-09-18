"""Regression coverage for Codex's single-response SessionStart protocol."""

import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from sync.codex_hooks import repair_codex_hooks, repair_source


FIXTURE = '''import json
if __name__ == "__main__":
    print(json.dumps({"async": True, "asyncTimeout": 180000}), flush=True)
    try:
        outcome = main()
    except Exception:
        outcome = 3
    response = {"metrics": {"sdk_bootstrap": outcome}}
    if outcome == 6:
        response["hookSpecificOutput"] = {"hookEventName": "SessionStart", "additionalContext": "notice"}
    print(json.dumps(response), flush=True)
'''


class CodexHookTests(unittest.TestCase):
    def run_fixture(self, source, main):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exec(source, {"__name__": "__main__", "main": main})
        return output.getvalue()

    def test_original_output_reproduces_invalid_json(self):
        with self.assertRaises(json.JSONDecodeError):
            json.loads(self.run_fixture(FIXTURE, lambda: 0))

    def test_success_early_returns_and_error_preserve_metrics_and_context(self):
        for result in (0, 1, 2, 3, 5, 6):
            with self.subTest(result=result):
                response = json.loads(self.run_fixture(repair_source(FIXTURE), lambda: result))
                self.assertEqual(response["metrics"]["sdk_bootstrap"], result)
                if result == 6:
                    self.assertEqual(response["hookSpecificOutput"]["additionalContext"], "notice")
        def fail():
            raise OSError("fixture failure")
        self.assertEqual(json.loads(self.run_fixture(repair_source(FIXTURE), fail))["metrics"]["sdk_bootstrap"], 3)

    def test_only_codex_security_guidance_cache_is_patched_idempotently(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            target = root / "plugins/cache/claude-plugins-official/security-guidance/2.0.8/hooks/ensure_agent_sdk.py"
            target.parent.mkdir(parents=True)
            target.write_text(FIXTURE)
            untouched = root / "herdr-agent-state.sh"
            untouched.write_text("unchanged")
            self.assertEqual(repair_codex_hooks(root), 1)
            self.assertEqual(repair_codex_hooks(root), 0)
            self.assertEqual(untouched.read_text(), "unchanged")
            self.assertEqual(repair_source("unfamiliar code"), "unfamiliar code")


if __name__ == "__main__":
    unittest.main()
