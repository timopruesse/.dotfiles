#!/usr/bin/env python3
"""Open in WSL Chrome, or the default Windows browser when Chrome is absent."""
import base64
import shutil
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit


def windows_target(target):
    """Convert Linux paths/file URIs; leave web URLs and other schemes intact."""
    uri = urlsplit(target)
    if uri.scheme and uri.scheme != 'file':
        return target
    if uri.scheme == 'file':
        if uri.netloc not in ('', 'localhost'):
            return target
        target = unquote(uri.path)
    path = str(Path(target).expanduser().resolve())
    return subprocess.check_output(['wslpath', '-aw', path], text=True).strip()


def open_browser(target):
    for name in ('google-chrome', 'google-chrome-stable'):
        chrome = shutil.which(name)
        if chrome:
            # A fresh Chrome process stays running; do not block the caller.
            subprocess.Popen([chrome, target], stdin=subprocess.DEVNULL,
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                             start_new_session=True)
            return 0

    # Encode a quoted literal, not raw -Command arguments: paths/URLs may contain
    # spaces, quotes, Unicode, or PowerShell metacharacters.
    target = windows_target(target).replace("'", "''")
    script = ("$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; "
              "Start-Process -FilePath '" + target + "'")
    encoded = base64.b64encode(script.encode('utf-16le')).decode('ascii')
    subprocess.run(['powershell.exe', '-NoProfile', '-NonInteractive',
                    '-EncodedCommand', encoded], check=True)
    return 0


def main():
    if len(sys.argv) != 2:
        print('Usage: wsl_browser.py <file-or-url>', file=sys.stderr)
        return 2
    try:
        return open_browser(sys.argv[1])
    except (OSError, subprocess.CalledProcessError, ValueError) as error:
        print(f'Browser opening failed: {error}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
