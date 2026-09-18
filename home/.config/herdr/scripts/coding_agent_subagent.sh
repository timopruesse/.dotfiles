#!/usr/bin/env zsh
# Subagent orchestration via Herdr: open splits/tabs and communicate with agents.
# Opt-in visible terminal management; native subagent tools remain the default.
#
# Usage:
#   coding_agent_subagent.sh run --agent <name> [--layout right|down|tab]
#                            [--name <label>] [--kind claude|cursor|agy]
#                            [--cwd <dir>] [--timeout <ms>] [--keep|--close]
#                            [--prompt <text> | <prompt text>]
#
#   coding_agent_subagent.sh spawn --agent <name> [--layout right|down|tab]
#                            [--name <label>] [--kind claude|cursor|agy] [--cwd <dir>]
#
#   coding_agent_subagent.sh prompt <target> <prompt text> [--timeout <ms>]
#
#   coding_agent_subagent.sh read <target> [--lines <N>]
#
#   coding_agent_subagent.sh wait <target> [--timeout <ms>]
#
#   coding_agent_subagent.sh close <target>

set -euo pipefail

scripts=${0:A:h}
source "$scripts/coding_agent_resolve.sh"
source "$scripts/coding_agent_ensure.sh"
source "$scripts/coding_agent_space.sh"

check_herdr_env() {
  if [[ "${HERDR_ENV:-}" != "1" ]]; then
    print -u2 "coding_agent_subagent: not running inside Herdr (HERDR_ENV!=1). Herdr is required."
    return 1
  fi
  command -v herdr >/dev/null 2>&1 || {
    print -u2 "coding_agent_subagent: 'herdr' command not found in PATH."
    return 1
  }
  return 0
}

pane_id_from_json() {
  python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    r = d.get("result") or {}
    p = r.get("pane") or r.get("root_pane") or {}
    if isinstance(p, dict):
        print(p.get("pane_id") or "")
    elif isinstance(p, str):
        print(p)
    else:
        print("")
except Exception:
    print("")
'
}

tab_id_from_json() {
  python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    r = d.get("result") or {}
    t = r.get("tab") or {}
    if isinstance(t, dict):
        print(t.get("tab_id") or "")
    elif isinstance(t, str):
        print(t)
    else:
        print("")
except Exception:
    print("")
'
}

agent_state_from_json() {
  python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    r = d.get("result") or {}
    a = r.get("agent") or r
    if isinstance(a, dict):
        print(a.get("state") or "")
    else:
        print("")
except Exception:
    print("")
'
}

resolve_herdr_kind() {
  local cli=$1
  case "$cli" in
  claude) print "claude" ;;
  agent | cursor) print "cursor" ;;
  agy) print "agy" ;;
  *) print -u2 "unsupported Herdr subagent host: $cli"; return 1 ;;
  esac
}

cmd=${1:-}
if [[ -z "$cmd" ]]; then
  print -u2 "usage: coding_agent_subagent.sh run|spawn|prompt|read|wait|close [options...]"
  exit 1
fi
shift

