#!/bin/sh
# Runs inside the Claude sidebar split (see claude_panel_toggle.sh).
# Shows a live, auto-refreshing list of Claude sessions; enter jumps to the
# selected one, esc/ctrl-c closes the sidebar.

SCRIPTS="$HOME/.tmux/scripts"

selected=$(
  "$SCRIPTS/claude_sessions.sh" | fzf \
    --reverse \
    --no-sort \
    --track \
    --delimiter='\t' \
    --with-nth='1,4,3' \
    --prompt='claude > ' \
    --header='enter: jump   ctrl-r: refresh   esc: close' \
    --bind="ctrl-r:reload($SCRIPTS/claude_sessions.sh)" \
    --bind="every(5):reload-sync($SCRIPTS/claude_sessions.sh)"
)

# Forget the sidebar so the toggle reopens a fresh one next time.
tmux set-option -gu @claude_panel

[ -z "$selected" ] && exit 0

target=$(printf '%s' "$selected" | cut -f2)
[ -z "$target" ] && exit 0

session=${target%%:*}
winpane=${target#*:}
window=${winpane%%.*}

tmux switch-client -t "$session"
tmux select-window -t "${session}:${window}" 2>/dev/null
tmux select-pane -t "$target" 2>/dev/null
