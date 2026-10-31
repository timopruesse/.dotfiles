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


def patch_pstack(agent):
    package = agent / 'npm/node_modules/pi-pstack'
    if not package.exists():
        return
    try:
        manifest = json.loads((package / 'package.json').read_text())
    except (OSError, ValueError) as error:
        raise RuntimeError(f'Cannot read pi-pstack package manifest: {package}') from error
    if not isinstance(manifest, dict) or (manifest.get('name'), manifest.get('version')) != ('pi-pstack', '0.1.0'):
        raise RuntimeError('Review pi-pstack patches for the installed package version')
    path = package / 'extensions/pstack/index.ts'
    text = path.read_text()
    old = 'await ctx.sendUserMessage(`/skill:poteto-mode${args.trim() ? ` ${args.trim()}` : ""}`);'
    new = 'pi.sendUserMessage(`/skill:poteto-mode${args.trim() ? ` ${args.trim()}` : ""}`, { expandPromptTemplates: true });'
    detector = r'''function knownExternalWrite(command: string): string | undefined {
  const patterns: Array<[RegExp, string]> = [
    [/\bgit\s+push\b/, "git push"],
    [/\bgh\s+pr\s+(create|edit|merge|close)\b/, "GitHub pull-request mutation"],
    [/\bgt\s+(submit|merge|create)\b/, "Graphite mutation"],
    [/\b(terraform|tofu)\s+(apply|destroy)\b/, "infrastructure mutation"],
    [/\bkubectl\s+(apply|delete|rollout)\b/, "Kubernetes mutation"],
    [/\b(vercel|flyctl|railway)\s+(deploy|promote)\b/, "deployment"],
    [/\brm\s+(-[A-Za-z]*r|--recursive)/, "recursive deletion"],
  ];
  return patterns.find(([pattern]) => pattern.test(command))?.[1];
}'''
    guard = r'''  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash") return;
    const input = event.input as { command?: string };
    const operation = input.command ? knownExternalWrite(input.command) : undefined;
    if (!operation) return;
    if (!ctx.hasUI) return { block: true, reason: `${operation} requires explicit user confirmation; non-interactive Pi cannot request it.` };
    const approved = await ctx.ui.confirm("Confirm external or irreversible action", `Allow ${operation}?\n\n${input.command}`);
    if (!approved) return { block: true, reason: `User declined ${operation}.` };
  });'''
    exemption = r'''    if (input.command && !/[\x00-\x1f\x7f-\x9f\u2028\u2029]/.test(input.command) &&
        /^ *git +push(?: +(?:-u|--set-upstream) +[a-zA-Z0-9][a-zA-Z0-9._-]* +[a-zA-Z0-9][a-zA-Z0-9._/-]*| +[a-zA-Z0-9][a-zA-Z0-9._-]*(?: +[a-zA-Z0-9][a-zA-Z0-9._/-]*)?)? *$/.test(input.command)) return;
'''
    patched_guard = guard.replace('    const approved =', exemption + '    const approved =')
    patches = [('command', old, new), ('guard', guard, patched_guard)]
    for label, original, patched in patches:
        if (text.count(original), text.count(patched)) not in ((1, 0), (0, 1)):
            raise RuntimeError(f'Unexpected pi-pstack {label} source: {path}')
    if text.count(detector) != 1:
        raise RuntimeError(f'Unexpected pi-pstack guard detector source: {path}')
    updated = text
    for _, original, patched in patches:
        updated = updated.replace(original, patched)
    if updated != text:
        path.write_text(updated)


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
    patch_pstack(agent)

    agent.mkdir(parents=True, exist_ok=True)
    for src, dest in links:
        dest.parent.mkdir(parents=True, exist_ok=True)
        if not dest.is_symlink():
            dest.symlink_to(os.path.relpath(src, dest.parent), target_is_directory=src.is_dir())
    write_settings(settings_path, settings_text)
    print(f'Pi resources and managed defaults installed in {agent}')


if __name__ == '__main__':
    install()
