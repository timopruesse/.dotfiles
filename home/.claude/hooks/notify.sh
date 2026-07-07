#!/usr/bin/env bash
# Claude Code notification hook.
#
# Bridges Claude Code hook events to a desktop notification + sound so the async
# self-looping commands (/babysit-pr, /babysit-fleet, /watch-boba) can run in the
# background and pull you back only when they need your attention.
#
# Usage (from settings.json hooks):
#   bash $HOME/.claude/hooks/notify.sh attention   # Notification event → popup + chime
#
# Only the Notification event is wired (attention-only). The `*` branch below is a
# defensive fallback for any other kind passed in.
#
# OS-aware: macOS uses osascript + afplay; Linux/WSL falls back to notify-send,
# then a terminal bell. Never fails the turn — always exits 0.

kind="${1:-attention}"

# Hook JSON arrives on stdin; pull out the human-readable message if present
# (the Notification event includes one). Best-effort — default if unavailable.
payload="$(cat 2>/dev/null || true)"
msg=""
if command -v python3 >/dev/null 2>&1; then
  msg="$(printf '%s' "$payload" | python3 -c 'import sys,json
try:
    print(json.load(sys.stdin).get("message",""))
except Exception:
    print("")' 2>/dev/null || true)"
fi

case "$kind" in
  attention)
    title="Claude Code — needs you"
    [ -z "$msg" ] && msg="Waiting for your input"
    mac_sound="Glass"
    ;;
  *)
    title="Claude Code"
    [ -z "$msg" ] && msg="$kind"
    mac_sound="Tink"
    ;;
esac

case "$(uname -s)" in
  Darwin)
    afplay "/System/Library/Sounds/${mac_sound}.aiff" >/dev/null 2>&1 &
    # Popup only for attention — a popup on every Stop would spam.
    if [ "$kind" = "attention" ]; then
      esc_msg=${msg//\\/\\\\}; esc_msg=${esc_msg//\"/\\\"}
      esc_title=${title//\\/\\\\}; esc_title=${esc_title//\"/\\\"}
      osascript -e "display notification \"${esc_msg}\" with title \"${esc_title}\"" >/dev/null 2>&1 || true
    fi
    ;;
  *)
    if [ "$kind" = "attention" ] && command -v notify-send >/dev/null 2>&1; then
      notify-send "$title" "$msg" >/dev/null 2>&1 || true
    else
      printf '\a' >&2   # terminal bell fallback
    fi
    ;;
esac

exit 0
