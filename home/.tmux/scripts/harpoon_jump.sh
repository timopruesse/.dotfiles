#!/bin/sh
# Jump to harpoon slot $1 (1-based). Bound to Alt+1..Alt+4 for instant switching.
. "$HOME/.tmux/scripts/claude_lib.sh"

LIST="$HOME/.tmux/claude_harpoon"
n=$1

[ -f "$LIST" ] || { tmux display-message "Harpoon is empty"; exit 0; }

target=$(sed -n "${n}p" "$LIST")
if [ -z "$target" ]; then
  tmux display-message "Harpoon slot $n is empty"
  exit 0
fi

if ! pane_exists "$target"; then
  tmux display-message "Harpoon slot $n pane is gone"
  exit 0
fi

claude_jump "$target"
