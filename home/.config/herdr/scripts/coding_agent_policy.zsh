# Shared coding-agent launch policy: keep-awake + default worktree.
# Sourced by ~/.zshrc wrappers and coding_agent_launch.sh.
# Do not exec — defines coding_agent_keep_awake_run / coding_agent_with_policy.

coding_agent_keep_awake_run() {
  local name_or_path="$1"
  shift
  local resolved
  resolved=$(whence -p "$name_or_path" 2>/dev/null)
  [[ -z "$resolved" && -x "$name_or_path" ]] && resolved="$name_or_path"

  if command -v caffeinate &>/dev/null && [[ -n "$resolved" ]]; then
    caffeinate -i "$resolved" "$@"
    return $?
  fi

  if [[ -n "$WSL_DISTRO_NAME" ]]; then
    local pwsh
    pwsh=$(command -v powershell.exe 2>/dev/null || command -v pwsh.exe 2>/dev/null)
    if [[ -n "$pwsh" ]]; then
      # 2147483649 = ES_CONTINUOUS (0x80000000) | ES_SYSTEM_REQUIRED (0x1)
      "$pwsh" -NoProfile -Command '$s = Add-Type -MemberDefinition "[DllImport(`"kernel32.dll`")] public static extern uint SetThreadExecutionState(uint e);" -Name Power -Namespace Win32 -PassThru; $s::SetThreadExecutionState(2147483649); while ($true) { Start-Sleep 3600 }' &>/dev/null &
      local keepawake_pid=$!
      disown 2>/dev/null
      trap "kill $keepawake_pid 2>/dev/null" EXIT
    fi
  fi

  if [[ -n "$resolved" ]]; then
    "$resolved" "$@"
  else
    command "$name_or_path" "$@"
  fi
}

# Apply --here / worktree defaults, then keep-awake + real binary.
# Usage: coding_agent_with_policy claude|agent [args...]
coding_agent_with_policy() {
  local cli="$1"
  shift
  local args=()
  local force_here=false
  local already_worktree=false

  for arg in "$@"; do
    if [[ "$arg" == "--here" ]]; then
      force_here=true
      continue
    fi
    if [[ "$arg" == "-w" || "$arg" == --worktree || "$arg" == -w=* || "$arg" == --worktree=* ]]; then
      already_worktree=true
    fi
    args+=("$arg")
  done

  if $force_here; then
    coding_agent_keep_awake_run "$cli" "${args[@]}"
    return $?
  fi

  local use_worktree=false
  # One git invocation (inside + toplevel + HEAD). Empty → not a usable repo.
  local rp=()
  rp=(${(f)"$(git rev-parse --is-inside-work-tree --show-toplevel HEAD 2>/dev/null)"})
  if ! $already_worktree && (( ${#rp} >= 3 )) && [[ "${rp[1]}" == true ]]; then
    local repo_root=${rp[2]}
    # Pane launches may not have sourced environment.zsh.
    local dotfiles="${DOTFILES:-${HOME}/github/timopruesse/.dotfiles}"

    if [[ "$repo_root" != "$dotfiles" ]]; then
      use_worktree=true
      local subcommands
      case "$cli" in
      claude)
        subcommands="agents|auth|auto-mode|doctor|install|mcp|plugin|plugins|setup-token|update|upgrade"
        ;;
      agent)
        subcommands="about|create-chat|generate-rule|rule|install-shell-integration|uninstall-shell-integration|login|logout|mcp|models|plugin|status|whoami|update|upgrade|worker"
        ;;
      *)
        subcommands=""
        ;;
      esac
      if [[ -n "$subcommands" ]]; then
        for arg in "${args[@]}"; do
          [[ "$arg" == -* ]] && continue
          [[ "$arg" =~ ^($subcommands)$ ]] && use_worktree=false
          break
        done
      fi
    fi
  fi

  if $use_worktree; then
    case "$cli" in
    claude) coding_agent_keep_awake_run claude "${args[@]}" --worktree ;;
    agent) coding_agent_keep_awake_run agent "${args[@]}" -w ;;
    *) coding_agent_keep_awake_run "$cli" "${args[@]}" ;;
    esac
  else
    coding_agent_keep_awake_run "$cli" "${args[@]}"
  fi
}
