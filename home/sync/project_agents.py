"""Ensure pinned Cursor agents appear under <git-root>/.cursor/agents/.

Cursor's Task tool / CLI often only loads project-scoped agents, not
~/.cursor/agents/. Domain term: project-agents (see CONTEXT.md).
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

from sync.common import repo_home
from sync.managed_links import install_links

REPO_HOME = repo_home()
DOTFILES_ROOT = REPO_HOME.parent
GENERATED_AGENTS = REPO_HOME / ".cursor" / "agents"
LIVE_AGENTS = Path.home() / ".cursor" / "agents"
EXCLUDE_LINE = ".cursor/agents/"


def git_root(start: Path | None = None) -> Path | None:
    cwd = start or Path.cwd()
    try:
        out = subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=cwd,
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError, OSError):
        return None
    root = Path(out.strip())
    return root if root.is_dir() else None


def agent_source_dir(root: Path) -> Path | None:
    """Prefer generated in-repo agents when inside this dotfiles tree."""
    try:
        if root.resolve() == DOTFILES_ROOT.resolve() and GENERATED_AGENTS.is_dir():
            return GENERATED_AGENTS
    except OSError:
        pass
    if LIVE_AGENTS.is_dir():
        return LIVE_AGENTS
    if GENERATED_AGENTS.is_dir():
        return GENERATED_AGENTS
    return None


def is_dotfiles_root(root: Path) -> bool:
    try:
        return root.resolve() == DOTFILES_ROOT.resolve()
    except OSError:
        return False


def ensure_git_exclude(root: Path) -> None:
    """Resolve Git's exclusion file, including linked worktrees."""
    if is_dotfiles_root(root):
        return
    raw = subprocess.check_output(
        ["git", "rev-parse", "--git-path", "info/exclude"], cwd=root, text=True,
    ).strip()
    exclude = Path(raw)
    if not exclude.is_absolute():
        exclude = root / exclude
    existing = exclude.read_text(encoding="utf-8") if exclude.is_file() else ""
    if EXCLUDE_LINE in (line.strip() for line in existing.splitlines()):
        return
    exclude.parent.mkdir(parents=True, exist_ok=True)
    prefix = "" if not existing or existing.endswith("\n") else "\n"
    with exclude.open("a", encoding="utf-8") as f:
        f.write(f"{prefix}# pinned Cursor project-agents (managed by ensure-project-agents)\n")
        f.write(f"{EXCLUDE_LINE}\n")


def ensure_project_agents(root: Path | None = None, *, quiet: bool = False) -> int:
    """Link pinned agent .md files into <root>/.cursor/agents/. Returns count of changed links."""
    git_root_path = root or git_root()
    if git_root_path is None:
        if not quiet:
            print("ensure-project-agents: not inside a git repo", file=sys.stderr)
        return 0

    src = agent_source_dir(git_root_path)
    if src is None or not src.is_dir():
        if not quiet:
            print(
                "ensure-project-agents: no agent source "
                f"({LIVE_AGENTS} or {GENERATED_AGENTS})",
                file=sys.stderr,
            )
        return 0

    dest = git_root_path / ".cursor" / "agents"
    paths = sorted(src.glob("*.md"))
    if not paths:
        if not quiet:
            print(f"ensure-project-agents: no *.md in {src}", file=sys.stderr)
        return 0

    linked = install_links(src, dest, "*.md", owned_roots=(GENERATED_AGENTS,))
    ensure_git_exclude(git_root_path)
    if not quiet:
        print(f"  project-agents: {linked} change(s) → {dest}")
    return linked


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    quiet = False
    start: Path | None = None
    for arg in args:
        if arg in ("-q", "--quiet"):
            quiet = True
        elif arg in ("-h", "--help"):
            print(
                "usage: ensure-project-agents [-q|--quiet] [dir]\n"
                "Link pinned Cursor agents into <git-root>/.cursor/agents/ "
                "so Task/CLI can discover them."
            )
            return 0
        elif arg.startswith("-"):
            print(f"ensure-project-agents: unknown flag {arg}", file=sys.stderr)
            return 2
        else:
            start = Path(arg)

    root = git_root(start) if start else git_root()
    if start is not None and root is None:
        # Allow explicit git root path even if cwd isn't inside it.
        candidate = start.resolve()
        if (candidate / ".git").exists() or (candidate / ".git").is_file():
            root = candidate
    ensure_project_agents(root, quiet=quiet)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
