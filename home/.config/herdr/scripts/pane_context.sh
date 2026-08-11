#!/usr/bin/env bash
# Deep pane-context module: pane-keyed AWS/worktree/agent signals → herdr report-metadata.
# Adapters: awsp/awsu, coding-agent launch, Claude/Cursor shell hooks.
#
# Usage (CLI):
#   pane_context.sh set-aws <profile> [pane_id]
#   pane_context.sh clear-aws [pane_id]
#   pane_context.sh get-aws [pane_id]
#   pane_context.sh report-aws [pane_id]
#   pane_context.sh parse-aws-from-command <cmdline>
#   pane_context.sh inject-prefix <cmdline>
#   pane_context.sh set-wt <name> [pane_id]
#   pane_context.sh set-agent <claude|cursor|agent> [pane_id]
#
# Source from zsh for functions with the same names (no .sh suffix on functions).

set -euo pipefail

PANE_CONTEXT_SOURCE="${PANE_CONTEXT_SOURCE:-dotfiles:pane-context}"
PANE_CONTEXT_SCRIPTS="${PANE_CONTEXT_SCRIPTS:-$(CDPATH= cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

pane_context_sanitize_id() {
  printf '%s' "$1" | sed 's/[^a-zA-Z0-9._-]/_/g'
}

pane_context_aws_file() {
  local pane_id="$1"
  local safe
  safe=$(pane_context_sanitize_id "$pane_id")
  printf '%s/herdr_pane_aws_%s' "${XDG_STATE_HOME:-$HOME/.local/state}" "$safe"
}

pane_context_in_herdr() {
  [ "${HERDR_ENV:-}" = "1" ] && [ -n "${HERDR_SOCKET_PATH:-}" ]
}

pane_context_herdr() {
  # Bound herdr CLI so a bad/missing socket cannot hang adapters or hooks.
  if ! command -v herdr >/dev/null 2>&1; then
    return 127
  fi
  if command -v timeout >/dev/null 2>&1; then
    timeout 2 herdr "$@"
    return $?
  fi
  if command -v gtimeout >/dev/null 2>&1; then
    gtimeout 2 herdr "$@"
    return $?
  fi
  # macOS fallback: no GNU timeout
  herdr "$@" &
  local pid=$!
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$i" -ge 20 ]; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      return 124
    fi
    sleep 0.1
    i=$((i + 1))
  done
  wait "$pid"
}

pane_context_focused_pane_id() {
  command -v herdr >/dev/null 2>&1 || return 1
  pane_context_herdr api snapshot 2>/dev/null | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    raise SystemExit(1)
snap = (data.get("result") or {}).get("snapshot") or data.get("snapshot") or {}
pane_id = snap.get("focused_pane_id") or ""
if pane_id:
    print(pane_id)
' 2>/dev/null
}

pane_context_resolve_pane_id() {
  local explicit="${1:-}"

  if [ -n "$explicit" ]; then
    printf '%s\n' "$explicit"
    return 0
  fi

  case "${PANE_CONTEXT_TARGET:-${HERDR_PANE_CONTEXT_TARGET:-}}" in
  focused | ui-focused)
    pane_context_focused_pane_id && return 0
    ;;
  esac

  if [ -n "${HERDR_PANE_ID:-}" ]; then
    printf '%s\n' "$HERDR_PANE_ID"
    return 0
  fi

  pane_context_focused_pane_id
}

pane_context_pane_agent() {
  local pane_id="$1"
  command -v herdr >/dev/null 2>&1 || return 1
  pane_context_herdr pane current --pane "$pane_id" 2>/dev/null | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    raise SystemExit(1)
pane = (data.get("result") or {}).get("pane") or {}
agent = pane.get("agent")
if isinstance(agent, str) and agent:
    print(agent)
' 2>/dev/null
}

pane_context_is_agent_pane() {
  local pane_id="$1"
  local agent
  agent=$(pane_context_pane_agent "$pane_id" 2>/dev/null || true)
  case "$agent" in
  claude | cursor | agent) return 0 ;;
  esac
  return 1
}

