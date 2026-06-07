#!/bin/sh
# Jump to harpoon slot $1 (1-based). Bound to Alt+1..Alt+4 for instant switching.
LIST="$HOME/.tmux/claude_harpoon"
n=$1

[ -f "$LIST" ] || { tmux display-message "Harpoon is empty"; exit 0; }

target=$(sed -n "${n}p" "$LIST")
if [ -z "$target" ]; then
  tmux display-message "Harpoon slot $n is empty"
  exit 0
fi

if ! tmux list-panes -a -F '#{pane_id}' | grep -qx "$target"; then
  tmux display-message "Harpoon slot $n pane is gone"
  exit 0
fi

session=$(tmux display-message -p -t "$target" '#{session_name}')
tmux switch-client -t "$session"
tmux select-window -t "$target" 2>/dev/null
tmux select-pane -t "$target" 2>/dev/null
