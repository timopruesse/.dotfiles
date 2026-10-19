"""WSL browser routing regressions; never start a real browser."""
import base64
import importlib.util
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / 'home/.config/zsh/wsl.zsh'
OPENER = CONFIG.with_name('wsl_browser.py')
ZSH = shutil.which('zsh')
SPEC = importlib.util.spec_from_file_location('wsl_browser', OPENER)
assert SPEC is not None and SPEC.loader is not None
browser = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(browser)


@unittest.skipUnless(ZSH, 'zsh is required')
class WslBrowserConfigTests(unittest.TestCase):
    def defaults(self, **overrides):
        assert ZSH is not None
        env = {**os.environ, 'WSL_DISTRO_NAME': 'Ubuntu', 'BROWSER': '',
               'XDG_CURRENT_DESKTOP': '', **overrides}
        return subprocess.check_output(
            [ZSH, '-f', '-c', 'source "$1"; printf "%s\\n" "$BROWSER" "$XDG_CURRENT_DESKTOP"',
             'test', str(CONFIG)], env=env, text=True,
        ).splitlines()

    def test_uses_opener_and_generic_handler(self):
        self.assertEqual(self.defaults(), [str(OPENER), 'X-Generic'])
        self.assertTrue(os.access(OPENER, os.X_OK))

    def test_replaces_inherited_browser_to_enforce_order(self):
        self.assertEqual(self.defaults(BROWSER='old-browser'), [str(OPENER), 'X-Generic'])

    def test_explicit_desktop_preserved(self):
        self.assertEqual(self.defaults(XDG_CURRENT_DESKTOP='GNOME'), [str(OPENER), 'GNOME'])

    def test_non_wsl_unchanged(self):
        self.assertEqual(self.defaults(WSL_DISTRO_NAME=''), ['', ''])


class WslBrowserRoutingTests(unittest.TestCase):
    def test_chrome_preferred_without_invoking_windows(self):
        with patch.object(browser.shutil, 'which', return_value='/usr/bin/google-chrome') as which, \
                patch.object(browser.subprocess, 'Popen') as spawn, \
                patch.object(browser.subprocess, 'run') as run:
            self.assertEqual(browser.open_browser('/home/test/test file.html'), 0)
            which.assert_called_once_with('google-chrome')
            self.assertEqual(spawn.call_args.args[0],
                             ['/usr/bin/google-chrome', '/home/test/test file.html'])
            self.assertTrue(spawn.call_args.kwargs['start_new_session'])
            run.assert_not_called()

    def test_stable_binary_supported(self):
        with patch.object(browser.shutil, 'which', side_effect=[None, '/bin/google-chrome-stable']), \
                patch.object(browser.subprocess, 'Popen') as spawn:
            browser.open_browser('https://example.com')
            self.assertEqual(spawn.call_args.args[0],
                             ['/bin/google-chrome-stable', 'https://example.com'])

    def windows_command(self, target):
        with patch.object(browser.shutil, 'which', return_value=None), \
                patch.object(browser.subprocess, 'run') as run:
            self.assertEqual(browser.open_browser(target), 0)
            args = run.call_args.args[0]
            self.assertEqual(args[:4], ['powershell.exe', '-NoProfile', '-NonInteractive',
                                       '-EncodedCommand'])
            self.assertTrue(run.call_args.kwargs['check'])
            return base64.b64decode(args[4]).decode('utf-16le')

    def test_windows_web_url_is_safely_quoted(self):
        target = "https://example.com/?q=it's&name=Grüße;$(not-code)"
        with patch.object(browser.subprocess, 'check_output') as convert:
            script = self.windows_command(target)
            convert.assert_not_called()
        self.assertEqual(script, "$ErrorActionPreference = 'Stop'; "
                         "$ProgressPreference = 'SilentlyContinue'; Start-Process -FilePath '"
                         + target.replace("'", "''") + "'")

    def test_windows_local_file_uses_wslpath(self):
        path = "/home/test/test file's.html"
        windows = "\\\\wsl.localhost\\Ubuntu\\home\\test\\test file's.html"
        with patch.object(browser.subprocess, 'check_output', return_value=windows + '\n') as convert:
            script = self.windows_command(path)
            convert.assert_called_once_with(['wslpath', '-aw', path], text=True)
        self.assertIn(windows.replace("'", "''"), script)

    def test_file_uri_is_decoded_before_conversion(self):
        with patch.object(browser.subprocess, 'check_output', return_value='C:\\file.html\n') as convert:
            self.windows_command('file:///home/test/test%20file%23%C3%BC.html')
            convert.assert_called_once_with(['wslpath', '-aw', '/home/test/test file#ü.html'], text=True)

    def test_relative_file_is_resolved(self):
        with patch.object(browser.subprocess, 'check_output', return_value='C:\\file.html\n') as convert:
            browser.windows_target('test.html')
            convert.assert_called_once_with(['wslpath', '-aw', str(Path('test.html').resolve())],
                                            text=True)

    def test_missing_windows_tools_report_failure(self):
        with tempfile.TemporaryDirectory() as empty:
            result = subprocess.run([sys.executable, str(OPENER), 'https://example.com'],
                                    env={**os.environ, 'PATH': empty}, capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn('Browser opening failed', result.stderr)

    def test_windows_launch_failure_propagates(self):
        with patch.object(browser.shutil, 'which', return_value=None), \
                patch.object(browser.subprocess, 'run',
                             side_effect=subprocess.CalledProcessError(1, 'powershell.exe')), \
                self.assertRaises(subprocess.CalledProcessError):
            browser.open_browser('https://example.com')


if __name__ == '__main__':
    unittest.main()
