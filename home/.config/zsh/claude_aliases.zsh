# coding-agent aliases: path/remote-aware launcher for Claude Code vs Cursor Agent.
# Resolve rules live in ~/.tmux/scripts/coding_agent_resolve.sh
#   chewielabs (remote or ~/github/chewielabs) → claude
#   everything else → agent
# Override: CODING_AGENT=claude|agent, or pass --claude / --agent to c/ch/cv/cr/cpi.

function _coding_agent_tmux() {
  local mode="$1"
  shift

  local force=""
  local args=()
  for arg in "$@"; do
    case "$arg" in
      --claude) force=claude ;;
      --agent|--cursor) force=agent ;;
      *) args+=("$arg") ;;
    esac
  done

  local cli
  if [[ -n "$force" ]]; then
    cli=$force
  else
    cli=$("$HOME/.tmux/scripts/coding_agent_resolve.sh" "$PWD")
  fi
  command -v "$cli" >/dev/null || { echo "$cli not found in PATH"; return 1; }

  local pane_id
  case "$mode" in
    window) pane_id=$(tmux new-window -c "$PWD" -P -F '#{pane_id}') ;;
    hsplit) pane_id=$(tmux split-window -h -c "$PWD" -P -F '#{pane_id}') ;;
    vsplit) pane_id=$(tmux split-window -v -c "$PWD" -P -F '#{pane_id}') ;;
  esac

  if (( ${#args[@]} == 0 )); then
    tmux send-keys -t "$pane_id" "$cli" Enter
  else
    tmux send-keys -t "$pane_id" "$cli $(printf '%q ' "${args[@]}")" Enter
  fi

  # Claude-only: rotate pane color after the TUI is up.
  if [[ "$cli" == claude ]]; then
    local colors=(red blue green yellow purple orange pink cyan)
    local state_file="${XDG_STATE_HOME:-$HOME/.local/state}/claude_color_index"
    local idx=$(($(cat "$state_file" 2>/dev/null || echo 0) % ${#colors[@]} + 1))
    echo "$idx" > "$state_file"
    local color="${colors[$idx]}"
    { sleep 3 && tmux send-keys -t "$pane_id" "/color $color" && sleep 0.2 && tmux send-keys -t "$pane_id" Escape && sleep 0.1 && tmux send-keys -t "$pane_id" Enter; } &!
  fi
}

function c() {
  _coding_agent_tmux window "$@"
}

function ch() {
  _coding_agent_tmux hsplit "$@"
}

function cv() {
  _coding_agent_tmux vsplit "$@"
}

function cr() {
  _coding_agent_tmux window --continue "$@"
}

function cpi() {
  local input=""
  if [ ! -t 0 ]; then
    input=$(cat)
  fi
  local instruction="$*"
  # Strip override flags from the prompt; re-pass them to the launcher.
  local force_flags=()
  local prompt_parts=()
  for arg in "$@"; do
    case "$arg" in
      --claude|--agent|--cursor) force_flags+=("$arg") ;;
      *) prompt_parts+=("$arg") ;;
    esac
  done
  instruction="${prompt_parts[*]}"

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
  _coding_agent_tmux window "${force_flags[@]}" -p "$prompt"
}

# clist / cj share one definition of "a running coding-agent session" (and one
# jump) with the tmux scripts: claude_sessions.sh enumerates, claude_picker.sh
# picks and jumps.
function clist() {
  local rows
  rows=$("$HOME/.tmux/scripts/claude_sessions.sh")
  if [[ -z "$rows" ]]; then
    echo "No coding agents running"
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
