#!/bin/bash
# Cull leaked `git fsmonitor--daemon` processes on macOS.
# Hundreds of stale daemons exhaust FSEventStream capacity and surface as
# `error: could not read IPC response` on git fetch / zcomet update.
set -eu

count="$(pgrep -lf 'fsmonitor--daemon' 2>/dev/null | wc -l | tr -d ' ')"
count="${count:-0}"

if [ "$count" -gt 50 ]; then
  pkill -f 'fsmonitor--daemon' 2>/dev/null || true
  echo "git fsmonitor: culled ${count} daemon(s)"
else
  echo "git fsmonitor: ${count} daemon(s), ok"
fi
