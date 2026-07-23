"""Install managed Cursor artifacts into ~/.cursor without replacing the tree."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

from sync.common import deep_merge, link_into, repo_home

REPO_HOME = repo_home()
SKILLS_SRC = REPO_HOME / "skills"
CURSOR_OUT_AGENTS = REPO_HOME / ".cursor" / "agents"
CURSOR_OUT_COMMANDS = REPO_HOME / ".cursor" / "commands"
CURSOR_RULE = REPO_HOME / ".cursor" / "rules" / "subagent-model-fallback.mdc"
CURSOR_HOOKS_JSON = REPO_HOME / ".cursor" / "hooks.json"
CURSOR_HOOKS_DIR = REPO_HOME / ".cursor" / "hooks"
CURSOR_CLI_CONFIG = REPO_HOME / ".cursor" / "cli-config.json"

LIVE_CURSOR = Path.home() / ".cursor"
LIVE_AGENTS = LIVE_CURSOR / "agents"
LIVE_COMMANDS = LIVE_CURSOR / "commands"
LIVE_RULES = LIVE_CURSOR / "rules"
LIVE_HOOKS_JSON = LIVE_CURSOR / "hooks.json"
LIVE_HOOKS_DIR = LIVE_CURSOR / "hooks"
LIVE_CLI_CONFIG = LIVE_CURSOR / "cli-config.json"
LIVE_CURSOR_SKILLS = LIVE_CURSOR / "skills"
LIVE_CLAUDE_SKILLS = Path.home() / ".claude" / "skills"


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
        link_into(CURSOR_HOOKS_JSON, LIVE_HOOKS_JSON)
        print(f"  installed hooks.json → {LIVE_HOOKS_JSON}")
    if CURSOR_HOOKS_DIR.is_dir():
        link_into(CURSOR_HOOKS_DIR, LIVE_HOOKS_DIR)
        print(f"  installed hooks/ → {LIVE_HOOKS_DIR}")


def install_rule() -> None:
    if CURSOR_RULE.is_file():
        link_into(CURSOR_RULE, LIVE_RULES / CURSOR_RULE.name)
        print(f"  installed rule → {LIVE_RULES / CURSOR_RULE.name}")


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
    LIVE_CLI_CONFIG.parent.mkdir(parents=True, exist_ok=True)
    LIVE_CLI_CONFIG.write_text(json.dumps(merged, indent=2) + "\n")
    print(f"  merged cli-config prefs → {LIVE_CLI_CONFIG}")


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
    """Link home/skills/<name> into ~/.cursor/skills and ~/.claude/skills.

    Only prunes symlinks that resolve under the managed skills source — leaves
    unrelated personal/plugin skills alone.
    """
    skills = _managed_skill_dirs()
    if not skills:
        return
    keep = {p.name for p in skills}
    for live_root in (LIVE_CURSOR_SKILLS, LIVE_CLAUDE_SKILLS):
        for skill_dir in skills:
            link_into(skill_dir, live_root / skill_dir.name)
        _prune_stale_managed_skills(live_root, keep)
        print(f"  linked {len(keep)} skills → {live_root}")


def install_all(
    *,
    agents: bool = True,
    commands: bool = True,
    hooks: bool = True,
    rule: bool = True,
    cli_config: bool = True,
    skills: bool = True,
) -> None:
    if agents and CURSOR_OUT_AGENTS.is_dir():
        keep = {p.stem for p in CURSOR_OUT_AGENTS.glob("*.md")}
        install_md_links(CURSOR_OUT_AGENTS, LIVE_AGENTS, keep)
        print(f"  linked {len(keep)} agents → {LIVE_AGENTS}")
    if commands and CURSOR_OUT_COMMANDS.is_dir():
        keep = {p.stem for p in CURSOR_OUT_COMMANDS.glob("*.md")}
        install_md_links(CURSOR_OUT_COMMANDS, LIVE_COMMANDS, keep)
        print(f"  linked {len(keep)} commands → {LIVE_COMMANDS}")
    if skills:
        install_skills()
    if rule:
        install_rule()
    if hooks:
        install_hooks()
    if cli_config:
        install_cli_config()


def main() -> int:
    install_all()
    print(f"live-install → {LIVE_CURSOR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
