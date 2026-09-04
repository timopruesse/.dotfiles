#!/usr/bin/env bash
# Cursor Agent CLI status line → Oh My Posh (reuse `claude` renderer).
#
# Cursor's StatusLinePayload is Claude-aligned, but OMP's claude segment expects
# integer context percentages (Cursor often sends floats) and has no Auto→resolved
# model rewrite. This adapter normalizes stdin, calculates remaining context
# tokens for AGENT_REMAINING, then renders the shared theme.
set -euo pipefail

CONFIG="${HOME}/.config/ohmyposh/catppuccin.omp.json"

# Statusline is agent UI (not a zsh readline) — theme hides vimode when set.
export CURSOR_AGENT="${CURSOR_AGENT:-1}"

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

# Calculate remaining percentage of pool/quota (e.g. 31.55% 5h (4h 3m)) if available.
export AGENT_POOL="$(echo "$INPUT" | jq -r '
  def fmt_pct:
    if . == null then ""
    else
      (. * 100 | round) as $r |
      ($r / 100 | floor) as $w |
      ($r % 100) as $f |
      if $f == 0 then
        "\($w)%"
      else
        "\($w).\(if $f < 10 then "0" + ($f | tostring) else ($f | tostring) end)%"
      end
    end;

  def reset_secs:
    if . == null then null
    elif (. | type) != "object" then null
    elif .reset_in_seconds != null then .reset_in_seconds
    elif .resets_at != null then ((.resets_at - now) | if . > 0 then . else 0 end)
    elif .reset_time != null then
      if (.reset_time | type) == "number" then
        ((.reset_time - now) | if . > 0 then . else 0 end)
      elif (.reset_time | type) == "string" then
        (((.reset_time | fromdateiso8601?) // 0) - now | if . > 0 then . else 0 end)
      else
        null
      end
    else
      null
    end;

  def fmt_duration:
    if . == null or . <= 0 then
      ""
    else
      (. | floor) as $s |
      ($s / 86400 | floor) as $d |
      (($s % 86400) / 3600 | floor) as $h |
      (($s % 3600) / 60 | floor) as $m |
      if $d > 0 then
        if $h > 0 then " (\($d)d \($h)h)" else " (\($d)d)" end
      elif $h > 0 then
        if $m > 0 then " (\($h)h \($m)m)" else " (\($h)h)" end
      elif $m > 0 then
        " (\($m)m)"
      else
        " (\($s)s)"
      end
    end;

  (
    (.rate_limits // .rate_limit // {}) as $rl |
    (.quota // .pool // {}) as $q |
    ((.model.display_name // .model.id // "") | ascii_downcase) as $m |
    (if ($m | test("claude|gpt|o1|o3|o4|sonnet|opus|haiku|3p")) then true else false end) as $is_3p |
    if $rl.five_hour.used_percentage != null then
      ($rl.five_hour | reset_secs | fmt_duration) as $dur |
      "\(100 - $rl.five_hour.used_percentage | fmt_pct)\(if $dur != "" then $dur else " 5h" end)"
    elif $rl.five_hour.remaining_percentage != null then
      ($rl.five_hour | reset_secs | fmt_duration) as $dur |
      "\($rl.five_hour.remaining_percentage | fmt_pct)\(if $dur != "" then $dur else " 5h" end)"
    elif $rl.seven_day.used_percentage != null then
      ($rl.seven_day | reset_secs | fmt_duration) as $dur |
      "\(100 - $rl.seven_day.used_percentage | fmt_pct)\(if $dur != "" then $dur else " 7d" end)"
    elif ($q | type) == "number" then
      if $q <= 1.0 and $q >= 0 then
        "\($q * 100 | fmt_pct) pool"
      else
        "\($q | fmt_pct) pool"
      end
    elif ($q | type) == "object" and ($q | length) > 0 then
      if $q.remaining_fraction != null or $q.remaining_percentage != null or $q.used_percentage != null then
        (if $q.window != null and $q.window != "" then " " + $q.window else " pool" end) as $win |
        ($q | reset_secs | fmt_duration) as $dur |
        (
          if $q.remaining_fraction != null then
            if $q.remaining_fraction <= 1.0 and $q.remaining_fraction >= 0 then $q.remaining_fraction * 100 else $q.remaining_fraction end
          elif $q.remaining_percentage != null then
            $q.remaining_percentage
          else
            (100 - $q.used_percentage)
          end
        ) as $val |
        if $dur != "" then
          "\($val | fmt_pct)\($dur)"
        else
          "\($val | fmt_pct)\($win)"
        end
      elif ($q.buckets != null) and (($q.buckets | length) > 0) then
        ($q.buckets[0]) as $b |
        (if $b.window != null and $b.window != "" then " " + $b.window else " pool" end) as $win |
        ($b | reset_secs | fmt_duration) as $dur |
        (
          if $b.remaining_fraction != null then
            if $b.remaining_fraction <= 1.0 and $b.remaining_fraction >= 0 then $b.remaining_fraction * 100 else $b.remaining_fraction end
          elif $b.remaining_percentage != null then
            $b.remaining_percentage
          elif $b.used_percentage != null then
            (100 - $b.used_percentage)
          else
            null
          end
        ) as $val |
        if $val == null then
          ""
        elif $dur != "" then
          "\($val | fmt_pct)\($dur)"
        else
          "\($val | fmt_pct)\($win)"
        end
      else
        # Map of quota buckets keyed by name (e.g. gemini-5h, 3p-5h)
        (
          if $is_3p then
            (if $q["3p-5h"] != null then {"k": "3p-5h", "v": $q["3p-5h"]}
             elif $q["3p-weekly"] != null then {"k": "3p-weekly", "v": $q["3p-weekly"]}
             elif $q["gemini-5h"] != null then {"k": "gemini-5h", "v": $q["gemini-5h"]}
             elif $q["gemini-weekly"] != null then {"k": "gemini-weekly", "v": $q["gemini-weekly"]}
             else null end)
          else
            (if $q["gemini-5h"] != null then {"k": "gemini-5h", "v": $q["gemini-5h"]}
             elif $q["gemini-weekly"] != null then {"k": "gemini-weekly", "v": $q["gemini-weekly"]}
             elif $q["3p-5h"] != null then {"k": "3p-5h", "v": $q["3p-5h"]}
             elif $q["3p-weekly"] != null then {"k": "3p-weekly", "v": $q["3p-weekly"]}
             else null end)
          end
          // ($q | to_entries | map(select(.key | test("5h"))) | map({"k": .key, "v": .value}) | .[0])
          // ($q | to_entries | map(select(.key | test("weekly|7d"))) | map({"k": .key, "v": .value}) | .[0])
          // ($q | to_entries | map({"k": .key, "v": .value}) | .[0])
        ) as $match |
        $match.v as $target |
        $match.k as $target_key |
        if $target == null then
          ""
        elif ($target | type) == "number" then
          if $target <= 1.0 and $target >= 0 then
            "\($target * 100 | fmt_pct)"
          else
            "\($target | fmt_pct)"
          end
        elif ($target | type) == "object" then
          (
            if ($target_key | test("5h")) or (($target.window // "") | test("5h")) then
              " 5h"
            elif ($target_key | test("weekly|7d")) or (($target.window // "") | test("weekly|7d")) then
              " 7d"
            elif $target.window != null and $target.window != "" then
              " " + $target.window
            else
              " pool"
            end
          ) as $win |
          ($target | reset_secs | fmt_duration) as $dur |
          (
            if $target.remaining_fraction != null then
              if $target.remaining_fraction <= 1.0 and $target.remaining_fraction >= 0 then $target.remaining_fraction * 100 else $target.remaining_fraction end
            elif $target.remaining_percentage != null then
              $target.remaining_percentage
            elif $target.used_percentage != null then
              (100 - $target.used_percentage)
            else
              null
            end
          ) as $val |
          if $val == null then
            ""
          elif $dur != "" then
            "\($val | fmt_pct)\($dur)"
          else
            "\($val | fmt_pct)\($win)"
          end
        else
          ""
        end
      end
    else
      ""
    end
  )
' 2>/dev/null || true)"

# Floor float percentages; null output tokens → 0; enrich Auto model label.
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
  | .model as $m
  | ($m.display_name // $m.id // "?") as $shown
  | ($m.id // "") as $id
  | (
      $m.resolved_display_name
      // $m.resolved_name
      // $m.actual_display_name
      // $m.actual_model
      // $m.routed_model
      // $m.underlying_model
      // ""
    ) as $resolved
  | .model.display_name = (
      if ($resolved != "") and (($resolved | ascii_downcase) != ($shown | ascii_downcase)) then
        "\($shown)→\($resolved)"
      elif (($shown | ascii_downcase) == "auto")
           and ($id != "")
           and (($id | ascii_downcase) != "auto") then
        "Auto (\($id))"
      else
        $shown
      end
      | if ($m.param_summary // "") != "" then . + " \($m.param_summary)" else . end
      | if $m.max_mode == true then . + " · max" else . end
    )
' | oh-my-posh claude --config "$CONFIG"
