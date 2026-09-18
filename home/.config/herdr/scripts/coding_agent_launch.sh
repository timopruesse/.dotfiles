#!/usr/bin/env zsh
# Launch the path-appropriate coding agent directly.
# Used by coding_agent_herdr.sh / herdr keybinds (cwd already set on the pane).
#
# Usage: coding_agent_launch.sh [resume|continue] [--claude|--codex|--agent|--cursor|--agy]
#                               [--print] [--prompt-file PATH] [extra args...]

scripts=${0:A:h}
source "$scripts/coding_agent_resolve.sh"
source "$scripts/coding_agent_ensure.sh"

mode=
force=
prompt_file=
args=()

while (( $# )); do
  case "$1" in
  resume | continue)
    mode=$1
    shift
    ;;
  --claude)
    force=claude
    shift
    ;;
  --agent | --cursor)
    force=agent
    shift
    ;;
  --codex)
    force=codex
    shift
    ;;
  --print)
    mode=print
    shift
    ;;
  --agy)
    force=agy
    shift
    ;;
  --prompt-file)
    if (( $# < 2 )) || [[ -z "$2" ]]; then
      print -u2 "coding_agent_launch: --prompt-file requires a path"
      sleep 2
      exit 1
    fi
    prompt_file=$2
    shift 2
    ;;
  --)
    shift
    args+=(-- "$@")
    break
    ;;
  *)
    args+=("$1")
    shift
    ;;
  esac
done

if [[ -n "$prompt_file" ]]; then
  if [[ ! -f "$prompt_file" ]]; then
    print -u2 "coding_agent_launch: prompt file not found: $prompt_file"
    sleep 2
    exit 1
  fi
  # File contents are a prompt, even when they begin with a CLI flag.
  if (( ! ${args[(Ie)--]} )); then
    args+=(--)
  fi
  args+=("$(<$prompt_file)")
  rm -f "$prompt_file"
fi

if [[ -n "$force" ]]; then
  cli=$force
else
  cli=$(coding_agent_resolve "$PWD")
fi

command -v "$cli" >/dev/null 2>&1 || {
  print -u2 "$cli not found in PATH"
  sleep 2
  exit 1
}

# Host preparation belongs here, in the actual target pane and checkout.
if [[ "$cli" == "agent" ]]; then
  coding_agent_ensure_project_agents "$PWD"
fi

pane_context="$scripts/pane_context.sh"
if [[ "${HERDR_ENV:-}" == 1 && -n "${HERDR_PANE_ID:-}" && -x "$pane_context" ]]; then
  "$pane_context" set-agent "$cli" "$HERDR_PANE_ID" >/dev/null || true
  wt=$("$pane_context" worktree-name "$PWD" 2>/dev/null || true)
  if [[ -n "$wt" ]]; then
    "$pane_context" set-wt "$wt" "$HERDR_PANE_ID" >/dev/null || true
  fi
fi

case "$mode" in
resume)
  if [[ "$cli" == "codex" ]]; then
    command "$cli" resume "${args[@]}"
  elif [[ "$cli" == "agy" ]]; then
    command "$cli" --continue "${args[@]}"
  else
    command "$cli" --resume "${args[@]}"
  fi
  ;;
continue)
  if [[ "$cli" == "codex" ]]; then
    command "$cli" resume --last "${args[@]}"
  else
    command "$cli" --continue "${args[@]}"
  fi
  ;;
print)
  if [[ "$cli" == "codex" ]]; then
    command "$cli" exec "${args[@]}"
  else
    command "$cli" -p "${args[@]}"
  fi
  ;;
*) command "$cli" "${args[@]}" ;;
esac