pane_context_worktree_name() {
  local cwd="${1:-${PWD}}"
  local toplevel primary

  toplevel=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || return 1

  case "$toplevel" in
  */.cursor/worktrees/* | */.claude/worktrees/* | */worktrees/* | */.worktrees/*)
    basename "$toplevel"
    return 0
    ;;
  esac

  primary=$(git -C "$cwd" worktree list --porcelain 2>/dev/null | awk '/^worktree / { print $2; exit }')
  if [ -n "$primary" ] && [ "$toplevel" != "$primary" ]; then
    basename "$toplevel"
    return 0
  fi

  return 1
}

pane_context_report_metadata() {
  local pane_id="$1"
  shift
  command -v herdr >/dev/null 2>&1 || return 0
  pane_context_herdr pane report-metadata "$pane_id" --source "$PANE_CONTEXT_SOURCE" "$@" >/dev/null 2>&1 || true
}

pane_context_maybe_export_aws() {
  local pane_id="$1"
  local profile="$2"

  if pane_context_is_agent_pane "$pane_id"; then
    return 0
  fi

  if [ -n "${HERDR_PANE_ID:-}" ] && [ "$pane_id" = "$HERDR_PANE_ID" ]; then
    export AWS_PROFILE="$profile"
    export AWS_DEFAULT_PROFILE="$profile"
    return 0
  fi

  if command -v herdr >/dev/null 2>&1; then
    pane_context_herdr pane run "$pane_id" \
      "export AWS_PROFILE=$(printf '%q' "$profile") AWS_DEFAULT_PROFILE=$(printf '%q' "$profile")" \
      >/dev/null 2>&1 || true
  fi
}

parse-aws-from-command() {
  local cmdline="${1:-}"
  [ -n "$cmdline" ] || return 0
  python3 - "$cmdline" <<'PY'
import re, shlex, sys

cmdline = sys.argv[1]

def from_env(text):
    for pat in (
        r'(?:^|[\s;|&]|&&|\|\|)\s*(?:export\s+)?AWS_PROFILE=(["\']?)([^"\';|&\s]+)\1',
        r'AWS_DEFAULT_PROFILE=(["\']?)([^"\';|&\s]+)\1',
    ):
        m = re.search(pat, text)
        if m:
            return m.group(2)
    return ""

def from_flags(text):
    m = re.search(r'(?:^|\s)--profile(?:=|\s+)(["\']?)([^"\';|&\s]+)\1', text)
    if m:
        return m.group(2)
    try:
        parts = shlex.split(text, posix=True)
    except ValueError:
        parts = text.split()
    for i, part in enumerate(parts):
        if part == "--profile" and i + 1 < len(parts):
            return parts[i + 1]
        if part.startswith("--profile="):
            return part.split("=", 1)[1]
    return ""

profile = from_env(cmdline) or from_flags(cmdline)
if profile:
    print(profile)
PY
}

get-aws() {
  local pane_id file
  pane_id=$(pane_context_resolve_pane_id "${1:-}") || return 1
  file=$(pane_context_aws_file "$pane_id")
  if [ -f "$file" ]; then
    tr -d '\n' <"$file"
  fi
}

set-aws() {
  local profile="${1:-}"
  local pane_id file

  pane_id=$(pane_context_resolve_pane_id "${2:-}") || {
    echo "pane_context: could not resolve pane id" >&2
    return 1
  }

  file=$(pane_context_aws_file "$pane_id")
  mkdir -p "$(dirname "$file")"

  if [ -z "$profile" ]; then
    clear-aws "${2:-}"
    return $?
  fi

  printf '%s\n' "$profile" >"$file"
  pane_context_report_metadata "$pane_id" --token "aws=$profile"
  pane_context_maybe_export_aws "$pane_id" "$profile"
}

clear-aws() {
  local pane_id file

  pane_id=$(pane_context_resolve_pane_id "${1:-}") || {
    echo "pane_context: could not resolve pane id" >&2
    return 1
  }

  file=$(pane_context_aws_file "$pane_id")
  rm -f "$file"
  # Clear aws token only — do not --clear-state-labels (would wipe wt/agent labels).
  pane_context_report_metadata "$pane_id" --clear-token aws

  if [ -n "${HERDR_PANE_ID:-}" ] && [ "$pane_id" = "$HERDR_PANE_ID" ]; then
    unset AWS_PROFILE AWS_DEFAULT_PROFILE || true
  fi
}

report-aws() {
  local pane_id profile file wt

  pane_id=$(pane_context_resolve_pane_id "${1:-}") || return 1
  file=$(pane_context_aws_file "$pane_id")

  if [ -f "$file" ]; then
    profile=$(tr -d '\n' <"$file")
    if [ -n "$profile" ]; then
      pane_context_report_metadata "$pane_id" --token "aws=$profile"
      return 0
    fi
  fi

  pane_context_report_metadata "$pane_id" --clear-token aws
}

inject-prefix() {
  local cmdline="${1:-}"
  local profile injected

  [ -n "$cmdline" ] || {
    printf '%s' "$cmdline"
    return 0
  }

  if parse-aws-from-command "$cmdline" | grep -q .; then
    printf '%s' "$cmdline"
    return 0
  fi

  profile=$(get-aws 2>/dev/null || true)
  if [ -z "$profile" ]; then
    printf '%s' "$cmdline"
    return 0
  fi

  injected=$(python3 - "$cmdline" <<'PY'
import re, sys

cmdline = sys.argv[1]
patterns = (
    r'\baws\b',
    r'\baws-vault\b',
    r'\bawless\b',
    r'\bterraform\b',
    r'\btofu\b',
    r'\bterragrunt\b',
    r'\bcdk\b',
    r'\bsam\b',
    r'\bcdklocal\b',
    r'\bpulumi\b',
)
if not any(re.search(p, cmdline) for p in patterns):
    raise SystemExit(1)
if re.search(r'(?:^|[\s;|&]|&&|\|\|)\s*(?:export\s+)?AWS_(?:PROFILE|DEFAULT_PROFILE)=', cmdline):
    raise SystemExit(1)
if re.search(r'(?:^|\s)--profile(?:=|\s+)', cmdline):
    raise SystemExit(1)
print(cmdline)
PY
  ) || {
    printf '%s' "$cmdline"
    return 0
  }

  printf 'AWS_PROFILE=%s %s' "$profile" "$cmdline"
}

set-wt() {
  local name="${1:-}"
  local pane_id title

  pane_id=$(pane_context_resolve_pane_id "${2:-}") || {
    echo "pane_context: could not resolve pane id" >&2
    return 1
  }

  if [ -z "$name" ]; then
    pane_context_report_metadata "$pane_id" --clear-token wt --clear-title
    return 0
  fi

  pane_context_report_metadata "$pane_id" --token "wt=$name"
  title="$name"
  pane_context_report_metadata "$pane_id" --title "$title"

  if command -v herdr >/dev/null 2>&1; then
    pane_context_herdr pane rename "$pane_id" "$name" >/dev/null 2>&1 || true
  fi
}

set-agent() {
  local agent="${1:-}"
  local pane_id display

  pane_id=$(pane_context_resolve_pane_id "${2:-}") || {
    echo "pane_context: could not resolve pane id" >&2
    return 1
  }

  case "$agent" in
  claude)
    display="Claude"
    agent="claude"
    ;;
  cursor | agent)
    display="Cursor"
    agent="cursor"
    ;;
  "")
    pane_context_report_metadata "$pane_id" --clear-token agent --clear-display-agent
    return 0
    ;;
  *)
    echo "pane_context: unknown agent: $agent" >&2
    return 1
    ;;
  esac

  pane_context_report_metadata "$pane_id" \
    --token "agent=$agent" \
    --display-agent "$display"
}

# --- zsh function exports when sourced ---
if [ -n "${ZSH_VERSION:-}" ]; then
  case ${ZSH_EVAL_CONTEXT:-} in
  *:file*)
    :
    ;;
  esac
fi

# --- CLI dispatch ---
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]] || [[ "${0##*/}" == "pane_context.sh" ]]; then
  cmd=${1:-}
  shift || true
  case "$cmd" in
  set-aws) set-aws "$@" ;;
  clear-aws) clear-aws "$@" ;;
  get-aws) get-aws "$@" ;;
  report-aws) report-aws "$@" ;;
  parse-aws-from-command) parse-aws-from-command "$@" ;;
  inject-prefix) inject-prefix "$@" ;;
  set-wt) set-wt "$@" ;;
  set-agent) set-agent "$@" ;;
  focused-pane-id) pane_context_focused_pane_id "$@" ;;
  worktree-name) pane_context_worktree_name "${1:-$PWD}" ;;
  *)
    echo "usage: ${0##*/} {set-aws|clear-aws|get-aws|report-aws|parse-aws-from-command|inject-prefix|set-wt|set-agent} ..." >&2
    exit 1
    ;;
  esac
fi
