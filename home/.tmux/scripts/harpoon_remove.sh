#!/bin/sh
# Remove a pane id from the harpoon list (used by the menu's ctrl-x binding).
LIST="$HOME/.tmux/claude_harpoon"
pane=$1
[ -f "$LIST" ] || exit 0
[ -z "$pane" ] && exit 0
# Note: grep -v exits 1 when nothing matches (i.e. removing the last entry),
# so don't gate the mv on its exit status.
grep -vx "$pane" "$LIST" >"$LIST.tmp"
mv "$LIST.tmp" "$LIST"
