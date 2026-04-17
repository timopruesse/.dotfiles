#!/usr/bin/env bash
# Rewrites pane_current_path in a tmux-resurrect save file so paths survive
# restore even after ephemeral dirs (like Claude worktrees) are gone.
#
# - /.../.claude/worktrees/<name> -> /... (the repo root that owns the worktrees)
# - any path that no longer exists -> nearest existing ancestor (fallback: $HOME)

set -eu

file="${1:-}"
[ -n "$file" ] && [ -f "$file" ] || exit 0

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

awk -v home="$HOME" '
BEGIN { FS = OFS = "\t" }
function nearest_existing(p,    cmd, rc) {
  while (p != "" && p != "/") {
    cmd = "test -d " shellesc(p)
    rc = system(cmd)
    if (rc == 0) return p
    sub(/\/[^\/]*$/, "", p)
  }
  return home
}
function shellesc(s,    r) {
  r = s
  gsub(/'\''/, "'\''\\'\'''\''", r)
  return "'\''" r "'\''"
}
$1 == "pane" {
  dir = $8
  leading = ""
  if (substr(dir, 1, 1) == ":") { leading = ":"; dir = substr(dir, 2) }
  n = index(dir, "/.claude/worktrees/")
  if (n > 0) dir = substr(dir, 1, n - 1)
  dir = nearest_existing(dir)
  $8 = leading dir
}
{ print }
' "$file" > "$tmp"

cat "$tmp" > "$file"