case "$cmd" in
spawn)
  check_herdr_env
  agent=""
  name=""
  layout="right"
  kind=""
  cwd="${PWD}"
  focus_flag="--focus"
  auto_mode=1
  dangerously_skip=0

  while (( $# )); do
    case "$1" in
    --agent) agent=$2; shift 2 ;;
    --name) name=$2; shift 2 ;;
    --layout) layout=$2; shift 2 ;;
    --kind) kind=$2; shift 2 ;;
    --cwd) cwd=$2; shift 2 ;;
    --no-focus) focus_flag="--no-focus"; shift ;;
    --focus) focus_flag="--focus"; shift ;;
    --auto) auto_mode=1; shift ;;
    --no-auto) auto_mode=0; shift ;;
    --dangerously-skip-permissions | --bypass) dangerously_skip=1; shift ;;
    *) print -u2 "unknown spawn option: $1"; exit 1 ;;
    esac
  done

  if [[ -z "$agent" ]]; then
    print -u2 "coding_agent_subagent spawn: --agent <name> is required"
    exit 1
  fi

  if [[ -z "$name" ]]; then
    # Generate unique live agent name: <agent> or <agent>_<random>
    name="${agent}"
    if herdr agent list 2>/dev/null | grep -qw "$name"; then
      name="${agent}_$(( RANDOM % 900 + 100 ))"
    fi
  fi

  if [[ -z "$kind" ]]; then
    resolved_cli=$(coding_agent_resolve "$cwd")
    kind=$(resolve_herdr_kind "$resolved_cli")
  fi

  case "$kind" in
  cursor) coding_agent_ensure_project_agents "$cwd" ;;
  claude | agy) ;;
  *) print -u2 "unsupported Herdr subagent host: $kind"; exit 1 ;;
  esac

  case "$layout" in
  right | down)
    resp=$(coding_agent_create_pane "$layout" "$cwd" "$focus_flag")
    ;;
  tab)
    resp=$(coding_agent_create_pane tab "$cwd" --label "$name" "$focus_flag")
    ;;
  *)
    print -u2 "unknown layout: $layout (use right|down|tab)"
    exit 1
    ;;
  esac

  pane_id=$(printf '%s\n' "$resp" | pane_id_from_json)
  tab_id=$(printf '%s\n' "$resp" | tab_id_from_json)
  if [[ -z "$pane_id" ]]; then
    print -u2 "coding_agent_subagent: failed to create pane:"
    print -u2 "$resp"
    exit 1
  fi

  # Start the agent based on kind with auto-mode / permission-bypass flags
  extra_args=()
  case "$kind" in
  claude)
    extra_args=(--agent "$agent")
    if (( dangerously_skip )); then
      extra_args+=(--dangerously-skip-permissions)
    elif (( auto_mode )); then
      extra_args+=(--permission-mode auto)
    fi
    herdr agent start "$name" --kind claude --pane "$pane_id" -- "${extra_args[@]}" >/dev/null
    ;;
  agy)
    extra_args=(--agent "$agent")
    if (( auto_mode || dangerously_skip )); then
      extra_args+=(--dangerously-skip-permissions)
    fi
    herdr agent start "$name" --kind agy --pane "$pane_id" -- "${extra_args[@]}" >/dev/null
    ;;
  cursor)
    extra_args=()
    if (( auto_mode || dangerously_skip )); then
      extra_args+=(-f --approve-mcps --trust)
    fi
    herdr agent start "$name" --kind cursor --pane "$pane_id" -- "${extra_args[@]}" >/dev/null
    ;;
  *)
    herdr agent start "$name" --kind "$kind" --pane "$pane_id" >/dev/null
    ;;
  esac

  # Output pane_id, tab_id, and live agent name
  print "PANE_ID=$pane_id"
  print "TAB_ID=$tab_id"
  print "AGENT_NAME=$name"
  ;;

prompt)
  check_herdr_env
  target=${1:-}
  if [[ -z "$target" ]]; then
    print -u2 "usage: coding_agent_subagent.sh prompt <target> <text> [--timeout <ms>]"
    exit 1
  fi
  shift
  prompt_text=""
  timeout="300000"

  while (( $# )); do
    case "$1" in
    --timeout) timeout=$2; shift 2 ;;
    *)
      if [[ -z "$prompt_text" ]]; then
        prompt_text=$1
      else
        prompt_text="$prompt_text $1"
      fi
      shift
      ;;
    esac
  done

  herdr agent prompt "$target" "$prompt_text" --wait --timeout "$timeout"
  ;;

read)
  check_herdr_env
  target=${1:-}
  if [[ -z "$target" ]]; then
    print -u2 "usage: coding_agent_subagent.sh read <target> [--lines <N>]"
    exit 1
  fi
  shift
  lines="120"
  while (( $# )); do
    case "$1" in
    --lines) lines=$2; shift 2 ;;
    *) shift ;;
    esac
  done

  herdr agent read "$target" --source recent-unwrapped --lines "$lines"
  ;;

wait)
  check_herdr_env
  target=${1:-}
  timeout="300000"
  shift
  while (( $# )); do
    case "$1" in
    --timeout) timeout=$2; shift 2 ;;
    *) shift ;;
    esac
  done

  herdr agent wait "$target" --timeout "$timeout"
  ;;

