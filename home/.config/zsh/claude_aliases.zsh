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

function cr() {
  _claude_tmux window "--continue"
}

function cpi() {
  local input=""
  if [ ! -t 0 ]; then
    input=$(cat)
  fi
  local instruction="$*"
  local prompt=""
  if [ -n "$instruction" ] && [ -n "$input" ]; then
    prompt="${instruction}\n\n${input}"
  elif [ -n "$input" ]; then
    prompt="$input"
  elif [ -n "$instruction" ]; then
    prompt="$instruction"
  else
    echo "Usage: echo 'code' | cpi 'instruction'  OR  cpi 'prompt'"
    return 1
  fi
  _claude_tmux window "-p $(printf '%q' "$prompt")"
}

# clist / cj share one definition of "a running Claude session" (and one jump)
# with the tmux scripts: claude_sessions.sh enumerates, claude_picker.sh picks
# and jumps. Re-implementing the enumeration here drifted out of sync with
# is_claude_cmd (it missed version-only panes and matched ~/.claude paths).
function clist() {
  local rows
  rows=$("$HOME/.tmux/scripts/claude_sessions.sh")
  if [[ -z "$rows" ]]; then
    echo "No Claude agents running"
    return 0
  fi
  # Show: status marker, target (session:window.pane), task title.
  printf '%s\n' "$rows" | awk -F '\t' '{ printf "%s  %-18s  %s\n", $1, $2, $3 }'
}

function cj() {
  "$HOME/.tmux/scripts/claude_picker.sh"
}
