#!/usr/bin/env zsh
# Launch the path-appropriate coding agent directly.
# Used by coding_agent_herdr.sh / herdr keybinds (cwd already set on the pane).
#
# Usage: coding_agent_launch.sh [resume|continue] [--claude|--codex|--agent|--cursor|--agy]
#                               [--resolved claude|codex|agent|agy] [--ensured]
#                               [--print] [--prompt-file PATH] [extra args...]
#
# --resolved: skip git-remote resolve (herdr already computed the CLI).
# --ensured:  skip ensure-project-agents (herdr already ran it).

scripts=${0:A:h}
source "$scripts/coding_agent_resolve.sh"
source "$scripts/coding_agent_ensure.sh"

mode=
force=
resolved=
ensured=0
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
  --resolved)
    if (( $# < 2 )) || [[ -z "$2" ]]; then
      print -u2 "coding_agent_launch: --resolved requires claude|codex|agent|agy"
      sleep 2
      exit 1
    fi
    case "$2" in
    claude | codex | agent | agy) resolved=$2 ;;
    *)
      print -u2 "coding_agent_launch: --resolved must be claude|codex|agent|agy (got: $2)"
      sleep 2
      exit 1
      ;;
    esac
    shift 2
    ;;
  --ensured)
    ensured=1
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

if (( !ensured )); then
  coding_agent_ensure_project_agents
fi

if [[ -n "$prompt_file" ]]; then
  if [[ ! -f "$prompt_file" ]]; then
    print -u2 "coding_agent_launch: prompt file not found: $prompt_file"
    sleep 2
    exit 1
  fi
  args+=("$(<$prompt_file)")
  rm -f "$prompt_file"
fi

if [[ -n "$force" ]]; then
  cli=$force
elif [[ -n "$resolved" ]]; then
  cli=$resolved
else
  cli=$(coding_agent_resolve "$PWD")
fi

command -v "$cli" >/dev/null 2>&1 || {
  print -u2 "$cli not found in PATH"
  sleep 2
  exit 1
}

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
