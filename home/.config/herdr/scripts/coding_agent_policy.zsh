# Shared coding-agent launch policy: keep-awake.
# Sourced by ~/.zshrc wrappers and coding_agent_launch.sh.
# Do not exec — defines coding_agent_keep_awake_run / coding_agent_with_policy.
# Worktree isolation is opt-in via the CLI's own -w / --worktree flags.

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

# Keep-awake + real binary. Worktrees: pass -w / --worktree to the CLI yourself.
# Usage: coding_agent_with_policy claude|agent [args...]
coding_agent_with_policy() {
  local cli="$1"
  shift
  coding_agent_keep_awake_run "$cli" "$@"
}
