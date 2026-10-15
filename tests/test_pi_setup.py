"""Pi setup tests: no network, credentials, or agent requests."""
import importlib.util
import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('setup_pi', ROOT / 'home/setup_pi.py')
assert spec is not None and spec.loader is not None
setup_pi = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup_pi)


class PiSetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.agent = self.home / '.pi/agent'
        self.agent.mkdir(parents=True)

    def install(self):
        setup_pi.install(self.home, ROOT / 'home')

    def test_preserves_state_settings_and_unrelated_resources(self):
        original = {'defaultProvider': 'personal', 'defaultModel': 'chosen',
                    'defaultThinkingLevel': 'high',
                    'modelThinkingLevels': {'openai/gpt-6.1-sol': 'high', 'other/model': 'low'},
                    'packages': ['npm:example'], 'skills': ['~/custom-skills'], 'theme': 'dark',
                    'subagents': {'customSetting': True, 'agentOverrides': {
                        'worker': {'model': 'personal/model'},
                        'reviewer': {'model': 'personal/reviewer', 'tools': 'bash, edit'}}}}
        settings = self.agent / 'settings.json'
        settings.write_text(json.dumps(original))
        settings.chmod(0o600)
        for relative in ('auth.json', 'sessions/saved.jsonl', 'extensions/personal.ts',
                         'prompts/custom.md'):
            path = self.agent / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('user-owned')
        self.install()
        loaded = json.loads(settings.read_text())
        for key in ('packages', 'skills', 'theme'):
            self.assertEqual(loaded[key], original[key])
        self.assertEqual(loaded['defaultProvider'], 'openai')
        self.assertEqual(loaded['defaultModel'], 'gpt-6.1-sol')
        self.assertEqual(loaded['defaultThinkingLevel'], 'medium')
        self.assertEqual(loaded['modelThinkingLevels'],
                         {'openai/gpt-6.1-sol': 'medium', 'other/model': 'low'})
        subagents = loaded['subagents']
        self.assertTrue(subagents['customSetting'])
        self.assertEqual(subagents['agentOverrides']['worker'], {'model': 'personal/model'})
        reviewer = subagents['agentOverrides']['reviewer']
        self.assertEqual(reviewer['model'], 'personal/reviewer')
        self.assertEqual(reviewer['acceptanceRole'], 'read-only')
        self.assertEqual(reviewer['defaultContext'], 'fresh')
        self.assertEqual(set(reviewer['tools']),
                         {'read', 'grep', 'find', 'ls', 'watchdog_diff', 'contact_supervisor'})
        self.assertFalse(settings.is_symlink())
        self.assertEqual(settings.stat().st_mode & 0o777, 0o600)
        for relative in ('auth.json', 'sessions/saved.jsonl', 'extensions/personal.ts',
                         'prompts/custom.md'):
            self.assertEqual((self.agent / relative).read_text(), 'user-owned')
        for relative in ('AGENTS.md', 'prompts/plan.md', 'prompts/review.md',
                         'prompts/dispatch.md', 'prompts/ship.md',
                         'prompts/babysit-pr.md', 'skills/herdr',
                         'skills/improve-codebase-architecture'):
            self.assertTrue((self.agent / relative).is_symlink())
            self.assertTrue((self.agent / relative).exists())
        before = settings.stat().st_mtime_ns
        self.install()
        self.assertEqual(settings.stat().st_mtime_ns, before)

    def test_collision_preflights_all_links(self):
        collision = self.agent / 'prompts/review.md'
        collision.parent.mkdir()
        collision.write_text('personal review')
        with self.assertRaisesRegex(RuntimeError, 'collision'):
            self.install()
        self.assertEqual(collision.read_text(), 'personal review')
        self.assertFalse((self.agent / 'AGENTS.md').exists())
        self.assertFalse((self.agent / 'settings.json').exists())

    def test_broken_foreign_symlink_is_a_collision(self):
        (self.agent / 'AGENTS.md').symlink_to('missing-personal-file')
        with self.assertRaisesRegex(RuntimeError, 'collision'):
            self.install()

    def test_invalid_settings_fail_before_resource_install(self):
        settings = self.agent / 'settings.json'
        for text in ('not json', '[]', '{"modelThinkingLevels": []}',
                     '{"subagents": []}', '{"subagents": {"agentOverrides": []}}',
                     '{"subagents": {"agentOverrides": {"reviewer": null}}}'):
            with self.subTest(text=text):
                settings.write_text(text)
                with self.assertRaises((ValueError, RuntimeError)):
                    self.install()
                self.assertEqual(settings.read_text(), text)
                self.assertFalse((self.agent / 'AGENTS.md').exists())

    def test_symlinked_settings_are_not_replaced(self):
        target = self.home / 'personal-settings.json'
        target.write_text('{}')
        (self.agent / 'settings.json').symlink_to(target)
        with self.assertRaisesRegex(RuntimeError, 'not a symlink'):
            self.install()
        self.assertEqual(target.read_text(), '{}')
        self.assertTrue((self.agent / 'settings.json').is_symlink())

    def test_fresh_setup_creates_private_model_defaults(self):
        self.install()
        settings = self.agent / 'settings.json'
        self.assertEqual(settings.stat().st_mode & 0o777, 0o600)
        loaded = json.loads(settings.read_text())
        self.assertEqual(loaded['defaultModel'], 'gpt-6.1-sol')
        self.assertEqual(loaded['defaultThinkingLevel'], 'medium')
        self.assertNotIn('packages', loaded)


