#!/usr/bin/env python3
"""Merge managed Herdr app preferences without owning app state."""
import json
import os
import shutil
import sys
import tempfile
from pathlib import Path


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
    target = Path(os.environ.get('HERDR_APP_HOME') or Path.home() / '.config/herdr-app')
    pending = []
    for name in ('settings.json', 'keys.json'):
        path = target / name
        if path.is_symlink():
            raise ValueError(f'Herdr app preferences must not be symlinks: {path}')
        existing = read_object(path) if path.exists() else {}
        merged = merge_preferences(existing, read_object(source / name), str(path))
        if json.dumps(merged, sort_keys=True) != json.dumps(existing, sort_keys=True):
            pending.append((path, json.dumps(merged, indent=2) + '\n'))
    if pending:
        target.mkdir(parents=True, exist_ok=True)
        for path, text in pending:
            write_preferences(path, text)
    print(f'Herdr app preferences applied in {target}')


if __name__ == '__main__':
    try:
        install()
    except (OSError, ValueError) as error:
        sys.exit(f'Cannot apply Herdr app preferences: {error}')
