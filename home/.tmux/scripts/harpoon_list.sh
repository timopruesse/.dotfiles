#!/bin/sh
# Print the harpoon list with live status, pruning panes that no longer exist.
# Output is tab-separated: <slot>\t<marker>\t<pane_id>\t<label>
#   pane_id (field 3) is hidden in the menu; used to jump/remove.

. "$(dirname "$0")/claude_status.sh"

LIST="$HOME/.tmux/claude_harpoon"
[ -f "$LIST" ] || exit 0

# Prune dead panes.
alive=$(tmux list-panes -a -F '#{pane_id}')
: >"$LIST.tmp"
while IFS= read -r pane; do
  [ -z "$pane" ] && continue
  printf '%s\n' "$alive" | grep -qx "$pane" && printf '%s\n' "$pane" >>"$LIST.tmp"
done <"$LIST"
mv "$LIST.tmp" "$LIST"

# Print remaining slots with status.
n=0
while IFS= read -r pane; do
  n=$((n + 1))
  marker=$(claude_status_marker "$pane")
  label=$(tmux display-message -p -t "$pane" '#{session_name}:#{window_index} #{window_name} (#{b:pane_current_path})')
  printf '%d\t%s\t%s\t%s\n' "$n" "$marker" "$pane" "$label"
done <"$LIST"
