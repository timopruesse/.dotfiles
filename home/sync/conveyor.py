"""Single sync conveyor: generate → catalog → live-install → project-agents."""

from __future__ import annotations

import sys

from sync.agents import sync_agents
from sync.catalog import generate_catalog
from sync.codex_hooks import repair_codex_hooks
from sync.codex_instructions import generate_codex_instructions, install_codex_instructions
from sync.commands import sync_commands
from sync.live_cursor import install_all
from sync.project_agents import DOTFILES_ROOT, ensure_project_agents


def run_sync() -> int:
    """Generate agents+commands, emit catalog, full live-install, project-agents."""
    rc = sync_agents()
    if rc != 0:
        return rc
    rc = sync_commands()
    if rc != 0:
        return rc
    generate_catalog()
    generate_codex_instructions()
    install_all()
    repair_codex_hooks()
    install_codex_instructions()
    ensure_project_agents(DOTFILES_ROOT, quiet=False)
    print("sync conveyor complete", flush=True)
    return 0


def main(argv: list[str] | None = None) -> int:
    args = argv if argv is not None else sys.argv[1:]
    if args in (["-h"], ["--help"]):
        print(
            "usage: home/sync/sync\n"
            "  generate agents+commands → catalog → live-install → project-agents",
            file=sys.stderr,
        )
        return 0
    if args:
        print(f"sync: unexpected arguments: {args!r}", file=sys.stderr)
        print("usage: home/sync/sync", file=sys.stderr)
        return 2
    return run_sync()


if __name__ == "__main__":
    raise SystemExit(main())