close)
  check_herdr_env
  target=${1:-}
  if [[ -z "$target" ]]; then
    print -u2 "usage: coding_agent_subagent.sh close <pane-id|agent-name>"
    exit 1
  fi
  # If target is an agent name, find its pane_id
  if [[ "$target" =~ ^[a-z][a-z0-9_-]*$ ]]; then
    agent_info=$(herdr agent get "$target" 2>/dev/null || true)
    pane_id=$(printf '%s\n' "$agent_info" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get("result", {}).get("agent", {}).get("pane_id", ""))
except Exception:
    print("")
')
    if [[ -n "$pane_id" ]]; then
      herdr pane close "$pane_id" 2>/dev/null || true
      exit 0
    fi
  fi
  herdr pane close "$target" 2>/dev/null || true
  ;;

run)
  check_herdr_env
  agent=""
  name=""
  layout="right"
  kind=""
  cwd="${PWD}"
  timeout="300000"
  keep=""
  prompt_text=""
  auto_mode=1
  dangerously_skip=0

  while (( $# )); do
    case "$1" in
    --agent) agent=$2; shift 2 ;;
    --name) name=$2; shift 2 ;;
    --layout) layout=$2; shift 2 ;;
    --kind) kind=$2; shift 2 ;;
    --cwd) cwd=$2; shift 2 ;;
    --timeout) timeout=$2; shift 2 ;;
    --keep) keep=1; shift ;;
    --close) keep=0; shift ;;
    --auto) auto_mode=1; shift ;;
    --no-auto) auto_mode=0; shift ;;
    --dangerously-skip-permissions | --bypass) dangerously_skip=1; shift ;;
    --prompt) prompt_text=$2; shift 2 ;;
    *)
      if [[ -z "$prompt_text" ]]; then
        prompt_text=$1
      else
        prompt_text="$prompt_text $1"
      fi
      shift
      ;;
    esac
  done

  if [[ -z "$agent" ]]; then
    print -u2 "coding_agent_subagent run: --agent <name> is required"
    exit 1
  fi
  if [[ -z "$prompt_text" ]]; then
    print -u2 "coding_agent_subagent run: prompt text is required"
    exit 1
  fi

  # Default retention policy:
  # committer doesn't hold information needed to revisit, so close its pane/tab automatically.
  # other agents (worker, verifier, scout, sweep) remain open for inspection.
  if [[ -z "$keep" ]]; then
    if [[ "$agent" == "committer" ]]; then
      keep=0
    else
      keep=1
    fi
  fi

  # 1. Spawn
  spawn_flags=()
  if (( !auto_mode )); then
    spawn_flags+=(--no-auto)
  fi
  if (( dangerously_skip )); then
    spawn_flags+=(--dangerously-skip-permissions)
  fi

  spawn_out=$("$scripts/coding_agent_subagent.sh" spawn --agent "$agent" \
    ${name:+--name "$name"} \
    --layout "$layout" \
    ${kind:+--kind "$kind"} \
    --cwd "$cwd" \
    "${spawn_flags[@]}")

  eval "$spawn_out"

  # 2. Prompt & wait
  if ! herdr agent prompt "$AGENT_NAME" "$prompt_text" --wait --timeout "$timeout"; then
    print -u2 "coding_agent_subagent: agent prompt failed or timed out"
    # Still attempt to read recent output
    herdr agent read "$AGENT_NAME" --source recent-unwrapped --lines 60 || true
    if (( !keep )); then
      if [[ -n "${TAB_ID:-}" ]]; then
        herdr tab close "$TAB_ID" 2>/dev/null || herdr pane close "$PANE_ID" 2>/dev/null || true
      else
        herdr pane close "$PANE_ID" 2>/dev/null || true
      fi
    fi
    exit 1
  fi

  # 3. Read output
  herdr agent read "$AGENT_NAME" --source recent-unwrapped --lines 120

  # 4. Optional close (committer closes automatically; others stay open unless --close passed)
  if (( !keep )); then
    if [[ -n "${TAB_ID:-}" ]]; then
      herdr tab close "$TAB_ID" 2>/dev/null || herdr pane close "$PANE_ID" 2>/dev/null || true
    else
      herdr pane close "$PANE_ID" 2>/dev/null || true
    fi
  fi
  ;;

*)
  print -u2 "unknown command: $cmd (use run|spawn|prompt|read|wait|close)"
  exit 1
  ;;
esac
