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
        self.env = {**os.environ, 'HOME': str(self.root), 'CODING_AGENT': '', 'DOTFILES': '', 'HERDR_ENV': '', 'HERDR_PANE_ID': ''}

    def resolve(self, directory, override=''):
        return subprocess.check_output(
            ['sh', str(SCRIPTS / 'coding_agent_resolve.sh'), str(directory)],
            env={**self.env, 'CODING_AGENT': override}, text=True,
        ).strip()

    def test_routing_and_overrides(self):
        work = self.root / 'github/chewielabs/project'
        work.mkdir(parents=True)
        self.assertEqual(self.resolve(work), 'pi')
        self.assertEqual(self.resolve(self.root), 'pi')
        for override in ('pi', 'claude', 'codex', 'agy', 'agent', 'cursor'):
            self.assertEqual(self.resolve(work, override), 'agent' if override == 'cursor' else override)
        subprocess.run(['git', 'init', '-q', str(work)], check=True)
        subprocess.run(['git', '-C', str(work), 'remote', 'add', 'origin',
                        'git@github.com:timopruesse/project.git'], check=True)
        self.assertEqual(self.resolve(work), 'pi')
        subprocess.run(['git', '-C', str(work), 'remote', 'set-url', 'origin',
                        'https://github.com/chewielabs/project.git'], check=True)
        self.assertEqual(self.resolve(work), 'pi')
        self.assertEqual(self.resolve(work, 'unknown'), 'pi')

    def test_launch_arguments(self):
        env = self.prepare_launch()
        cases = [
            ([], ['pi']),
            (['--pi', '--', 'fix this'], ['pi', '--', 'fix this']),
            (['resume'], ['pi', '--resume']),
            (['continue', '--pi'], ['pi', '--continue']),
            (['--print', '--pi', '--', '--literal'], ['pi', '-p', '--', '--literal']),
            (['--codex', '--pi'], ['pi']),
            (['--codex', '--', 'fix this'], ['codex', '--', 'fix this']),
            (['resume', '--codex'], ['codex', 'resume']),
            (['continue', '--codex'], ['codex', 'resume', '--last']),
            (['--print', '--codex', '--', '--claude'], ['codex', 'exec', '--', '--claude']),
            (['--claude', '--codex'], ['codex']),
            (['resume', '--claude'], ['claude', '--resume']),
            (['continue', '--agent'], ['agent', '--continue']),
            (['resume', '--agy'], ['agy', '--continue']),
            (['--print', '--agent', '--', 'fix this'], ['agent', '-p', '--', 'fix this']),
        ]
        for args, expected in cases:
            with self.subTest(args=args):
                result = subprocess.check_output(
                    ['zsh', str(self.root / 'coding_agent_launch.sh'), *args],
                    cwd=self.root, env=env,
                ).decode().rstrip('\0').split('\0')
                self.assertEqual(result, expected)

    def prepare_launch(self):
        for name in ('coding_agent_launch.sh', 'coding_agent_resolve.sh'):
            shutil.copy(SCRIPTS / name, self.root)
        for cli in ('pi', 'codex', 'claude', 'agent', 'agy'):
            binary = self.root / cli
            binary.write_text('#!/bin/sh\nprintf "%s\\0" "${0##*/}" "$@"\n')
            binary.chmod(0o755)
        return {**self.env, 'PATH': str(self.root) + ':' + os.environ['PATH']}

    def test_prompt_file_and_metadata_use_launched_host_and_pane(self):
        env = self.prepare_launch()
        context = self.root / 'pane_context.sh'
        context.write_text('#!/bin/sh\nif [ "$1" = worktree-name ]; then echo feature; '
                           'else printf "%s\\n" "$*" >> "$HOME/metadata"; fi\n')
        context.chmod(0o755)
        prompt = self.root / 'prompt with spaces'
        prompt.write_text('--literal prompt\nsecond line')
        result = subprocess.check_output(
            ['zsh', str(self.root / 'coding_agent_launch.sh'), '--claude', '--codex',
             '--prompt-file', str(prompt)], cwd=self.root,
            env={**env, 'CODING_AGENT': 'agy', 'HERDR_ENV': '1', 'HERDR_PANE_ID': 'w2:p4'})
        self.assertEqual(result.decode().rstrip('\0').split('\0'), ['codex', '--', '--literal prompt\nsecond line'])
        self.assertFalse(prompt.exists())
        self.assertEqual((self.root / 'metadata').read_text().splitlines(),
                         ['set-agent codex w2:p4', 'set-wt feature w2:p4'])

    def test_missing_prompt_and_binary_fail(self):
        env = self.prepare_launch()
        result = subprocess.run(['zsh', str(self.root / 'coding_agent_launch.sh'), '--cursor',
                                 '--prompt-file', str(self.root / 'absent')],
                                cwd=self.root, env=env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('prompt file not found', result.stderr)
        result = subprocess.run([shutil.which('zsh'), str(self.root / 'coding_agent_launch.sh'), '--codex'],
                                cwd=self.root, env={**env, 'PATH': '/usr/bin:/bin'},
                                capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('codex not found', result.stderr)


if __name__ == '__main__':
    unittest.main()
