"""Install managed Codex role files; role loading rejects symlinks (ELOOP)."""

import os
from pathlib import Path
import tempfile

from sync.agents import CODEX_BANNER
from sync.common import repo_home
from sync.managed_links import owns_link

CODEX_OUT = repo_home() / ".codex" / "agents"
LIVE_CODEX_AGENTS = Path.home() / ".codex" / "agents"


def _owned(path: Path, source: Path) -> bool:
    if path.is_symlink():
        return owns_link(path, source)
    return path.is_file() and path.read_bytes().startswith(CODEX_BANNER.encode())


def install_codex_agents(src_dir: Path = CODEX_OUT, live_dir: Path = LIVE_CODEX_AGENTS) -> None:
    """Preflight the set, migrate owned links, and atomically refresh managed copies.

    The generated banner marks owned regular files. Unrelated paths and the
    user's session config are never replaced. A missing source is not an empty set.
    """
    if not src_dir.is_dir():
        return
    if src_dir.resolve() == live_dir.resolve():
        raise SystemExit("Codex source and live agent directories must differ")
    contents = {p.name: p.read_bytes() for p in sorted(src_dir.glob("*.toml"))}
    for name, content in contents.items():
        if not content.startswith(CODEX_BANNER.encode()):
            raise SystemExit(f"missing generated banner in {src_dir / name}")
        path = live_dir / name
        if (path.exists() or path.is_symlink()) and not _owned(path, src_dir):
            raise SystemExit(f"refusing to replace unmanaged path {path}")
    live_dir.mkdir(parents=True, exist_ok=True)
    changed = 0
    for name, content in contents.items():
        path = live_dir / name
        if not path.is_symlink() and path.is_file() and path.read_bytes() == content:
            continue
        fd, temporary = tempfile.mkstemp(dir=live_dir, prefix=f".{name}-")
        try:
            with os.fdopen(fd, "wb") as stream:
                stream.write(content)
            os.replace(temporary, path)
        finally:
            Path(temporary).unlink(missing_ok=True)
        changed += 1
    for path in live_dir.glob("*.toml"):
        if path.name not in contents and _owned(path, src_dir):
            path.unlink()
            changed += 1
    if changed:
        print(f"  installed {changed} managed Codex agent change(s) → {live_dir}")
