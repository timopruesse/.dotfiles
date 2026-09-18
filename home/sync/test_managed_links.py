"""Installation behavior against temporary homes and linked worktrees."""
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from sync.managed_links import install_links
from sync import live_install, project_agents


class ManagedLinkTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        self.source = self.root / 'source'
        self.live = self.root / 'live'
        self.source.mkdir()
        self.live.mkdir()

    def test_preservation_pruning_and_repeat(self):
        for suffix in ('md', 'toml', 'mdc'):
            with self.subTest(suffix=suffix):
                (self.source / f'scout.{suffix}').write_text('managed')
                personal = self.root / f'personal.{suffix}'
                personal.write_text('personal')
                foreign = self.live / personal.name
                foreign.symlink_to(personal)
                stale = self.live / f'stale.{suffix}'
                stale.symlink_to(self.source / stale.name)
                self.assertEqual(install_links(self.source, self.live, f'*.{suffix}'), 2)
                self.assertTrue(foreign.is_symlink())
                self.assertFalse(stale.is_symlink())
                self.assertEqual(install_links(self.source, self.live, f'*.{suffix}'), 0)

    def test_collision_preflight(self):
        for kind in ('file', 'directory', 'foreign-link', 'broken-link'):
            with self.subTest(kind=kind):
                live = self.live / kind
                live.mkdir()
                (self.source / 'a.md').write_text('managed')
                (self.source / 'z.md').write_text('managed')
                conflict = live / 'z.md'
                if kind == 'file':
                    conflict.write_text('personal')
                elif kind == 'directory':
                    conflict.mkdir()
                else:
                    target = self.root / kind
                    if kind == 'foreign-link':
                        target.write_text('personal')
                    conflict.symlink_to(target)
                with self.assertRaises(SystemExit):
                    install_links(self.source, live, '*.md')
                self.assertFalse((live / 'a.md').exists())
                self.assertTrue(conflict.exists() or conflict.is_symlink())

    def test_missing_source_does_not_prune(self):
        missing = self.root / 'missing'
        stale = self.live / 'scout.md'
        stale.symlink_to(missing / 'scout.md')
        self.assertEqual(install_links(missing, self.live, '*.md'), 0)
        self.assertTrue(stale.is_symlink())

    def test_skill_names_reclaimed_without_touching_foreign_targets(self):
        for kind in ('file', 'directory', 'link'):
            skill = self.source / kind
            skill.mkdir()
            (skill / 'SKILL.md').write_text('managed')
            dest = self.live / kind
            if kind == 'file':
                dest.write_text('personal')
            elif kind == 'directory':
                dest.mkdir()
                (dest / 'custom').write_text('personal')
            else:
                external = self.root / 'external'
                external.mkdir()
                (external / 'keep').write_text('personal')
                dest.symlink_to(external)
        unrelated = self.live / 'personal'
        unrelated.mkdir()
        with patch.multiple(live_install, SKILLS_SRC=self.source,
                            LIVE_CURSOR_SKILLS=self.live, LIVE_CLAUDE_SKILLS=self.live,
                            LIVE_AGENTS_SKILLS=self.live, LIVE_AGY_SKILLS=self.live):
            live_install.install_skills()
            live_install.install_skills()
        for kind in ('file', 'directory', 'link'):
            self.assertEqual((self.live / kind).resolve(), (self.source / kind).resolve())
        self.assertTrue(unrelated.is_dir())
        self.assertEqual((self.root / 'external/keep').read_text(), 'personal')
        self.assertFalse(list(self.live.glob('*.bak*')))

    def test_external_source_link_does_not_claim_its_parent_directory(self):
        external = self.root / 'external'
        external.mkdir()
        (external / 'custom.md').write_text('custom')
        (self.source / 'custom.md').symlink_to(external / 'custom.md')
        foreign = self.live / 'personal.md'
        foreign.symlink_to(external / 'personal.md')
        self.assertEqual(install_links(self.source, self.live, '*.md'), 1)
        self.assertEqual(install_links(self.source, self.live, '*.md'), 0)
        self.assertTrue(foreign.is_symlink())

    def test_project_links_resolve_live_source_and_exclude_worktree(self):
        repo = self.root / 'repo'
        repo.mkdir()
        def git(*args):
            return subprocess.check_output(['git', '-C', str(repo), *args], text=True).strip()
        git('init', '-q')
        git('-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
            '-c', 'core.hooksPath=/dev/null', '-c', 'commit.gpgsign=false',
            'commit', '--allow-empty', '-qm', 'fixture')
        worktree = self.root / 'worktree'
        git('worktree', 'add', '--detach', '-q', str(worktree))
        (self.source / 'scout.md').write_text('managed')
        (self.live / 'scout.md').symlink_to(self.source / 'scout.md')
        with patch.multiple(project_agents, LIVE_AGENTS=self.live, GENERATED_AGENTS=self.source):
            for checkout in (repo, worktree):
                self.assertEqual(project_agents.ensure_project_agents(checkout), 1)
                foreign = checkout / '.cursor/agents/personal.md'
                foreign.symlink_to(self.root / 'foreign.md')
                self.assertEqual(project_agents.ensure_project_agents(checkout), 0)
                self.assertTrue(foreign.is_symlink())
                ignored = subprocess.run(['git', '-C', str(checkout), 'check-ignore',
                                          '.cursor/agents/scout.md'], capture_output=True)
                self.assertEqual(ignored.returncode, 0)


if __name__ == '__main__':
    unittest.main()