class PiResourceTests(unittest.TestCase):
    def test_approved_custom_prompt_set(self):
        prompts = ROOT / 'home/.pi/agent/prompts'
        self.assertEqual({p.stem for p in prompts.glob('*.md')},
                         {'plan', 'review', 'dispatch', 'ship', 'babysit-pr'})
        for path in prompts.glob('*.md'):
            with self.subTest(path=path):
                self.assertTrue(path.read_text().startswith('---\ndescription:'))
                self.assertIn('$', path.read_text())

    def test_approved_packages_declared_for_install_and_update(self):
        config = (ROOT / 'machine_setup.yaml').read_text()
        for package in ('npm:pi-web-access@0.41.0', 'npm:pi-subagents@0.78.0',
                        'npm:pi-lens@4.4.3', 'npm:pi-impeccable@0.1.0'):
            self.assertEqual(config.count('pi install ' + package + '\n'), 2)
            name = package.rsplit('@', 1)[0]
            self.assertEqual(config.count('pi remove ' + name + '\n'), 1)
        self.assertEqual(config.count('pi install "$HOME/pi-workbench"\n'), 2)
        self.assertEqual(config.count('pi remove "$HOME/pi-workbench"\n'), 1)

    def test_workbench_manifest_and_workflow_integration(self):
        package = ROOT / 'home/pi-workbench'
        manifest = json.loads((package / 'package.json').read_text())
        self.assertEqual(manifest['name'], 'pi-workbench')
        self.assertTrue(manifest['private'])
        self.assertEqual(manifest['pi']['extensions'], ['./index.ts'])
        self.assertTrue((package / 'skills/workbench/SKILL.md').exists())
        for name in ('dispatch', 'review', 'ship', 'babysit-pr'):
            prompt = ROOT / f'home/.pi/agent/prompts/{name}.md'
            self.assertIn('workbench', prompt.read_text())


class PiProviderTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('nvim'), 'Neovim is not installed')
    def test_99_pi_provider_commands(self):
        provider = ROOT / 'home/.config/nvim/lua/timopruesse/pi_provider.lua'
        lua = '''
package.preload['99.providers'] = function() return { BaseProvider = {} } end
local provider = dofile(PROVIDER_PATH)
assert(provider._get_provider_name() == 'PiProvider')
assert(provider._get_default_model() == 'default')
assert(vim.deep_equal(provider._build_command(nil, '--literal prompt', {model='default'}),
    {'pi', '--print', '--no-session', '--', '--literal prompt'}))
assert(vim.deep_equal(provider._build_command(nil, 'query', {model='provider/model'}),
    {'pi', '--print', '--no-session', '--model', 'provider/model', '--', 'query'}))
'''.replace('PROVIDER_PATH', json.dumps(str(provider)))
        result = subprocess.run(
            ['nvim', '--headless', '-u', 'NONE', '-i', 'NONE',
             '-c', 'lua ' + lua, '-c', 'qa!'], capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn('Error', result.stderr)


if __name__ == '__main__':
    unittest.main()
