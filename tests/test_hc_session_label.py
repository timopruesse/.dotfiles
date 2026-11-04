"""The Claude Code SessionStart hook labels the hc terminal; it never fails or runs a real hc."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
HOOK = ROOT / 'home/.claude/hooks/hc-session-label.sh'


class HcSessionLabelTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name).resolve()
        self.calls = self.home / 'calls'
        bin_dir = self.home / '.local/bin'
        bin_dir.mkdir(parents=True)
        fake = bin_dir / 'hc'
        fake.write_text('#!/bin/sh\nfor a in "$@"; do printf "%s\\n" "$a"; done >> "$CALLS"\nprintf "%s" "$CALLS_EXIT_CODE"; exit "${HC_EXIT:-0}"\n')
        fake.chmod(0o755)
        self.env = {'HOME': str(self.home), 'PATH': f'{bin_dir}:/usr/bin:/bin', 'CALLS': str(self.calls),
                    'CALLS_EXIT_CODE': '', 'HC_TERMINAL_ID': 't7'}

    def run_hook(self, payload, **env):
        stdin = payload if isinstance(payload, str) else json.dumps(payload)
        result = subprocess.run(['sh', str(HOOK)], input=stdin, text=True, capture_output=True,
                                env={**self.env, **env})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, '')
        return self.calls.read_text().split('\n')[:-1] if self.calls.exists() else []

    def test_labels_the_terminal_with_session_and_transcript(self):
        calls = self.run_hook({'hook_event_name': 'SessionStart', 'source': 'startup', 'session_id': 'abc-123',
                               'transcript_path': '/h/.claude/projects/x/abc-123.jsonl'})
        self.assertEqual(calls, ['label', 't7', 'agent.kind=claude', 'agent.session=abc-123',
                                 'agent.transcript=/h/.claude/projects/x/abc-123.jsonl'])

    def test_falls_back_to_local_bin_when_hc_is_not_on_path(self):
        calls = self.run_hook({'hook_event_name': 'SessionStart', 'session_id': 's', 'transcript_path': '/t.jsonl'},
                              PATH='/usr/bin:/bin')
        self.assertEqual(calls[:2], ['label', 't7'])

    def test_skips_outside_hc_sub_agents_other_events_and_bad_input(self):
        payload = {'hook_event_name': 'SessionStart', 'session_id': 's', 'transcript_path': '/t.jsonl'}
        self.assertEqual(self.run_hook(payload, HC_TERMINAL_ID=''), [])
        self.assertEqual(self.run_hook({**payload, 'agent_id': 'sub'}), [])
        self.assertEqual(self.run_hook({**payload, 'hook_event_name': 'Stop'}), [])
        self.assertEqual(self.run_hook({**payload, 'transcript_path': ''}), [])
        self.assertEqual(self.run_hook({**payload, 'session_id': 'a\nb'}), [])
        self.assertEqual(self.run_hook('not json'), [])
        self.assertEqual(self.run_hook(''), [])

    def test_hc_failure_does_not_fail_the_hook(self):
        calls = self.run_hook({'hook_event_name': 'SessionStart', 'session_id': 's', 'transcript_path': '/t.jsonl'}, HC_EXIT='3')
        self.assertEqual(calls[:2], ['label', 't7'])


if __name__ == '__main__':
    unittest.main()
