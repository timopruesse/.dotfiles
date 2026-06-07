#!/bin/sh
# Pin the current pane to the Claude harpoon list (dedup by pane id).
LIST="$HOME/.tmux/claude_harpoon"
pane=$(tmux display-message -p '#{pane_id}')

touch "$LIST"

if grep -qx "$pane" "$LIST"; then
  slot=$(grep -nx "$pane" "$LIST" | cut -d: -f1)
  tmux display-message "Already harpooned — slot $slot"
  exit 0
fi

printf '%s\n' "$pane" >>"$LIST"
slot=$(grep -c . "$LIST")
label=$(tmux display-message -p -t "$pane" '#{session_name}:#{window_index} #{window_name}')
tmux display-message "Harpooned slot $slot → $label"
