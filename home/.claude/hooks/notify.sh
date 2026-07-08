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
# OS-aware: macOS prefers terminal-notifier (clicking the banner returns you to
# the session — the exact tmux pane when inside tmux) and falls back to osascript
# (whose banners macOS attributes to Script Editor, so clicks open that) + afplay.
# Linux/WSL falls back to notify-send, then a terminal bell. Never fails the turn
# — always exits 0. Install the mac helper with: brew install terminal-notifier

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
      # Resolve the host terminal's bundle id so a click returns you to it rather
      # than to Script Editor (which owns osascript-posted banners). Inside tmux
      # the interactive env is masked, so fall back to tmux's stored copy.
      term_bundle="${__CFBundleIdentifier:-}"
      if [ -z "$term_bundle" ] && [ -n "${TMUX:-}" ]; then
        term_bundle="$(tmux show-environment -g __CFBundleIdentifier 2>/dev/null | sed 's/^__CFBundleIdentifier=//')"
      fi

      if command -v terminal-notifier >/dev/null 2>&1; then
        # terminal-notifier lets us control what a click does. Inside tmux, jump
        # back to the exact session/window/pane that fired the alert; otherwise
        # just activate the terminal app. Either way, no more Script Editor.
        set -- -title "$title" -message "$msg"
        if [ -n "${TMUX:-}" ] && [ -n "${TMUX_PANE:-}" ]; then
          sess="$(tmux display-message -pt "$TMUX_PANE" '#{session_name}' 2>/dev/null)"
          jump="tmux switch-client -t \"$sess\"; tmux select-window -t $TMUX_PANE; tmux select-pane -t $TMUX_PANE"
          [ -n "$term_bundle" ] && jump="open -b \"$term_bundle\"; $jump"
          set -- "$@" -execute "$jump"
        elif [ -n "$term_bundle" ]; then
          set -- "$@" -activate "$term_bundle"
        fi
        terminal-notifier "$@" >/dev/null 2>&1 || true
      else
        # Fallback: osascript. Still notifies + chimes, but clicking the banner
        # opens Script Editor (macOS attributes it to the script runner). Install
        # terminal-notifier to make clicks return you to the session.
        esc_msg=${msg//\\/\\\\}; esc_msg=${esc_msg//\"/\\\"}
        esc_title=${title//\\/\\\\}; esc_title=${esc_title//\"/\\\"}
        osascript -e "display notification \"${esc_msg}\" with title \"${esc_title}\"" >/dev/null 2>&1 || true
      fi
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
