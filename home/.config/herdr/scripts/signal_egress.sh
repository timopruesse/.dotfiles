#!/usr/bin/env bash
# Deep signal-egress module: out-of-session attention pings for spine/hub events.
# Interface is event verbs — not a generic notify.
#
# Usage:
#   signal_egress.sh halt <message>
#   signal_egress.sh changes <message>
#   signal_egress.sh triage <message>
#
# v1 adapters: herdr toast (when server is running), else macOS (osascript),
# Linux/WSL (notify-send, else PowerShell toast). Fire-and-forget so a hung
# backend never blocks the spine.
# Chat adapters (e.g. WhatsApp) are demand-only later ports — do not stub here.
#
# Call sites (orchestrator prose): HANDOFF on HALT/STOP; /my-work watch on
# non-empty CHANGES; /triage-security when parking findings.

set -euo pipefail

usage() {
  echo "usage: signal_egress.sh halt|changes|triage <message>" >&2
  exit 2
}

[[ $# -ge 2 ]] || usage

verb="$1"
shift
message="$*"
message="${message//$'\n'/ }"
[[ -n "$message" ]] || usage

case "$verb" in
  halt) title="Spine HALT"; sound="request" ;;
  changes) title="Hub changes"; sound="done" ;;
  triage) title="Security triage"; sound="request" ;;
  *)
    echo "signal_egress: unknown verb '$verb' (want halt|changes|triage)" >&2
    exit 2
    ;;
esac

# Truncate for OS banners (keep full message on stdout for the parent).
body="$message"
if [[ ${#body} -gt 180 ]]; then
  body="${body:0:177}..."
fi

signal_egress_bg() {
  # Detach so herdr/osascript/notify-send/powershell cannot hang this process.
  (
    "$@" >/dev/null 2>&1 || true
  ) &
  disown 2>/dev/null || true
}

signal_egress_herdr_available() {
  command -v herdr >/dev/null 2>&1 \
    && herdr status server 2>/dev/null | grep -qx 'status: running'
}

signal_egress_deliver_herdr() {
  local t="$1" b="$2" snd="$3"
  signal_egress_herdr_available || return 1
  signal_egress_bg herdr notification show "$t" --body "$b" --sound "$snd"
  return 0
}

signal_egress_deliver_os() {
  local t="$1" b="$2"
  case "$(uname -s)" in
    Darwin)
      if ! command -v osascript >/dev/null 2>&1; then
        return 1
      fi
      local te be
      te="${t//\\/\\\\}"
      te="${te//\"/\\\"}"
      be="${b//\\/\\\\}"
      be="${be//\"/\\\"}"
      signal_egress_bg osascript -e "display notification \"$be\" with title \"$te\""
      return 0
      ;;
    Linux)
      if command -v notify-send >/dev/null 2>&1; then
        signal_egress_bg notify-send --app-name=signal-egress "$t" "$b"
        return 0
      fi
      if { grep -qi microsoft /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]; } \
        && command -v powershell.exe >/dev/null 2>&1; then
        local te be
        te="${t//\'/\'\'}"
        be="${b//\'/\'\'}"
        signal_egress_bg powershell.exe -NoProfile -Command \
          "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > \$null; \
           \$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02); \
           \$texts = \$xml.GetElementsByTagName('text'); \
           \$texts.Item(0).AppendChild(\$xml.CreateTextNode('$te')) > \$null; \
           \$texts.Item(1).AppendChild(\$xml.CreateTextNode('$be')) > \$null; \
           \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml); \
           [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('signal-egress').Show(\$toast)"
        return 0
      fi
      ;;
  esac
  return 1
}

if signal_egress_deliver_herdr "$title" "$body" "$sound" \
  || signal_egress_deliver_os "$title" "$body"; then
  printf 'signal_egress: %s — %s\n' "$verb" "$message"
  exit 0
fi

# Never fail the spine because a banner could not display — log and continue.
printf 'signal_egress: %s — %s (no adapter delivered)\n' "$verb" "$message" >&2
exit 0
