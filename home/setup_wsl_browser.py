#!/usr/bin/env python3
import os
import subprocess
import sys
from pathlib import Path

DESKTOP_ID = 'dotfiles-wsl-browser.desktop'
WEB_TYPES = ('x-scheme-handler/http', 'x-scheme-handler/https')


def is_wsl():
    if os.environ.get('WSL_DISTRO_NAME'):
        return True
    try:
        return 'microsoft' in Path('/proc/version').read_text().lower()
    except OSError:
        return False


def main():
    if not is_wsl():
        return 0
    bridge = Path(__file__).resolve().parent / '.config/zsh/wsl_browser.py'
    if not bridge.is_file():
        raise FileNotFoundError(f'Windows browser bridge not found: {bridge}')
    launcher = Path.home() / '.local/bin/dotfiles-wsl-browser'
    launcher.parent.mkdir(parents=True, exist_ok=True)
    if launcher.is_symlink() and launcher.readlink() != bridge:
        launcher.unlink()
    if not launcher.is_symlink():
        launcher.symlink_to(bridge)
    data_home = Path(os.environ.get('XDG_DATA_HOME') or Path.home() / '.local/share')
    applications = data_home / 'applications'
    applications.mkdir(parents=True, exist_ok=True)
    desktop = applications / DESKTOP_ID
    content = (
        '[Desktop Entry]\n'
        'Type=Application\n'
        'Name=Windows default browser\n'
        'Exec=dotfiles-wsl-browser %u\n'
        'Terminal=false\n'
        'NoDisplay=true\n'
        f'MimeType={";".join(WEB_TYPES)};\n'
    )
    if not desktop.exists() or desktop.read_text(encoding='utf-8') != content:
        desktop.write_text(content, encoding='utf-8')
    for mime_type in WEB_TYPES:
        subprocess.run(['xdg-mime', 'default', DESKTOP_ID, mime_type], check=True)
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (OSError, subprocess.CalledProcessError) as error:
        print(f'WSL browser setup failed: {error}', file=sys.stderr)
        sys.exit(1)
