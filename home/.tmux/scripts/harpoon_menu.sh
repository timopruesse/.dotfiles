#!/bin/sh
# Harpoon menu popup (bound to prefix + e): manage and jump to pinned sessions.
SCRIPTS="$HOME/.tmux/scripts"

if [ -z "$("$SCRIPTS/harpoon_list.sh")" ]; then
  echo "Harpoon is empty — press 'prefix m' in a pane to pin it"
  sleep 1.5
  exit 0
fi

selected=$(
  "$SCRIPTS/harpoon_list.sh" | fzf \
    --reverse \
    --no-sort \
    --track \
    --delimiter='\t' \
    --with-nth='1,2,4' \
    --prompt='harpoon > ' \
    --header='enter: jump   ctrl-x: unpin   ctrl-r: refresh' \
    --bind="ctrl-r:reload($SCRIPTS/harpoon_list.sh)" \
    --bind="every(3):reload($SCRIPTS/harpoon_list.sh)" \
    --bind="ctrl-x:execute-silent($SCRIPTS/harpoon_remove.sh {3})+reload($SCRIPTS/harpoon_list.sh)"
)

[ -z "$selected" ] && exit 0

target=$(printf '%s' "$selected" | cut -f3)
[ -z "$target" ] && exit 0

session=$(tmux display-message -p -t "$target" '#{session_name}')
tmux switch-client -t "$session"
tmux select-window -t "$target" 2>/dev/null
tmux select-pane -t "$target" 2>/dev/null
