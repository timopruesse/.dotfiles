#!/usr/bin/env bash
# Prune stale git worktrees under ~/worktrees/<repo>/ for the current repo.
#
# A worktree is removed only when its branch has a configured upstream whose
# remote-tracking ref no longer exists after `fetch --prune` (git's "[gone]":
# pushed, then the remote branch was deleted, i.e. the PR merged) AND the tree is
# clean. Branches with no upstream (never pushed) and live upstreams are kept;
# dirty trees are skipped and reported. "Merged into main" is deliberately not
# used as a signal: a fresh branch with no commits is trivially an ancestor of
# main and would be pruned right after scaffolding.
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
repo="$(basename "$root")"
dir="${WORKTREES_DIR:-$HOME/worktrees}/$repo"

git -C "$root" fetch --prune --quiet

if [ ! -d "$dir" ]; then
  echo "no worktrees under $dir"
  exit 0
fi

for wt in "$dir"/*/; do
  wt="${wt%/}"
  [ -e "$wt/.git" ] || continue
  branch="$(git -C "$wt" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
  if [ -z "$branch" ]; then
    echo "keep   $wt  (detached HEAD)"
    continue
  fi
  remote="$(git -C "$wt" config "branch.$branch.remote" || true)"
  merge="$(git -C "$wt" config "branch.$branch.merge" || true)"
  if [ -z "$remote" ] || [ -z "$merge" ]; then
    echo "keep   $wt  ($branch: no upstream — never pushed)"
    continue
  fi
  tracking="refs/remotes/$remote/${merge#refs/heads/}"
  if git -C "$wt" show-ref --verify --quiet "$tracking"; then
    echo "keep   $wt  ($branch: upstream live)"
    continue
  fi
  if [ -n "$(git -C "$wt" status --porcelain)" ]; then
    echo "skip   $wt  ($branch: upstream gone, but the tree has uncommitted changes)"
    continue
  fi
  git -C "$root" worktree remove "$wt"
  echo "pruned $wt  ($branch: upstream gone)"
done

git -C "$root" worktree prune
