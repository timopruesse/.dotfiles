"""Pi setup tests: no network, credentials, or agent requests."""
import importlib.util
import json
import os
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


PSTACK_COMMAND = '''\
let potetoMode = false;
const MODE_ENTRY = "pstack-mode";
pi.registerCommand("poteto-mode", {
  handler: async (args, ctx) => {
    if (/^(off|disable|stop)$/i.test(args.trim())) {
      potetoMode = false;
      pi.appendEntry(MODE_ENTRY, { enabled: false });
      ctx.ui.setStatus("pstack-mode", undefined);
      ctx.ui.notify("Poteto Mode disabled for this session.", "info");
      return;
    }
    potetoMode = true;
    pi.appendEntry(MODE_ENTRY, { enabled: true });
    ctx.ui.setStatus("pstack-mode", "pstack: poteto mode");
    await ctx.sendUserMessage(`/skill:poteto-mode${args.trim() ? ` ${args.trim()}` : ""}`);
  },
});
'''


class PiSetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.agent = self.home / '.pi/agent'
        self.agent.mkdir(parents=True)

    def install(self):
        setup_pi.install(self.home, ROOT / 'home')

    def pstack_fixture(self, text=PSTACK_COMMAND, version='0.1.0'):
        package = self.agent / 'npm/node_modules/pi-pstack'
        package.mkdir(parents=True)
        (package / 'package.json').write_text(json.dumps({'name': 'pi-pstack', 'version': version}))
        path = package / 'extensions/pstack/index.ts'
        path.parent.mkdir(parents=True)
        path.write_text(text)
        return path

    def test_pstack_patch_survives_reinstall_and_is_idempotent(self):
        path = self.pstack_fixture()
        self.install()
        patched = path.read_text()
        self.assertNotIn('ctx.sendUserMessage', patched)
        self.assertIn('pi.sendUserMessage', patched)
        self.assertIn('expandPromptTemplates: true', patched)
        before = path.stat().st_mtime_ns
        self.install()
        self.assertEqual(path.stat().st_mtime_ns, before)
        path.write_text(PSTACK_COMMAND)
        self.install()
        self.assertEqual(path.read_text(), patched)

    def test_pstack_patch_rejects_unknown_source_before_installing_resources(self):
        path = self.pstack_fixture(text='unexpected upstream code')
        with self.assertRaisesRegex(RuntimeError, 'Unexpected pi-pstack command source'):
            self.install()
        self.assertEqual(path.read_text(), 'unexpected upstream code')
        self.assertFalse((self.agent / 'AGENTS.md').exists())
        self.assertFalse((self.agent / 'settings.json').exists())

    def test_pstack_patch_rejects_unreviewed_version(self):
        path = self.pstack_fixture(version='0.2.0')
        with self.assertRaisesRegex(RuntimeError, 'installed package version'):
            self.install()
        self.assertEqual(path.read_text(), PSTACK_COMMAND)

    @unittest.skipUnless(shutil.which('node'), 'Node.js is not installed')
    def test_pstack_command_uses_api_owner_and_expands_skill(self):
        path = self.pstack_fixture()
        self.install()
        script = '''
import assert from 'node:assert/strict';
let handler;
const entries = [], messages = [], statuses = [], notices = [];
const pi = {
  registerCommand: (name, command) => { handler = command.handler; },
  appendEntry: (type, data) => entries.push([type, data]),
  sendUserMessage: (content, options) => messages.push([content, options]),
};
const ctx = { ui: {
  setStatus: (key, value) => statuses.push([key, value]),
  notify: (message, level) => notices.push([message, level]),
} };
''' + path.read_text() + '''
assert.equal(ctx.sendUserMessage, undefined);
await handler('', ctx);
await handler('  fix tests  ', ctx);
await handler('off', ctx);
assert.deepEqual(messages, [
  ['/skill:poteto-mode', { expandPromptTemplates: true }],
  ['/skill:poteto-mode fix tests', { expandPromptTemplates: true }],
]);
assert.deepEqual(entries.map(([, data]) => data.enabled), [true, true, false]);
assert.deepEqual(statuses.map(([, value]) => value), ['pstack: poteto mode', 'pstack: poteto mode', undefined]);
assert.deepEqual(notices, [['Poteto Mode disabled for this session.', 'info']]);
'''
        result = subprocess.run(['node', '--input-type=module'], input=script,
                                capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)

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
        # Retired runtime settings are user-owned and inert, not migration targets.
        self.assertEqual(loaded['subagents'], original['subagents'])
        self.assertFalse(settings.is_symlink())
        self.assertEqual(settings.stat().st_mode & 0o777, 0o600)
        for relative in ('auth.json', 'sessions/saved.jsonl', 'extensions/personal.ts',
                         'prompts/custom.md'):
            self.assertEqual((self.agent / relative).read_text(), 'user-owned')
        for relative in ('AGENTS.md', 'prompts/plan.md', 'prompts/review.md',
                         'prompts/dispatch.md', 'prompts/ship.md',
                         'prompts/babysit-pr.md', 'agents/pstack-reviewer.md', 'skills/herdr',
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

    def test_reviewer_collision_preflights_all_links(self):
        collision = self.agent / 'agents/pstack-reviewer.md'
        collision.parent.mkdir()
        collision.write_text('personal role')
        with self.assertRaisesRegex(RuntimeError, 'collision'):
            self.install()
        self.assertEqual(collision.read_text(), 'personal role')
        self.assertFalse((self.agent / 'AGENTS.md').exists())
        self.assertFalse((self.agent / 'settings.json').exists())

    def test_broken_foreign_symlink_is_a_collision(self):
        (self.agent / 'AGENTS.md').symlink_to('missing-personal-file')
        with self.assertRaisesRegex(RuntimeError, 'collision'):
            self.install()

    def test_invalid_settings_fail_before_resource_install(self):
        settings = self.agent / 'settings.json'
        for text in ('not json', '[]', '{"modelThinkingLevels": []}'):
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
        self.assertNotIn('subagents', loaded)


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
        for package in ('npm:pi-web-access@0.41.0', 'npm:pi-pstack@0.1.0',
                        'npm:pi-lens@4.4.3', 'npm:pi-impeccable@0.1.0'):
            self.assertEqual(config.count('pi install ' + package + '\n'), 2)
            name = package.rsplit('@', 1)[0]
            self.assertEqual(config.count('pi remove ' + name + '\n'), 1)
        self.assertNotIn('pi install npm:pi-subagents', config)
        self.assertNotIn('pi install "$HOME/pi-workbench"', config)
        section = config.split('  pi_packages:', 1)[1].split('  pi_mcp:', 1)[0]
        for phase in ('install', 'update'):
            commands = section.split(f'        {phase}:\n', 1)[1].split(
                '        update:' if phase == 'install' else '        uninstall:', 1)[0]
            self.assertIn('pi install npm:pi-pstack@0.1.0\n'
                          '        - python3 $HOME/setup_pi.py\n', commands)
            self.assertLess(commands.index('pi remove npm:pi-subagents'),
                            commands.index('pi install npm:pi-pstack'))
            self.assertLess(commands.index('pi remove "$HOME/pi-workbench"'),
                            commands.index('pi install npm:pi-pstack'))

    def test_retired_package_removal_is_repeatable_and_fails_closed(self):
        config = (ROOT / 'machine_setup.yaml').read_text()
        phase = config.split('  pi_packages:', 1)[1].split('        update:', 1)[0]
        commands = [' '.join(line.strip() for line in
                             block.split('        - ', 1)[0].splitlines())
                    for block in phase.split('        - >-\n')[1:]]
        self.assertEqual(len(commands), 2)
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            pi = home / '.local/bin/pi'
            pi.parent.mkdir(parents=True)
            pi.write_text('''#!/bin/sh
if [ "$1" = list ]; then
    [ "$FAIL_LIST" = 1 ] && exit 9
    printf '%s\\n' "$PACKAGE_LIST"
else
    [ "$FAIL_REMOVE" = 1 ] && exit 8
    printf '%s\\n' "$*" >> "$HOME/calls"
fi
''')
            pi.chmod(0o755)
            env = {**os.environ, 'HOME': str(home), 'PACKAGE_LIST': '',
                   'FAIL_LIST': '0', 'FAIL_REMOVE': '0'}
            for command in commands:
                self.assertEqual(subprocess.run(['sh', '-c', command], env=env).returncode, 0)
            self.assertFalse((home / 'calls').exists())
            env['PACKAGE_LIST'] = ('User packages:\n  npm:pi-subagents@0.78.0\n'
                                   f'  ../../pi-workbench\n    {home}/pi-workbench\n')
            for command in commands:
                self.assertEqual(subprocess.run(['sh', '-c', command], env=env).returncode, 0)
            self.assertEqual((home / 'calls').read_text().splitlines(),
                             ['remove npm:pi-subagents', f'remove {home}/pi-workbench'])
            for flag, code in (('FAIL_LIST', 9), ('FAIL_REMOVE', 8)):
                for command in commands:
                    self.assertEqual(subprocess.run(
                        ['sh', '-c', command], env={**env, flag: '1'}).returncode, code)

    def test_poteto_workflow_and_read_only_reviewer(self):
        role = (ROOT / 'home/.pi/agent/agents/pstack-reviewer.md').read_text()
        self.assertIn('name: pstack-reviewer', role)
        self.assertIn('tools: read, grep, find, ls\n', role)
        instructions = (ROOT / 'home/.pi/agent/AGENTS.md').read_text()
        self.assertIn('default unless the user disables Poteto Mode', instructions)
        for name in ('dispatch', 'ship', 'babysit-pr'):
            prompt = (ROOT / f'home/.pi/agent/prompts/{name}.md').read_text()
            self.assertIn('poteto-mode', prompt)
            self.assertIn('pstack_todo', prompt)
            self.assertNotIn('Load the installed `workbench`', prompt)
            self.assertNotIn('`pi-subagents` worker', prompt)
        review = (ROOT / 'home/.pi/agent/prompts/review.md').read_text()
        self.assertIn('agentScope: "user"', review)
        self.assertIn('pstack-reviewer', review)
        self.assertIn('exact patch/head', review)


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
