"""Install managed Cursor artifacts into ~/.cursor without replacing the tree."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

from sync.common import deep_merge, link_into, repo_home
from sync.normalize_herdr_hooks import normalize_all

REPO_HOME = repo_home()
SKILLS_SRC = REPO_HOME / "skills"
CURSOR_OUT_AGENTS = REPO_HOME / ".cursor" / "agents"
CURSOR_OUT_COMMANDS = REPO_HOME / ".cursor" / "commands"
AGY_OUT_AGENTS = REPO_HOME / ".agents" / "agents"
AGY_OUT_WORKFLOWS = REPO_HOME / ".agents" / "workflows"
CURSOR_RULES_DIR = REPO_HOME / ".cursor" / "rules"
CURSOR_HOOKS_JSON = REPO_HOME / ".cursor" / "hooks.json"
CURSOR_HOOKS_DIR = REPO_HOME / ".cursor" / "hooks"
AGY_HOOKS_JSON = REPO_HOME / ".gemini" / "hooks.json"
AGY_HOOKS_DIR = REPO_HOME / ".gemini" / "hooks"
CURSOR_CLI_CONFIG = REPO_HOME / ".cursor" / "cli-config.json"
CURSOR_STATUSLINE = REPO_HOME / ".cursor" / "statusline.sh"

LIVE_CURSOR = Path.home() / ".cursor"
LIVE_AGENTS = LIVE_CURSOR / "agents"
LIVE_COMMANDS = LIVE_CURSOR / "commands"
LIVE_RULES = LIVE_CURSOR / "rules"
LIVE_HOOKS_JSON = LIVE_CURSOR / "hooks.json"
LIVE_HOOKS_DIR = LIVE_CURSOR / "hooks"
LIVE_CLI_CONFIG = LIVE_CURSOR / "cli-config.json"
LIVE_STATUSLINE = LIVE_CURSOR / "statusline.sh"
LIVE_CURSOR_SKILLS = LIVE_CURSOR / "skills"
LIVE_CLAUDE_SKILLS = Path.home() / ".claude" / "skills"
LIVE_AGY_CONFIG = Path.home() / ".gemini" / "config"
LIVE_AGY_AGENTS = LIVE_AGY_CONFIG / "agents"
LIVE_AGY_WORKFLOWS = LIVE_AGY_CONFIG / "workflows"
LIVE_AGY_SKILLS = LIVE_AGY_CONFIG / "skills"
LIVE_AGY_HOOKS_JSON = LIVE_AGY_CONFIG / "hooks.json"
LIVE_AGY_HOOKS_DIR = Path.home() / ".gemini" / "hooks"
AGY_STATUSLINE = REPO_HOME / ".gemini" / "statusline.sh"
LIVE_AGY_STATUSLINE = Path.home() / ".gemini" / "statusline.sh"
LIVE_AGY_STATUSLINE_CLI = Path.home() / ".gemini" / "antigravity-cli" / "statusline.sh"
AGY_SETTINGS = REPO_HOME / ".gemini" / "settings.json"
LIVE_AGY_SETTINGS = Path.home() / ".gemini" / "antigravity-cli" / "settings.json"
LIVE_AGENTS_ROOT = Path.home() / ".agents"
LIVE_AGENTS_AGENTS = LIVE_AGENTS_ROOT / "agents"
LIVE_AGENTS_WORKFLOWS = LIVE_AGENTS_ROOT / "workflows"
LIVE_AGENTS_SKILLS = LIVE_AGENTS_ROOT / "skills"
LIVE_AGENTS_HOOKS_JSON = LIVE_AGENTS_ROOT / "hooks.json"


def install_md_links(src_dir: Path, live_dir: Path, keep: set[str] | None = None) -> None:
    if not src_dir.is_dir():
        return
    paths = sorted(src_dir.glob("*.md"))
    if keep is None:
        keep = {p.stem for p in paths}
    for path in paths:
        if path.stem not in keep:
            continue
        link_into(path, live_dir / path.name)
    if live_dir.is_dir():
        for stale in live_dir.glob("*.md"):
            if stale.stem not in keep and stale.is_symlink():
                stale.unlink()
                print(f"  removed stale live link {stale}")


def install_hooks() -> None:
    if CURSOR_HOOKS_JSON.is_file():
        if link_into(CURSOR_HOOKS_JSON, LIVE_HOOKS_JSON):
            print(f"  installed hooks.json → {LIVE_HOOKS_JSON}")
    if CURSOR_HOOKS_DIR.is_dir():
        if link_into(CURSOR_HOOKS_DIR, LIVE_HOOKS_DIR):
            print(f"  installed hooks/ → {LIVE_HOOKS_DIR}")
    if AGY_HOOKS_JSON.is_file():
        if link_into(AGY_HOOKS_JSON, LIVE_AGY_HOOKS_JSON):
            print(f"  installed hooks.json → {LIVE_AGY_HOOKS_JSON}")
        if link_into(AGY_HOOKS_JSON, LIVE_AGENTS_HOOKS_JSON):
            print(f"  installed hooks.json → {LIVE_AGENTS_HOOKS_JSON}")
    if AGY_HOOKS_DIR.is_dir():
        if link_into(AGY_HOOKS_DIR, LIVE_AGY_HOOKS_DIR):
            print(f"  installed hooks/ → {LIVE_AGY_HOOKS_DIR}")
    normalize_all()


def install_rules() -> None:
    """Link every managed `.mdc` rule into ~/.cursor/rules/."""
    if not CURSOR_RULES_DIR.is_dir():
        return
    LIVE_RULES.mkdir(parents=True, exist_ok=True)
    keep: set[str] = set()
    linked = 0
    for path in sorted(CURSOR_RULES_DIR.glob("*.mdc")):
        keep.add(path.name)
        if link_into(path, LIVE_RULES / path.name):
            linked += 1
            print(f"  installed rule → {LIVE_RULES / path.name}")
    if LIVE_RULES.is_dir():
        for stale in LIVE_RULES.glob("*.mdc"):
            if stale.name not in keep and stale.is_symlink():
                stale.unlink()
                print(f"  removed stale live link {stale}")
    if linked == 0 and keep:
        print(f"  ({len(keep)} rules already linked → {LIVE_RULES})")


def install_statusline() -> None:
    """Link the managed CLI statusline script into ~/.cursor/statusline.sh and ~/.gemini/."""
    if CURSOR_STATUSLINE.is_file():
        changed = link_into(CURSOR_STATUSLINE, LIVE_STATUSLINE)
        try:
            CURSOR_STATUSLINE.chmod(CURSOR_STATUSLINE.stat().st_mode | 0o111)
        except OSError:
            pass
        if changed:
            print(f"  installed statusline → {LIVE_STATUSLINE}")

    if AGY_STATUSLINE.is_file():
        c1 = link_into(AGY_STATUSLINE, LIVE_AGY_STATUSLINE)
        c2 = link_into(AGY_STATUSLINE, LIVE_AGY_STATUSLINE_CLI)
        try:
            AGY_STATUSLINE.chmod(AGY_STATUSLINE.stat().st_mode | 0o111)
        except OSError:
            pass
        if c1 or c2:
            print(f"  installed agy statusline → {LIVE_AGY_STATUSLINE}")


def install_cli_config() -> None:
    """Merge managed CLI prefs into ~/.cursor/cli-config.json.

    Cursor writes auth + caches into the live file, so we never symlink it —
    only overlay durable prefs from the repo (approvalMode, sandbox, editor, …).
    """
    if not CURSOR_CLI_CONFIG.is_file():
        return
    managed = json.loads(CURSOR_CLI_CONFIG.read_text())
    live: dict[str, Any] = {}
    if LIVE_CLI_CONFIG.is_file() and not LIVE_CLI_CONFIG.is_symlink():
        try:
            loaded = json.loads(LIVE_CLI_CONFIG.read_text())
            if isinstance(loaded, dict):
                live = loaded
        except json.JSONDecodeError:
            print(
                f"  warning: {LIVE_CLI_CONFIG} is not valid JSON; "
                "rewriting from managed prefs only",
                file=sys.stderr,
            )
    elif LIVE_CLI_CONFIG.is_symlink():
        print(
            f"  warning: refusing to write through symlink {LIVE_CLI_CONFIG}",
            file=sys.stderr,
        )
        return

    merged = deep_merge(live, managed)
    text = json.dumps(merged, indent=2) + "\n"
    if LIVE_CLI_CONFIG.is_file():
        try:
            if LIVE_CLI_CONFIG.read_text() == text:
                return
        except OSError:
            pass
    LIVE_CLI_CONFIG.parent.mkdir(parents=True, exist_ok=True)
    LIVE_CLI_CONFIG.write_text(text)
    print(f"  merged cli-config prefs → {LIVE_CLI_CONFIG}")


def install_agy_settings() -> None:
    """Merge managed settings from home/.gemini/settings.json into live ~/.gemini/antigravity-cli/settings.json."""
    if not AGY_SETTINGS.is_file():
        return
    managed = json.loads(AGY_SETTINGS.read_text())
    live: dict[str, Any] = {}
    if LIVE_AGY_SETTINGS.is_file() and not LIVE_AGY_SETTINGS.is_symlink():
        try:
            loaded = json.loads(LIVE_AGY_SETTINGS.read_text())
            if isinstance(loaded, dict):
                live = loaded
        except json.JSONDecodeError:
            print(
                f"  warning: {LIVE_AGY_SETTINGS} is not valid JSON; "
                "rewriting from managed settings only",
                file=sys.stderr,
            )
    elif LIVE_AGY_SETTINGS.is_symlink():
        print(
            f"  warning: refusing to write through symlink {LIVE_AGY_SETTINGS}",
            file=sys.stderr,
        )
        return

    merged = deep_merge(live, managed)
    text = json.dumps(merged, indent=2) + "\n"
    if LIVE_AGY_SETTINGS.is_file():
        try:
            if LIVE_AGY_SETTINGS.read_text() == text:
                return
        except OSError:
            pass
    LIVE_AGY_SETTINGS.parent.mkdir(parents=True, exist_ok=True)
    LIVE_AGY_SETTINGS.write_text(text)
    print(f"  merged agy settings → {LIVE_AGY_SETTINGS}")


def _managed_skill_dirs() -> list[Path]:
    if not SKILLS_SRC.is_dir():
        return []
    return sorted(
        p
        for p in SKILLS_SRC.iterdir()
        if p.is_dir() and not p.name.startswith(".") and (p / "SKILL.md").is_file()
    )


def _prune_stale_managed_skills(live_root: Path, keep: set[str]) -> None:
    """Remove live skill symlinks that pointed at our managed src but are gone."""
    if not live_root.is_dir():
        return
    src_root = SKILLS_SRC.resolve()
    for entry in live_root.iterdir():
        if entry.name in keep or not entry.is_symlink():
            continue
        try:
            resolved = entry.resolve()
        except OSError:
            continue
        if resolved == src_root or src_root in resolved.parents:
            entry.unlink()
            print(f"  removed stale live skill {entry}")


def install_skills() -> None:
    """Link home/skills/<name> into ~/.cursor/skills, ~/.claude/skills, and ~/.agents/skills.

    Always reclaim managed names (overwrite foreign symlinks).
    Only prunes symlinks that resolve under the managed skills source — leaves
    unrelated personal/plugin skills alone.
    """
    skills = _managed_skill_dirs()
    if not skills:
        return
    keep = {p.name for p in skills}
    roots = [LIVE_CURSOR_SKILLS, LIVE_CLAUDE_SKILLS]
    seen = {p.resolve() for p in roots if p.exists()}
    for candidate in (LIVE_AGENTS_SKILLS, LIVE_AGY_SKILLS):
        try:
            cand_res = candidate.resolve()
        except OSError:
            cand_res = candidate
        if cand_res not in seen:
            roots.append(candidate)
            seen.add(cand_res)

    for live_root in roots:
        linked = 0
        reclaimed = 0
        for skill_dir in skills:
            dest = live_root / skill_dir.name
            if dest.is_symlink():
                try:
                    if dest.resolve() != skill_dir.resolve():
                        reclaimed += 1
                        dest.unlink()
                except OSError:
                    reclaimed += 1
                    dest.unlink()
            elif dest.is_dir():
                import shutil
                shutil.rmtree(dest)
                reclaimed += 1
            if link_into(skill_dir, dest):
                linked += 1
        _prune_stale_managed_skills(live_root, keep)
        if reclaimed:
            print(f"  reclaimed {reclaimed} skill link(s) → {live_root}")
        if linked:
            print(f"  linked {linked}/{len(keep)} skills → {live_root}")
        else:
            print(f"  ({len(keep)} skills already linked → {live_root})")


def install_all(
    *,
    agents: bool = True,
    commands: bool = True,
    hooks: bool = True,
    rule: bool = True,
    cli_config: bool = True,
    statusline: bool = True,
    skills: bool = True,
) -> None:
    if agents and CURSOR_OUT_AGENTS.is_dir():
        keep = {p.stem for p in CURSOR_OUT_AGENTS.glob("*.md")}
        install_md_links(CURSOR_OUT_AGENTS, LIVE_AGENTS, keep)
        print(f"  linked {len(keep)} agents → {LIVE_AGENTS}")
    if agents and AGY_OUT_AGENTS.is_dir():
        keep = {p.stem for p in AGY_OUT_AGENTS.glob("*.md")}
        for target in (LIVE_AGY_AGENTS, LIVE_AGENTS_AGENTS):
            install_md_links(AGY_OUT_AGENTS, target, keep)
            print(f"  linked {len(keep)} agy agents → {target}")
    if commands and CURSOR_OUT_COMMANDS.is_dir():
        keep = {p.stem for p in CURSOR_OUT_COMMANDS.glob("*.md")}
        install_md_links(CURSOR_OUT_COMMANDS, LIVE_COMMANDS, keep)
        print(f"  linked {len(keep)} commands → {LIVE_COMMANDS}")
    if commands and AGY_OUT_WORKFLOWS.is_dir():
        keep = {p.stem for p in AGY_OUT_WORKFLOWS.glob("*.md")}
        for target in (LIVE_AGY_WORKFLOWS, LIVE_AGENTS_WORKFLOWS):
            install_md_links(AGY_OUT_WORKFLOWS, target, keep)
            print(f"  linked {len(keep)} agy workflows → {target}")
    if skills:
        install_skills()
    if rule:
        install_rules()
    if hooks:
        install_hooks()
    if statusline:
        install_statusline()
    if cli_config:
        install_cli_config()
        install_agy_settings()


def main() -> int:
    install_all()
    print(f"live-install → {LIVE_CURSOR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
