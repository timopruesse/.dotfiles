import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
INSTALLER = ROOT / 'home/setup_wsl_browser.py'
SPEC = importlib.util.spec_from_file_location('setup_wsl_browser', INSTALLER)
assert SPEC is not None and SPEC.loader is not None
setup = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(setup)


class WslBrowserSetupTests(unittest.TestCase):
    def test_non_wsl_does_not_write_or_register(self):
        with patch.dict(os.environ, {'WSL_DISTRO_NAME': ''}), \
                patch.object(Path, 'read_text', return_value='Linux ordinary kernel'), \
                patch.object(Path, 'mkdir') as mkdir, \
                patch.object(setup.subprocess, 'run') as run:
            self.assertEqual(setup.main(), 0)
        mkdir.assert_not_called()
        run.assert_not_called()

    def test_wsl_detection(self):
        with patch.dict(os.environ, {'WSL_DISTRO_NAME': 'Ubuntu'}), \
                patch.object(Path, 'read_text', side_effect=AssertionError('unneeded')):
            self.assertTrue(setup.is_wsl())
        with patch.dict(os.environ, {'WSL_DISTRO_NAME': ''}), \
                patch.object(Path, 'read_text', return_value='Linux Microsoft-standard-WSL2'):
            self.assertTrue(setup.is_wsl())
        with patch.dict(os.environ, {'WSL_DISTRO_NAME': ''}), \
                patch.object(Path, 'read_text', side_effect=FileNotFoundError):
            self.assertFalse(setup.is_wsl())

@unittest.skipUnless(shutil.which('xdg-mime') and shutil.which('gio'),
                     'xdg-mime and gio are required')
class DesktopIntegrationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name)
        self.data = self.home / 'xdg data'
        self.config = self.home / 'config'
        self.env = {**os.environ, 'HOME': str(self.home),
                    'XDG_DATA_HOME': str(self.data), 'XDG_CONFIG_HOME': str(self.config),
                    'XDG_CACHE_HOME': str(self.home / 'cache'),
                    'XDG_DATA_DIRS': str(self.home / 'system-data'),
                    'XDG_CONFIG_DIRS': str(self.home / 'system-config'),
                    'XDG_CURRENT_DESKTOP': 'X-Generic', 'WSL_DISTRO_NAME': 'Ubuntu',
                    'LC_ALL': 'C'}
        source = self.home / 'checkout space "quote" `tick` $cash \\slash %u'
        source.mkdir()
        self.installer = source / 'setup_wsl_browser.py'
        shutil.copyfile(INSTALLER, self.installer)
        self.bridge = source / '.config/zsh/wsl_browser.py'
        self.bridge.parent.mkdir(parents=True)
        self.record = self.home / 'browser-arguments.json'
        self.bridge.write_text(
            '#!/usr/bin/env python3\n'
            'import json, os, sys\n'
            'from pathlib import Path\n'
            'Path(os.environ["BROWSER_RECORD"]).write_text(json.dumps(sys.argv[1:]))\n'
        )
        self.bridge.chmod(0o755)
        self.env.update({'BROWSER_RECORD': str(self.record),
                         'PATH': str(self.home / '.local/bin') + os.pathsep + os.environ['PATH'],
                         'DISPLAY': ':0', 'BROWSER': '/usr/bin/false'})
        self.link = self.home / 'setup_wsl_browser.py'
        self.link.symlink_to(self.installer)

    def command(self, *args):
        return subprocess.check_output(args, env=self.env, text=True, stderr=subprocess.STDOUT)

    def install(self):
        self.command(sys.executable, str(self.link))

    def test_real_defaults_idempotence_and_unrelated_associations(self):
        self.config.mkdir()
        mimeapps = self.config / 'mimeapps.list'
        mimeapps.write_text('[Default Applications]\ntext/html=keep-html.desktop;\n'
                            'x-scheme-handler/file=keep-files.desktop;\n'
                            'application/pdf=keep-pdf.desktop;\n'
                            '\n[Added Associations]\ntext/plain=keep-text.desktop;\n')
        self.install()
        desktop = self.data / 'applications' / setup.DESKTOP_ID
        self.assertTrue(desktop.is_file())
        self.assertIn('Exec=dotfiles-wsl-browser %u\n', desktop.read_text())
        launcher = self.home / '.local/bin/dotfiles-wsl-browser'
        self.assertEqual(launcher.readlink(), self.bridge)
        self.assertTrue(os.access(launcher, os.X_OK))
        launcher_mtime = launcher.lstat().st_mtime_ns
        self.assertIn('MimeType=x-scheme-handler/http;x-scheme-handler/https;\n',
                      desktop.read_text())
        for mime_type in setup.WEB_TYPES:
            self.assertEqual(self.command('xdg-mime', 'query', 'default', mime_type).strip(),
                             setup.DESKTOP_ID)
            default_line = self.command('gio', 'mime', mime_type).splitlines()[0]
            self.assertTrue(default_line.endswith(': ' + setup.DESKTOP_ID), default_line)
        for association in ('text/html=keep-html.desktop;',
                            'x-scheme-handler/file=keep-files.desktop;',
                            'application/pdf=keep-pdf.desktop;',
                            'text/plain=keep-text.desktop;'):
            self.assertIn(association, mimeapps.read_text())
        before = {path: path.read_bytes() for path in (desktop, mimeapps)}
        mtime = desktop.stat().st_mtime_ns
        self.install()
        self.assertEqual(before, {path: path.read_bytes() for path in before})
        self.assertEqual(mtime, desktop.stat().st_mtime_ns)
        self.assertEqual(launcher_mtime, launcher.lstat().st_mtime_ns)

    def test_replaces_stale_launcher_symlink(self):
        launcher = self.home / '.local/bin/dotfiles-wsl-browser'
        launcher.parent.mkdir(parents=True)
        launcher.symlink_to(self.home / 'old-missing-bridge')
        self.install()
        self.assertEqual(launcher.readlink(), self.bridge)
        self.assert_launch('gio', 'launch',
                           str(self.data / 'applications' / setup.DESKTOP_ID))

    def test_preserves_unrelated_launcher_file(self):
        launcher = self.home / '.local/bin/dotfiles-wsl-browser'
        launcher.parent.mkdir(parents=True)
        launcher.write_text('unrelated executable')
        result = subprocess.run([sys.executable, str(self.link)], env=self.env,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn('File exists', result.stderr)
        self.assertEqual(launcher.read_text(), 'unrelated executable')
        self.assertFalse((self.data / 'applications' / setup.DESKTOP_ID).exists())

    def assert_launch(self, *command):
        uri = 'https://example.com/a%20path?q=space%20here&literal=%25#fragment'
        result = subprocess.run([*command, uri], env=self.env, text=True,
                                capture_output=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, '')
        deadline = time.monotonic() + 3
        while not self.record.exists() and time.monotonic() < deadline:
            time.sleep(0.01)
        self.assertTrue(self.record.exists(), result.stdout)
        self.assertEqual(json.loads(self.record.read_text()), [uri])

    def test_gio_launches_bridge(self):
        self.install()
        self.assert_launch('gio', 'launch',
                           str(self.data / 'applications' / setup.DESKTOP_ID))

    @unittest.skipUnless(shutil.which('xdg-open'), 'xdg-open is required')
    def test_xdg_open_launches_bridge_in_generic_mode(self):
        self.install()
        self.assert_launch('xdg-open')

    def test_default_data_home(self):
        self.env.pop('XDG_DATA_HOME')
        self.install()
        self.assertTrue((self.home / '.local/share/applications' / setup.DESKTOP_ID).is_file())


if __name__ == '__main__':
    unittest.main()
