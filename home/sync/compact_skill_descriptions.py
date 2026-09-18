#!/usr/bin/env python3
"""Apply curated descriptions to an explicit Codex skills/list inventory."""
import argparse
import json
from pathlib import Path
import re

# A top-level YAML field ends at the next non-indented line.
DESCRIPTION = re.compile(r"^description:[^\n]*(?:\n[ \t]+[^\n]*)*", re.MULTILINE)


def compact(text: str, description: str, original: str) -> str:
    parts = text.split("---\n", 2)
    if len(parts) != 3 or parts[0]:
        raise ValueError("missing YAML frontmatter")
    frontmatter, body = parts[1:]
    matches = list(DESCRIPTION.finditer(frontmatter))
    if len(matches) != 1:
        raise ValueError("expected one description field")
    match = matches[0]
    replacement = 'description: ' + json.dumps(description, ensure_ascii=False)
    if match.group() == replacement:
        return text
    frontmatter = frontmatter[:match.start()] + replacement + frontmatter[match.end():]
    if original != description:
        # Detailed triggers remain available when Codex opens the skill.
        body = '\n## Detailed scope\n\n' + original + '\n' + body
    return '---\n' + frontmatter + '---\n' + body


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--inventory', required=True, type=Path,
                        help='JSON response from Codex app-server skills/list')
    parser.add_argument('--apply', action='store_true', help='write changes (default: preview)')
    args = parser.parse_args()
    descriptions = json.loads(Path(__file__).with_name('skill_descriptions.json').read_text())
    inventory = json.loads(args.inventory.read_text())['result']['data']
    changes = {}
    for group in inventory:
        for skill in group['skills']:
            new = descriptions.get(skill['name'])
            if not skill.get('enabled', True) or new is None:
                continue
            path = Path(skill['path']).resolve(strict=True)
            old_text = path.read_text()
            new_text = compact(old_text, new, skill['description'])
            if old_text != new_text:
                changes[path] = (old_text, new_text)
    for path, (old_text, new_text) in changes.items():
        print(path)
        if args.apply:
            if path.read_text() != old_text:
                raise RuntimeError(f'{path} changed during preview')
            path.write_text(new_text)
    print(f'{"Updated" if args.apply else "Would update"} {len(changes)} skills')


if __name__ == '__main__':
    main()
