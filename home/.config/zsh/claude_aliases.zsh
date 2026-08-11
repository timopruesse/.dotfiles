# coding-agent aliases: path/remote-aware launcher for Claude Code vs Cursor Agent.
# Resolve + herdr split/tab live in ~/.config/herdr/scripts/coding_agent_herdr.sh
#   chewielabs (remote or ~/github/chewielabs) → claude
#   everything else → agent
# Override: CODING_AGENT=claude|agent, or pass --claude / --agent to c/ch/cv/cr/cpi.

_CODING_AGENT_SCRIPTS="${HOME}/.config/herdr/scripts"

function _coding_agent_herdr() {
  local mode="$1"
  shift

  if [ "${HERDR_ENV:-}" != 1 ]; then
    echo "Not inside herdr — run \`herdr\` first, or launch the agent in this shell."
    return 1
  fi

  local layout
  case "$mode" in
    window) layout=window ;;
    hsplit) layout=hsplit ;;
    vsplit) layout=vsplit ;;
    *)
      echo "unknown mode: $mode"
      return 1
      ;;
  esac

  "$_CODING_AGENT_SCRIPTS/coding_agent_herdr.sh" "$layout" "$@" >/dev/null || return 1
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
  _coding_agent_herdr window continue "$@"
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
