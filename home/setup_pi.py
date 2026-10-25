#!/usr/bin/env python3
"""Link Pi resources and merge managed defaults, preserving unrelated state."""
import json
import os
import tempfile
from pathlib import Path


def merge_defaults(settings, defaults, path='settings'):
    """Own only declared leaves; reject malformed managed sections without clobbering them."""
    result = dict(settings)
    for key, value in defaults.items():
        if isinstance(value, dict):
            existing = settings.get(key, {})
            if not isinstance(existing, dict):
                raise RuntimeError(f'invalid Pi settings object: {path}.{key}')
            result[key] = merge_defaults(existing, value, f'{path}.{key}')
        else:
            result[key] = value
    return result


def prepare_settings(path, defaults_path):
    """Validate and merge before any resources or settings files are changed."""
    if path.is_symlink():
        raise RuntimeError(f'Pi settings must be machine-local, not a symlink: {path}')
    try:
        settings = json.loads(path.read_text()) if path.exists() else {}
        defaults = json.loads(defaults_path.read_text())
    except (OSError, ValueError) as error:
        raise RuntimeError(f'Cannot read Pi settings/defaults for {path}') from error
    if not isinstance(settings, dict) or not isinstance(defaults, dict):
        raise RuntimeError(f'invalid Pi settings: {path}')
    return json.dumps(merge_defaults(settings, defaults), indent=2) + '\n'


def write_settings(path, text):
    """Atomically publish only changed settings, preserving existing permissions."""
    if path.exists() and path.read_text() == text:
        return
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o600
    fd, temporary = tempfile.mkstemp(dir=path.parent, prefix='.settings-')
    try:
        with os.fdopen(fd, 'w') as stream:
            stream.write(text)
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def install(home=None, source=None):
    home = Path(home) if home is not None else Path.home()
    source = Path(source) if source is not None else Path(__file__).resolve().parent
    agent = home / '.pi/agent'
    resources = source / '.pi/agent'
    links = [(resources / 'AGENTS.md', agent / 'AGENTS.md')]
    links.extend((p, agent / 'prompts' / p.name) for p in sorted((resources / 'prompts').glob('*.md')))
    links.extend((p, agent / 'agents' / p.name) for p in sorted((resources / 'agents').glob('*.md')))
    links.extend((source / 'skills' / name, agent / 'skills' / name)
                 for name in ('herdr', 'improve-codebase-architecture'))

    # Preflight every destination before changing anything. Never replace personal files.
    for src, dest in links:
        if not src.exists():
            raise RuntimeError(f'missing Pi resource: {src}')
        if (dest.exists() or dest.is_symlink()) and not (
                dest.is_symlink() and dest.resolve() == src.resolve()):
            raise RuntimeError(f'Pi resource collision: {dest}; move or merge it first')
    settings_path = agent / 'settings.json'
    settings_text = prepare_settings(settings_path, resources / 'settings.defaults.json')

    agent.mkdir(parents=True, exist_ok=True)
    for src, dest in links:
        dest.parent.mkdir(parents=True, exist_ok=True)
        if not dest.is_symlink():
            dest.symlink_to(os.path.relpath(src, dest.parent), target_is_directory=src.is_dir())
    write_settings(settings_path, settings_text)
    print(f'Pi resources and managed defaults installed in {agent}')


if __name__ == '__main__':
    install()
