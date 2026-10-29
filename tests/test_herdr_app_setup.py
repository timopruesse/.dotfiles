"""Exercise the preference installer without touching a running Herdr app."""
import json
import os
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
        path.write_text(json.dumps(value), encoding='utf-8')
        return path

    def read(self, name):
        return json.loads((self.target / name).read_text(encoding='utf-8'))

    def test_fresh_config_contains_only_managed_preferences(self):
        self.run_setup()
        for name in ('settings.json', 'keys.json'):
            expected = json.loads((RESOURCES / name).read_text())
            self.assertEqual(self.read(name), expected)
            self.assertFalse((self.target / name).is_symlink())
        self.assertEqual(sorted(p.name for p in self.target.iterdir()), ['keys.json', 'settings.json'])

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
        before = {p.name: (p.read_bytes(), p.stat().st_mtime_ns) for p in self.target.iterdir()}
        self.run_setup()
        after = {p.name: (p.read_bytes(), p.stat().st_mtime_ns) for p in self.target.iterdir()}
        self.assertEqual(after, before)

    def test_already_matching_noncanonical_json_is_not_reformatted(self):
        for name in ('settings.json', 'keys.json'):
            self.put(name, json.loads((RESOURCES / name).read_text()))
        before = {p.name: (p.read_bytes(), p.stat().st_mtime_ns) for p in self.target.iterdir()}
        self.run_setup()
        self.assertEqual(before, {p.name: (p.read_bytes(), p.stat().st_mtime_ns) for p in self.target.iterdir()})

    def test_invalid_json_or_object_rejects_all_writes(self):
        for name, invalid in (
            ('settings.json', '{broken'), ('keys.json', '{broken'),
            ('settings.json', '[]'), ('settings.json', '{"sounds": false}'),
            ('keys.json', '{"global": []}'),
        ):
            with self.subTest(name=name, invalid=invalid):
                for path in self.target.glob('*'):
                    path.unlink()
                self.put('settings.json', {'font': 'Keep'})
                self.put('keys.json', {'terminal': {'ctrl-1': 'terminal'}})
                (self.target / name).write_text(invalid)
                before = {p.name: (p.read_bytes(), p.stat().st_mtime_ns) for p in self.target.iterdir()}
                self.run_setup(success=False)
                self.assertEqual(before, {p.name: (p.read_bytes(), p.stat().st_mtime_ns) for p in self.target.iterdir()})

    def test_symlinked_installer_resolves_resources_from_checkout(self):
        link = self.home / 'setup_herdr_app.py'
        link.symlink_to(SCRIPT)
        self.run_setup(script=link)
        self.assertEqual(self.read('settings.json')['appearance'], 'dark')

    def test_documented_home_override(self):
        self.target = self.home / 'alternate-app-home'
        self.env['HERDR_APP_HOME'] = str(self.target)
        self.run_setup()
        self.assertTrue((self.target / 'keys.json').is_file())
        self.assertFalse((self.home / '.config/herdr-app').exists())


if __name__ == '__main__':
    unittest.main()
