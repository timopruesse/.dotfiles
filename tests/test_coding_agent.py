"""Routing and CLI argument regressions; never start a real agent."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / 'home/.config/herdr/scripts'


class CodingAgentTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.env = {**os.environ, 'HOME': str(self.root), 'CODING_AGENT': ''}

    def resolve(self, directory, override=''):
        return subprocess.check_output(
            ['sh', str(SCRIPTS / 'coding_agent_resolve.sh'), str(directory)],
            env={**self.env, 'CODING_AGENT': override}, text=True,
        ).strip()

    def test_routing_and_overrides(self):
        work = self.root / 'github/chewielabs/project'
        work.mkdir(parents=True)
        self.assertEqual(self.resolve(work), 'claude')
        self.assertEqual(self.resolve(self.root), 'codex')
        for override in ('claude', 'codex', 'agy', 'agent', 'cursor'):
            self.assertEqual(self.resolve(work, override), 'agent' if override == 'cursor' else override)
        subprocess.run(['git', 'init', '-q', str(work)], check=True)
        subprocess.run(['git', '-C', str(work), 'remote', 'add', 'origin',
                        'git@github.com:timopruesse/project.git'], check=True)
        self.assertEqual(self.resolve(work), 'codex')
        subprocess.run(['git', '-C', str(work), 'remote', 'set-url', 'origin',
                        'https://github.com/chewielabs/project.git'], check=True)
        self.assertEqual(self.resolve(work), 'claude')

    def test_launch_arguments(self):
        for name in ('coding_agent_launch.sh', 'coding_agent_resolve.sh', 'coding_agent_ensure.sh'):
            shutil.copy(SCRIPTS / name, self.root)
        for cli in ('codex', 'claude', 'agent', 'agy'):
            binary = self.root / cli
            binary.write_text('#!/bin/sh\nprintf "%s\\0" "${0##*/}" "$@"\n')
            binary.chmod(0o755)
        env = {**self.env, 'PATH': str(self.root) + ':' + os.environ['PATH']}
        cases = [
            (['--resolved', 'codex', '--', 'fix this'], ['codex', '--', 'fix this']),
            (['resume', '--resolved', 'codex'], ['codex', 'resume']),
            (['continue', '--resolved', 'codex'], ['codex', 'resume', '--last']),
            (['--print', '--resolved', 'codex', '--', '--claude'], ['codex', 'exec', '--', '--claude']),
            (['--resolved', 'claude', '--codex'], ['codex']),
            (['resume', '--resolved', 'claude'], ['claude', '--resume']),
            (['continue', '--resolved', 'agent'], ['agent', '--continue']),
            (['resume', '--resolved', 'agy'], ['agy', '--continue']),
            (['--print', '--resolved', 'agent', '--', 'fix this'], ['agent', '-p', '--', 'fix this']),
        ]
        for args, expected in cases:
            with self.subTest(args=args):
                result = subprocess.check_output(
                    ['zsh', str(self.root / 'coding_agent_launch.sh'), '--ensured', *args],
                    cwd=self.root, env=env,
                ).decode().rstrip('\0').split('\0')
                self.assertEqual(result, expected)


if __name__ == '__main__':
    unittest.main()
