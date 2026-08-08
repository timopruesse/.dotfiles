# coding-agent aliases: path/remote-aware launcher for Claude Code vs Cursor Agent.
# Resolve rules live in ~/.config/herdr/scripts/coding_agent_resolve.sh
#   chewielabs (remote or ~/github/chewielabs) → claude
#   everything else → agent
# Override: CODING_AGENT=claude|agent, or pass --claude / --agent to c/ch/cv/cr/cpi.

_CODING_AGENT_SCRIPTS="${HOME}/.config/herdr/scripts"

function _herdr_pane_id_from_json() {
  python3 -c '
import json, sys
d = json.load(sys.stdin)
r = d.get("result") or {}
p = r.get("pane") or r.get("root_pane") or {}
if isinstance(p, dict):
    print(p.get("pane_id") or "")
elif isinstance(p, str):
    print(p)
'
}

function _coding_agent_herdr() {
  local mode="$1"
  shift

  if [ "${HERDR_ENV:-}" != 1 ]; then
    echo "Not inside herdr — run \`herdr\` first, or launch the agent in this shell."
    return 1
  fi

  # Best-effort project-agents for Cursor Task enum.
  if [[ -x "$_CODING_AGENT_SCRIPTS/coding_agent_ensure.sh" ]]; then
    "$_CODING_AGENT_SCRIPTS/coding_agent_ensure.sh" >/dev/null 2>&1 || true
  fi

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
    cli=$("$_CODING_AGENT_SCRIPTS/coding_agent_resolve.sh" "$PWD")
  fi
  command -v "$cli" >/dev/null || { echo "$cli not found in PATH"; return 1; }

  local resp pane_id
  case "$mode" in
    window)
      resp=$(herdr tab create --cwd "$PWD" --focus)
      ;;
    hsplit)
      resp=$(herdr pane split --current --direction right --cwd "$PWD" --focus)
      ;;
    vsplit)
      resp=$(herdr pane split --current --direction down --cwd "$PWD" --focus)
      ;;
    *)
      echo "unknown mode: $mode"; return 1
      ;;
  esac

  pane_id=$(printf '%s\n' "$resp" | _herdr_pane_id_from_json)
  if [[ -z "$pane_id" ]]; then
    echo "herdr: failed to create pane"
    printf '%s\n' "$resp"
    return 1
  fi

  if (( ${#args[@]} == 0 )); then
    herdr pane run "$pane_id" "$cli"
  else
    # Join args into one shell command line for pane run.
    herdr pane run "$pane_id" "$cli $(printf '%q ' "${args[@]}")"
  fi

  # Claude-only: rotate pane color after the TUI is up.
  if [[ "$cli" == claude ]]; then
    local colors=(red blue green yellow purple orange pink cyan)
    local state_file="${XDG_STATE_HOME:-$HOME/.local/state}/claude_color_index"
    local idx=$(($(cat "$state_file" 2>/dev/null || echo 0) % ${#colors[@]} + 1))
    echo "$idx" > "$state_file"
    local color="${colors[$idx]}"
    {
      sleep 3
      herdr pane send-text "$pane_id" "/color $color"
      herdr pane send-keys "$pane_id" enter
      sleep 0.2
      herdr pane send-keys "$pane_id" esc
      sleep 0.1
      herdr pane send-keys "$pane_id" enter
    } &!
  fi
}

function c() {
  _coding_agent_herdr window "$@"
}

function ch() {
  _coding_agent_herdr hsplit "$@"
}

function cv() {
  _coding_agent_herdr vsplit "$@"
}

function cr() {
  _coding_agent_herdr window --continue "$@"
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
  _coding_agent_herdr window "${force_flags[@]}" -p "$prompt"
}

# Agent list / jump: goto (prefix+g / prefix+C) or sidebar (prefix+a).
# Spaces: picker prefix+w; new space prefix+shift+N. Last pane: prefix+Tab.
function clist() {
  if [ "${HERDR_ENV:-}" != 1 ]; then
    echo "Not inside herdr — run \`herdr\` first."
    return 1
  fi
  herdr agent list
}

function cj() {
  echo "Jump agents: goto (prefix+g / prefix+C) or sidebar (prefix+a). Spaces: prefix+w."
  if [ "${HERDR_ENV:-}" = 1 ]; then
    herdr agent list
  fi
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
