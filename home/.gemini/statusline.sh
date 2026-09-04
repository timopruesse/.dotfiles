#!/usr/bin/env bash
# Antigravity (agy) CLI status line → Oh My Posh (reuse `claude` renderer).
#
# Antigravity's StatusLinePayload is Claude-aligned, but OMP's claude segment expects
# integer context percentages and a structured cost object. This adapter
# normalizes stdin, calculates remaining context tokens for AGENT_REMAINING,
# then renders the shared theme.
set -euo pipefail

CONFIG="${HOME}/.config/ohmyposh/catppuccin.omp.json"

# Statusline is agent UI (not a zsh readline) — theme hides vimode when set.
export AGY_AGENT="${AGY_AGENT:-1}"

if ! command -v oh-my-posh >/dev/null 2>&1; then
  echo "oh-my-posh missing" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq missing" >&2
  exit 1
fi

INPUT="$(cat)"

# Calculate human-readable remaining token count (e.g. 170k, 1.8m) or percentage.
export AGENT_REMAINING="$(echo "$INPUT" | jq -r '
  .context_window as $cw |
  if $cw == null then ""
  elif $cw.context_window_size != null and $cw.context_window_size > 0 then
    (
      if $cw.total_input_tokens != null then
        ($cw.context_window_size - ($cw.total_input_tokens + ($cw.total_output_tokens // 0)))
      elif $cw.remaining_percentage != null then
        ($cw.context_window_size * ($cw.remaining_percentage / 100))
      elif $cw.used_percentage != null then
        ($cw.context_window_size * ((100 - $cw.used_percentage) / 100))
      else
        $cw.context_window_size
      end
    ) as $rem |
    if $rem >= 1000000 then
      "\($rem / 1000000 * 10 | round / 10)m"
    elif $rem >= 10000 then
      "\($rem / 1000 | round)k"
    elif $rem >= 1000 then
      "\($rem / 1000 * 10 | round / 10)k"
    elif $rem > 0 then
      "\($rem | round)"
    else
      "0"
    end
  elif $cw.remaining_percentage != null then
    "\($cw.remaining_percentage | floor)%"
  elif $cw.used_percentage != null then
    "\((100 - $cw.used_percentage) | floor)%"
  else
    ""
  end
' 2>/dev/null || true)"

# Calculate remaining percentage of pool/quota (e.g. 85% pool, 80% 5h) if available.
export AGENT_POOL="$(echo "$INPUT" | jq -r '
  (
    (.rate_limits // .rate_limit // {}) as $rl |
    (.quota // .pool // {}) as $q |
    if $rl.five_hour.used_percentage != null then
      "\((100 - $rl.five_hour.used_percentage) | floor)% 5h"
    elif $rl.five_hour.remaining_percentage != null then
      "\($rl.five_hour.remaining_percentage | floor)% 5h"
    elif $rl.seven_day.used_percentage != null then
      "\((100 - $rl.seven_day.used_percentage) | floor)% 7d"
    elif ($q | type) == "number" then
      if $q <= 1.0 and $q > 0 then
        "\($q * 100 | floor)% pool"
      else
        "\($q | floor)% pool"
      end
    elif ($q | type) == "object" and ($q | length) > 0 then
      if $q.remaining_fraction != null then
        "\($q.remaining_fraction * 100 | floor)%\(if $q.window != null and $q.window != "" then " " + $q.window else " pool" end)"
      elif $q.remaining_percentage != null then
        "\($q.remaining_percentage | floor)%\(if $q.window != null and $q.window != "" then " " + $q.window else " pool" end)"
      elif $q.used_percentage != null then
        "\((100 - $q.used_percentage) | floor)%\(if $q.window != null and $q.window != "" then " " + $q.window else " pool" end)"
      elif ($q.buckets != null) and (($q.buckets | length) > 0) then
        ($q.buckets[0]) as $b |
        if $b.remaining_fraction != null then
          "\($b.remaining_fraction * 100 | floor)%\(if $b.window != null and $b.window != "" then " " + $b.window else " pool" end)"
        elif $b.remaining_percentage != null then
          "\($b.remaining_percentage | floor)%\(if $b.window != null and $b.window != "" then " " + $b.window else " pool" end)"
        elif $b.used_percentage != null then
          "\((100 - $b.used_percentage) | floor)%\(if $b.window != null and $b.window != "" then " " + $b.window else " pool" end)"
        else
          ""
        end
      else
        ""
      end
    else
      ""
    end
  )
' 2>/dev/null || true)"

# Floor float percentages; null output tokens → 0; normalize cost to object.
echo "$INPUT" | jq '
  .context_window as $cw
  | .context_window.used_percentage |= (if . == null then . else floor end)
  | .context_window.remaining_percentage |= (
      if . != null then
        floor
      elif $cw.used_percentage != null then
        (100 - ($cw.used_percentage | floor))
      else
        null
      end
    )
  | .context_window.total_output_tokens |= (if . == null then 0 else . end)
  | if (.cost | type) == "number" then
      .cost = { "total_cost_usd": .cost }
    elif (.cost | type) != "object" then
      .cost = { "total_cost_usd": 0 }
    else
      .
    end
  | .model as $m
  | ($m.display_name // $m.id // "?") as $shown
  | ($m.id // "") as $id
  | .model.display_name = (
      if ($shown | ascii_downcase) == "auto" and ($id != "") and (($id | ascii_downcase) != "auto") then
        "Auto (\($id))"
      else
        $shown
      end
    )
' | oh-my-posh claude --config "$CONFIG"
