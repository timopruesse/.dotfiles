"""Reconcile a link set without taking ownership of unrelated live paths."""

from pathlib import Path
import shutil

from sync.common import link_into


def owns_link(path: Path, source: Path) -> bool:
    if not path.is_symlink():
        return False
    try:
        return path.resolve().is_relative_to(source.resolve())
    except (OSError, RuntimeError):
        return False


def install_links(source: Path, destination: Path, pattern: str, *,
                  names: set[str] | None = None, reclaim_skills: bool = False,
                  owned_roots: tuple[Path, ...] = ()) -> int:
    """Preflight one set, install it, and prune only links owned by source.

    Missing sources do not mean an empty desired set. Managed skill names alone
    may replace personal content, without backups, by explicit user policy.
    """
    if not source.is_dir():
        return 0
    paths = sorted(p for p in source.glob(pattern) if names is None or p.name in names)
    roots = (source, *owned_roots)
    for path in paths:
        link = destination / path.name
        try:
            correct = link.is_symlink() and link.resolve() == path.resolve()
        except (OSError, RuntimeError):
            correct = False
        if (not reclaim_skills and not correct
                and (link.exists() or link.is_symlink())
                and not any(owns_link(link, root) for root in roots)):
            raise SystemExit(f"refusing to replace unmanaged path {link}")
    changed = 0
    for path in paths:
        link = destination / path.name
        if reclaim_skills and not link.is_symlink():
            if link.is_dir():
                shutil.rmtree(link)
            elif link.exists():
                link.unlink()
        if link_into(path, link):
            changed += 1
    keep = {p.name for p in paths}
    if destination.is_dir():
        for link in destination.glob(pattern):
            if link.name not in keep and any(owns_link(link, root) for root in roots):
                link.unlink()
                changed += 1
    if changed:
        print(f"  reconciled {changed} managed link change(s) → {destination}")
    return changed
