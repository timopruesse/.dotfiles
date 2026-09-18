"""Install only managed native Codex agents; never modify session config."""

from pathlib import Path

from sync.common import repo_home
from sync.managed_links import install_links

CODEX_OUT = repo_home() / ".codex" / "agents"
LIVE_CODEX_AGENTS = Path.home() / ".codex" / "agents"


def install_codex_agents(src_dir: Path = CODEX_OUT, live_dir: Path = LIVE_CODEX_AGENTS) -> None:
    install_links(src_dir, live_dir, "*.toml")
