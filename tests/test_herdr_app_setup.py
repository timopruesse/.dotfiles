"""Exercise the preference installer without touching a running Herdr app."""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'home/setup_herdr_app.py'
RESOURCES = ROOT / 'home/herdr-app'


class HerdrAppSetupTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.home = Path(temporary.name)
        self.target = self.home / '.config/herdr-app'
        self.env = dict(os.environ, HOME=str(self.home))
        self.env.pop('HERDR_APP_HOME', None)

    def run_setup(self, script=SCRIPT, success=True):
        result = subprocess.run(
            [sys.executable, str(script)], env=self.env,
            capture_output=True, text=True, check=False,
        )
        self.assertEqual(result.returncode == 0, success, result.stderr)
        return result

    def put(self, name, value):
        self.target.mkdir(parents=True, exist_ok=True)
        path = self.target / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value), encoding='utf-8')
        return path

    def read(self, name):
        return json.loads((self.target / name).read_text(encoding='utf-8'))

    def snapshot(self):
        return {str(p.relative_to(self.target)): (p.read_bytes(), p.stat().st_mtime_ns)
                for p in self.target.rglob('*') if p.is_file()}

    def test_fresh_config_contains_only_managed_resources_and_preferences(self):
        self.run_setup()
        for name in ('settings.json', 'keys.json'):
            expected = json.loads((RESOURCES / name).read_text())
            self.assertEqual(self.read(name), expected)
            self.assertFalse((self.target / name).is_symlink())
        self.assertEqual(set(self.snapshot()), {
            'keys.json', 'settings.json', 'layouts/dotfiles-main.json',
            'mods/dotfiles-spaces/main.js', 'mods/dotfiles-spaces/mod.json',
            'mods/dotfiles-spaces/grouping.js',
        })

    def test_preserves_nested_settings_keys_and_app_state_with_backups(self):
        settings = self.put('settings.json', {
            'font': 'Personal Mono', 'font_size': 17, 'zoom': 1.2,
            'sounds': {'enabled': True, 'done': 'done.mp3', 'blocked': 'blocked.mp3'},
            'colors': {'accent': '#123456'},
        })
        keys = self.put('keys.json', {
            'global': {'alt-1': 'space.select:1', 'ctrl-1': 'tab.select:1', 'ctrl-shift-t': 'tab.new'},
            'terminal': {'ctrl-9': 'terminal'},
            'layout:terminals': {'ctrl-p': 'app.palette'},
        })
        state = self.put('view.json', {'space': 'keep-me'})
        originals = {p: p.read_bytes() for p in (settings, keys, state)}
        self.run_setup()
        expected_settings = json.loads(originals[settings])
        expected_settings['sounds']['enabled'] = False
        expected_settings['appearance'] = 'dark'
        self.assertEqual(self.read('settings.json'), expected_settings)
        expected_keys = json.loads(originals[keys])
        expected_keys['global'].update(json.loads((RESOURCES / 'keys.json').read_text())['global'])
        self.assertEqual(self.read('keys.json'), expected_keys)
        self.assertEqual(state.read_bytes(), originals[state])
        for path in (settings, keys):
            backups = list(self.target.glob(f'{path.name}.backup-*'))
            self.assertEqual(len(backups), 1)
            self.assertEqual(backups[0].read_bytes(), originals[path])

    def test_second_run_changes_neither_bytes_mtime_nor_backups(self):
        self.put('settings.json', {'font': 'Keep'})
        self.run_setup()
        before = self.snapshot()
        self.run_setup()
        after = self.snapshot()
        self.assertEqual(after, before)

    def test_already_matching_noncanonical_json_is_not_reformatted(self):
        self.run_setup()
        for name in ('settings.json', 'keys.json'):
            self.put(name, json.loads((RESOURCES / name).read_text()))
        before = self.snapshot()
        self.run_setup()
        self.assertEqual(before, self.snapshot())

    def test_invalid_json_or_object_rejects_all_writes(self):
        for name, invalid in (
            ('settings.json', '{broken'), ('keys.json', '{broken'),
            ('settings.json', '[]'), ('settings.json', '{"sounds": false}'),
            ('keys.json', '{"global": []}'),
        ):
            with self.subTest(name=name, invalid=invalid):
                shutil.rmtree(self.target, ignore_errors=True)
                self.put('settings.json', {'font': 'Keep'})
                self.put('keys.json', {'terminal': {'ctrl-1': 'terminal'}})
                (self.target / name).write_text(invalid)
                before = self.snapshot()
                self.run_setup(success=False)
                self.assertEqual(before, self.snapshot())

    def test_symlinked_installer_resolves_resources_from_checkout(self):
        link = self.home / 'setup_herdr_app.py'
        link.symlink_to(SCRIPT)
        self.run_setup(script=link)
        self.assertEqual(self.read('settings.json')['appearance'], 'dark')

    def test_owned_resources_back_up_changes_without_touching_neighbors(self):
        self.run_setup()
        owned = self.target / 'mods/dotfiles-spaces/main.js'
        owned.write_text('// locally changed owned resource\n')
        neighbors = [self.put(name, {'keep': name}) for name in (
            'layouts/main.json', 'layouts/.state/dotfiles-main.json',
            'mods/spaces/mod.json', 'mods/unrelated/mod.json',
            'shared.json', 'installed.json', 'view.json', 'window.json',
        )]
        original = {p: (p.read_bytes(), p.stat().st_mtime_ns) for p in neighbors}
        self.run_setup()
        self.assertEqual(owned.read_bytes(), (RESOURCES / 'mods/dotfiles-spaces/main.js').read_bytes())
        backups = list(owned.parent.glob('main.js.backup-*'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), '// locally changed owned resource\n')
        self.assertEqual(original, {p: (p.read_bytes(), p.stat().st_mtime_ns) for p in neighbors})

    def test_symlink_files_and_ancestors_fail_before_any_write(self):
        for relative in ('settings.json', 'keys.json', 'mods', 'layouts',
                         'mods/dotfiles-spaces', 'mods/dotfiles-spaces/main.js',
                         'layouts/dotfiles-main.json'):
            with self.subTest(relative=relative):
                shutil.rmtree(self.target, ignore_errors=True)
                link = self.target / relative
                link.parent.mkdir(parents=True, exist_ok=True)
                outside = self.home / 'outside'
                outside.mkdir(exist_ok=True)
                link.symlink_to(outside / 'missing' if relative.endswith('.json') else outside)
                before = self.snapshot()
                self.run_setup(success=False)
                self.assertTrue(link.is_symlink())
                self.assertEqual(before, self.snapshot())
                self.assertEqual(list(outside.iterdir()), [])

    def test_symlink_app_home_is_not_followed(self):
        outside = self.home / 'outside'
        outside.mkdir()
        self.target.parent.mkdir(parents=True)
        self.target.symlink_to(outside)
        self.run_setup(success=False)
        self.assertEqual(list(outside.iterdir()), [])

    def test_nonfile_owned_target_rejects_all_writes(self):
        path = self.target / 'mods/dotfiles-spaces/main.js'
        path.mkdir(parents=True)
        self.run_setup(success=False)
        self.assertEqual(self.snapshot(), {})

    def test_invalid_resource_rejects_preference_changes(self):
        checkout = self.home / 'checkout'
        checkout.mkdir()
        script = checkout / SCRIPT.name
        shutil.copy2(SCRIPT, script)
        shutil.copytree(RESOURCES, checkout / 'herdr-app')
        resource = checkout / 'herdr-app/layouts/dotfiles-main.json'
        for invalid in ('{broken', '[]', ''):
            with self.subTest(invalid=invalid):
                resource.write_text(invalid)
                self.run_setup(script=script, success=False)
                self.assertFalse(self.target.exists())

    def test_layout_keeps_native_nodes_and_only_replaces_spaces_mod(self):
        layout = json.loads((RESOURCES / 'layouts/dotfiles-main.json').read_text())
        mods = []
        def visit(node):
            if 'mod' in node.get('content', {}):
                mods.append(node['content']['mod'])
            for child in node.get('children', []):
                visit(child)
        visit(layout)
        self.assertIn('dotfiles-spaces', mods)
        self.assertNotIn('spaces', mods)
        for mod in ('workspace-chrome', 'agents', 'tabs', 'files', 'changes', 'workspace-status'):
            self.assertIn(mod, mods)
        meta = json.loads((RESOURCES / 'mods/dotfiles-spaces/mod.json').read_text())
        self.assertEqual(meta['place'], 'none')

    def test_documented_home_override(self):
        self.target = self.home / 'alternate-app-home'
        self.env['HERDR_APP_HOME'] = str(self.target)
        self.run_setup()
        self.assertTrue((self.target / 'keys.json').is_file())
        self.assertFalse((self.home / '.config/herdr-app').exists())


if __name__ == '__main__':
    unittest.main()
