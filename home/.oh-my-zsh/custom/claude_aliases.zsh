function c() {
  if [ -z "$1" ]; then
    tmux new-window "claude"
  else
    tmux new-window "claude -p \"$*\""
  fi
}

function ch() {
  if [ -z "$1" ]; then
    tmux split-window -h "claude"
  else
    tmux split-window -h "claude -p \"$*\""
  fi
}

function cv() {
  if [ -z "$1" ]; then
    tmux split-window -v "claude"
  else
    tmux split-window -v "claude -p \"$*\""
  fi
}
