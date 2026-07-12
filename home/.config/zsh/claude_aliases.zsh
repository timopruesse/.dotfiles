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

# agents-link: make Cursor read the same instructions as Claude by symlinking
# AGENTS.md -> CLAUDE.md (Cursor reads AGENTS.md, Claude reads CLAUDE.md; one
# source of bytes). CLAUDE.md stays the real file. Relative symlink so it
# survives moving/cloning the repo.
#   agents-link [dir]     link a single CLAUDE.md (default: $PWD)
#   agents-link --all     link every CLAUDE.md in the repo (skips .git/node_modules)
#   agents-link -f ...     replace an existing AGENTS.md symlink (never a real file)
function agents-link() {
  local force=0 all=0
  while [[ "$1" == -* ]]; do
    case "$1" in
      -f|--force) force=1 ;;
      --all) all=1 ;;
      -h|--help)
        echo "usage: agents-link [-f] [--all] [dir]"; return 0 ;;
      *) echo "agents-link: unknown flag $1"; return 1 ;;
    esac
    shift
  done

  _agents_link_one() {
    local dir="$1"
    if [[ ! -f "$dir/CLAUDE.md" ]]; then
      echo "✗ $dir: no CLAUDE.md"; return 1
    fi
    local target="$dir/AGENTS.md"
    if [[ -L "$target" ]]; then
      if [[ "$(readlink "$target")" == "CLAUDE.md" ]]; then
        echo "• $dir/AGENTS.md already linked"; return 0
      fi
      if (( ! force )); then
        echo "✗ $dir/AGENTS.md is a symlink to something else (readlink: $(readlink "$target")); pass -f to replace"; return 1
      fi
      rm "$target"
    elif [[ -e "$target" ]]; then
      echo "✗ $dir/AGENTS.md is a real file — refusing to clobber. Merge it into CLAUDE.md first."; return 1
    fi
    ( cd "$dir" && ln -s CLAUDE.md AGENTS.md ) && echo "✓ $dir/AGENTS.md -> CLAUDE.md"
  }

  if (( all )); then
    local root; root=$(git rev-parse --show-toplevel 2>/dev/null) || root="$PWD"
    local f
    find "$root" \( -name .git -o -name node_modules \) -prune -o -name CLAUDE.md -print 2>/dev/null | while read -r f; do
      _agents_link_one "${f:h}"
    done
  else
    _agents_link_one "${1:-$PWD}"
  fi
  unfunction _agents_link_one 2>/dev/null
}
