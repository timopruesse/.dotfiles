#!/usr/bin/env python3
"""Install managed Herdr app preferences and resources, never app state."""
import json
import os
import shutil
import sys
import tempfile
from pathlib import Path

OWNED_RESOURCES = (
    'mods/dotfiles-spaces/grouping.js',
    'mods/dotfiles-spaces/mod.json',
    'mods/dotfiles-spaces/main.js',
    'layouts/dotfiles-main.json',
)


def validate_path(path):
    for parent in (path, *path.parents):
        if parent.is_symlink():
            raise ValueError(f'Herdr app managed paths must not be symlinks: {parent}')
        if parent.exists():
            if parent == path:
                if not parent.is_file():
                    raise ValueError(f'Expected regular file: {parent}')
            elif not parent.is_dir():
                raise ValueError(f'Expected directory: {parent}')


def merge_preferences(existing, managed, location):
    result = dict(existing)
    for key, value in managed.items():
        if isinstance(value, dict):
            section = existing.get(key, {})
            if not isinstance(section, dict):
                raise ValueError(f'Expected JSON object at {location}.{key}')
            result[key] = merge_preferences(section, value, f'{location}.{key}')
        else:
            result[key] = value
    return result


def read_object(path):
    try:
        value = json.loads(path.read_text(encoding='utf-8'))
    except (OSError, ValueError) as error:
        raise ValueError(f'Cannot read JSON preferences in {path}: {error}') from error
    if not isinstance(value, dict):
        raise ValueError(f'Expected JSON object in {path}')
    return value


def write_preferences(path, text):
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o600
    fd, temporary = tempfile.mkstemp(dir=path.parent, prefix=f'.{path.name}-')
    try:
        with os.fdopen(fd, 'w', encoding='utf-8') as stream:
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, mode)
        if path.exists():
            backup_fd, backup = tempfile.mkstemp(dir=path.parent, prefix=f'{path.name}.backup-')
            os.close(backup_fd)
            shutil.copy2(path, backup)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def install():
    source = Path(__file__).resolve().parent / 'herdr-app'
    target = Path(os.environ.get('HERDR_APP_HOME') or Path.home() / '.config/herdr-app').absolute()
    pending = []
    for name in ('settings.json', 'keys.json'):
        path = target / name
        validate_path(path)
        validate_path(source / name)
        existing = read_object(path) if path.exists() else {}
        merged = merge_preferences(existing, read_object(source / name), str(path))
        if json.dumps(merged, sort_keys=True) != json.dumps(existing, sort_keys=True):
            pending.append((path, json.dumps(merged, indent=2) + '\n'))
    for name in OWNED_RESOURCES:
        path = target / name
        resource = source / name
        validate_path(path)
        validate_path(resource)
        text = resource.read_text(encoding='utf-8')
        if not text.strip():
            raise ValueError(f'Empty Herdr app resource: {resource}')
        if resource.suffix == '.json':
            read_object(resource)
        if not path.exists() or path.read_bytes() != text.encode('utf-8'):
            pending.append((path, text))
    for path, text in pending:
        path.parent.mkdir(parents=True, exist_ok=True)
        write_preferences(path, text)
    print(f'Herdr app preferences and owned resources applied in {target}')


if __name__ == '__main__':
    try:
        install()
    except (OSError, ValueError) as error:
        sys.exit(f'Cannot apply Herdr app preferences: {error}')
