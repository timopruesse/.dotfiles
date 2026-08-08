#!/usr/bin/env zsh
# Launch the path-appropriate coding agent with shared policy (worktree + keep-awake).
# Used by coding_agent_herdr.sh / herdr keybinds (cwd already set on the pane).
#
# Usage: coding_agent_launch.sh [resume|continue] [--claude|--agent|--cursor]
#                               [--prompt-file PATH] [extra args...]

scripts=${0:A:h}
source "$scripts/coding_agent_resolve.sh"
source "$scripts/coding_agent_ensure.sh"
source "$scripts/coding_agent_policy.zsh"

coding_agent_ensure_project_agents

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
    args+=("$@")
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

case "$mode" in
resume) coding_agent_with_policy "$cli" --resume "${args[@]}" ;;
continue) coding_agent_with_policy "$cli" --continue "${args[@]}" ;;
*) coding_agent_with_policy "$cli" "${args[@]}" ;;
esac
