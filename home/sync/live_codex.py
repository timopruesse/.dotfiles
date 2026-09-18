"""Install only managed native Codex agents; never modify session config."""

from pathlib import Path

from sync.common import link_into, repo_home

CODEX_OUT = repo_home() / ".codex" / "agents"
LIVE_CODEX_AGENTS = Path.home() / ".codex" / "agents"


def install_codex_agents(src_dir: Path = CODEX_OUT, live_dir: Path = LIVE_CODEX_AGENTS) -> None:
    if not src_dir.is_dir():
        return
    paths = sorted(src_dir.glob("*.toml"))
    # Preflight all collisions before changing any live links.
    for path in paths:
        link = live_dir / path.name
        if link.is_symlink():
            if link.resolve().parent != src_dir.resolve():
                raise SystemExit(f"refusing to replace unmanaged Codex agent link {link}")
        elif link.exists():
            raise SystemExit(f"refusing to replace unmanaged Codex agent file {link}")
    for path in paths:
        link_into(path, live_dir / path.name)
    keep = {path.name for path in paths}
    if live_dir.is_dir():
        for stale in live_dir.glob("*.toml"):
            if (stale.name not in keep and stale.is_symlink()
                    and stale.resolve().parent == src_dir.resolve()):
                stale.unlink()
