function _claude_tmux() {
  local mode="$1"
  shift
  command -v claude >/dev/null || { echo "claude not found in PATH"; return 1; }

  local colors=(red blue green yellow purple orange pink cyan)
  local state_file="${XDG_STATE_HOME:-$HOME/.local/state}/claude_color_index"
  local idx=$(($(cat "$state_file" 2>/dev/null || echo 0) % ${#colors[@]} + 1))
  echo "$idx" > "$state_file"
  local color="${colors[$idx]}"

  local pane_id
  case "$mode" in
    window) pane_id=$(tmux new-window -c "$PWD" -P -F '#{pane_id}') ;;
    hsplit) pane_id=$(tmux split-window -h -c "$PWD" -P -F '#{pane_id}') ;;
    vsplit) pane_id=$(tmux split-window -v -c "$PWD" -P -F '#{pane_id}') ;;
  esac

  if [ -z "$1" ]; then
    tmux send-keys -t "$pane_id" "claude" Enter
  else
    tmux send-keys -t "$pane_id" "claude $(printf '%q' "$*")" Enter
  fi

  { sleep 3 && tmux send-keys -t "$pane_id" "/color $color" && sleep 0.2 && tmux send-keys -t "$pane_id" Escape && sleep 0.1 && tmux send-keys -t "$pane_id" Enter; } &!
}

function c() {
  _claude_tmux window "$@"
}

function ch() {
  _claude_tmux hsplit "$@"
}

function cv() {
  _claude_tmux vsplit "$@"
}
