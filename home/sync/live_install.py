"""Install managed host artifacts without replacing personal configuration."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

from sync.common import deep_merge, link_into, repo_home
from sync.live_codex import install_codex_agents
from sync.managed_links import install_links
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
CURSOR_GITHUB_MCP = REPO_HOME / ".cursor" / "github-mcp.sh"
CURSOR_MCP_JSON = REPO_HOME / ".cursor" / "mcp.json"
AGY_MCP_CONFIG = REPO_HOME / ".gemini" / "mcp_config.json"

LIVE_CURSOR = Path.home() / ".cursor"
LIVE_AGENTS = LIVE_CURSOR / "agents"
LIVE_COMMANDS = LIVE_CURSOR / "commands"
LIVE_RULES = LIVE_CURSOR / "rules"
LIVE_HOOKS_JSON = LIVE_CURSOR / "hooks.json"
LIVE_HOOKS_DIR = LIVE_CURSOR / "hooks"
LIVE_CLI_CONFIG = LIVE_CURSOR / "cli-config.json"
LIVE_STATUSLINE = LIVE_CURSOR / "statusline.sh"
LIVE_GITHUB_MCP = LIVE_CURSOR / "github-mcp.sh"
LIVE_CURSOR_MCP_JSON = LIVE_CURSOR / "mcp.json"
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
LIVE_AGY_MCP_CONFIG = LIVE_AGY_CONFIG / "mcp_config.json"
LIVE_AGENTS_ROOT = Path.home() / ".agents"
LIVE_AGENTS_AGENTS = LIVE_AGENTS_ROOT / "agents"
LIVE_AGENTS_WORKFLOWS = LIVE_AGENTS_ROOT / "workflows"
LIVE_AGENTS_SKILLS = LIVE_AGENTS_ROOT / "skills"
LIVE_AGENTS_HOOKS_JSON = LIVE_AGENTS_ROOT / "hooks.json"


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
    install_links(CURSOR_RULES_DIR, LIVE_RULES, "*.mdc")


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


def install_github_mcp() -> None:
    """Link the GitHub MCP Docker wrapper into ~/.cursor/github-mcp.sh."""
    if not CURSOR_GITHUB_MCP.is_file():
        return
    changed = link_into(CURSOR_GITHUB_MCP, LIVE_GITHUB_MCP)
    try:
        CURSOR_GITHUB_MCP.chmod(CURSOR_GITHUB_MCP.stat().st_mode | 0o111)
    except OSError:
        pass
    if changed:
        print(f"  installed github-mcp → {LIVE_GITHUB_MCP}")


def _merge_json_file(managed_path: Path, live_path: Path, label: str) -> None:
    """Merge JSON from managed_path into live_path via deep_merge."""
    if not managed_path.is_file():
        return
    managed = json.loads(managed_path.read_text())
    live: dict[str, Any] = {}
    if live_path.is_file() and not live_path.is_symlink():
        try:
            loaded = json.loads(live_path.read_text())
            if isinstance(loaded, dict):
                live = loaded
        except json.JSONDecodeError:
            print(
                f"  warning: {live_path} is not valid JSON; "
                f"rewriting from managed {label} only",
                file=sys.stderr,
            )
    elif live_path.is_symlink():
        print(
            f"  warning: refusing to write through symlink {live_path}",
            file=sys.stderr,
        )
        return

    merged = deep_merge(live, managed)
    text = json.dumps(merged, indent=2) + "\n"
    if live_path.is_file():
        try:
            if live_path.read_text() == text:
                return
        except OSError:
            pass
    live_path.parent.mkdir(parents=True, exist_ok=True)
    live_path.write_text(text)
    print(f"  merged {label} → {live_path}")


def install_cli_config() -> None:
    """Merge managed CLI prefs into ~/.cursor/cli-config.json.

    Cursor writes auth + caches into the live file, so we never symlink it —
    only overlay durable prefs from the repo (approvalMode, sandbox, editor, …).
    """
    _merge_json_file(CURSOR_CLI_CONFIG, LIVE_CLI_CONFIG, "cli-config prefs")


def install_agy_settings() -> None:
    """Merge managed settings from home/.gemini/settings.json into live ~/.gemini/antigravity-cli/settings.json."""
    _merge_json_file(AGY_SETTINGS, LIVE_AGY_SETTINGS, "agy settings")


def install_mcp_config() -> None:
    """Merge managed MCP server configurations into live ~/.gemini/config/mcp_config.json and ~/.cursor/mcp.json."""
    _merge_json_file(AGY_MCP_CONFIG, LIVE_AGY_MCP_CONFIG, "agy mcp_config")
    _merge_json_file(CURSOR_MCP_JSON, LIVE_CURSOR_MCP_JSON, "cursor mcp")


def _managed_skill_dirs() -> list[Path]:
    if not SKILLS_SRC.is_dir():
        return []
    return sorted(
        p
        for p in SKILLS_SRC.iterdir()
        if p.is_dir() and not p.name.startswith(".") and (p / "SKILL.md").is_file()
    )


def install_skills() -> None:
    """Link home/skills/<name> into ~/.cursor/skills, ~/.claude/skills, and ~/.agents/skills.

    Always reclaim managed names (overwrite foreign symlinks).
    Only prunes symlinks that resolve under the managed skills source — leaves
    unrelated personal/plugin skills alone.
    """
    skills = _managed_skill_dirs()
    if not SKILLS_SRC.is_dir():
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
        install_links(SKILLS_SRC, live_root, "*", names=keep, reclaim_skills=True)


def install_all() -> None:
    install_codex_agents()
    for source, targets in (
        (CURSOR_OUT_AGENTS, (LIVE_AGENTS,)),
        (AGY_OUT_AGENTS, (LIVE_AGY_AGENTS, LIVE_AGENTS_AGENTS)),
        (CURSOR_OUT_COMMANDS, (LIVE_COMMANDS,)),
        (AGY_OUT_WORKFLOWS, (LIVE_AGY_WORKFLOWS, LIVE_AGENTS_WORKFLOWS)),
    ):
        for target in targets:
            install_links(source, target, "*.md")
    install_skills()
    install_rules()
    install_hooks()
    install_statusline()
    install_github_mcp()
    install_cli_config()
    install_agy_settings()
    install_mcp_config()
