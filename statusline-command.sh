#!/bin/bash
# Claude Code status line: model + cost + context + rate limits,
# rendered as unicode gauge bars.

input=$(cat)

IFS=$'\t' read -r model ctx_used ctx_size ctx_pct cost lim_5h lim_7d effort reset_5h reset_7d <<<"$(
  printf '%s' "$input" | jq -r '
    [ (.model.display_name // "-"),
      ((.context_window.current_usage // {})
        | ((.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0))),
      (.context_window.context_window_size // 0),
      ((.context_window.used_percentage // 0) | round),
      (.cost.total_cost_usd // 0),
      ((.rate_limits.five_hour.used_percentage // -1) | round),
      ((.rate_limits.seven_day.used_percentage // -1) | round),
      (.effort.level // "-"),
      (.rate_limits.five_hour.resets_at // 0),
      (.rate_limits.seven_day.resets_at // 0)
    ] | @tsv' | tr -d '\r'
)"

# 49359 -> 49.4k ; 1000000 -> 1.0M
human() {
  awk -v n="$1" 'BEGIN{
    if (n >= 1000000) printf "%.1fM", n/1000000;
    else if (n >= 1000) printf "%.1fk", n/1000;
    else printf "%d", n;
  }'
}

# Filled/empty blocks for a percentage. $1 percent, $2 total cells.
gauge() {
  awk -v p="$1" -v cells="$2" 'BEGIN{
    filled = int(p * cells / 100 + 0.5);
    if (p > 0 && filled == 0) filled = 1;
    if (filled > cells) filled = cells;
    for (i = 0; i < filled; i++) printf "▮";
    for (i = filled; i < cells; i++) printf "▯";
  }'
}

# Green under 50%, yellow under 80%, red at/above 80%.
level_color() {
  if [ "$1" -ge 80 ] 2>/dev/null; then printf 203
  elif [ "$1" -ge 50 ] 2>/dev/null; then printf 178
  else printf 71
  fi
}

parts=()

# Model, with the effort level bracketed after it.
if [ "$model" != "-" ]; then
  model_part=$(printf '\033[38;5;245m%s\033[0m' "$model")
  if [ "$effort" != "-" ] && [ -n "$effort" ]; then
    model_part="$model_part$(printf ' \033[38;5;140m[%s]\033[0m' "$effort")"
  fi
  parts+=("$model_part")
fi

if [ -n "$cost" ]; then
  parts+=("$(printf '\033[38;5;180m$%s\033[0m' "$(awk -v c="$cost" 'BEGIN{printf "%.2f", c}')")")
fi

# Context: gauge + percent.
if [ "${ctx_size:-0}" -gt 0 ] 2>/dev/null; then
  ctx_color=$(level_color "$ctx_pct")
  parts+=("$(printf '\033[38;5;240mctx\033[0m \033[38;5;%sm%s\033[0m \033[38;5;%sm%s%%\033[0m' \
    "$ctx_color" "$(gauge "$ctx_pct" 8)" \
    "$ctx_color" "$ctx_pct")")
fi

# Rate limits: gauge + percent + reset stamp.
# $1 label, $2 used percent, $3 reset epoch, $4 strftime format for the reset
limit_part() {
  local label=$1 pct=$2 epoch=$3 fmt=$4 color reset=""
  [ -z "$pct" ] && return
  [ "$pct" -lt 0 ] 2>/dev/null && return
  color=$(level_color "$pct")
  if [ "${epoch:-0}" -gt 0 ] 2>/dev/null; then
    reset=$(date -d "@$epoch" "+$fmt" 2>/dev/null || date -r "$epoch" "+$fmt" 2>/dev/null)
    [ -n "$reset" ] && reset=" ($reset)"
  fi
  parts+=("$(printf '\033[38;5;240m%s\033[0m \033[38;5;%sm%s %s%%\033[0m\033[38;5;240m%s\033[0m' \
    "$label" "$color" "$(gauge "$pct" 5)" "$pct" "$reset")")
}
limit_part 5h "$lim_5h" "$reset_5h" "%H:%M"
limit_part 7d "$lim_7d" "$reset_7d" "%b %-d"

# Join with a dim pipe separator.
out=""
for p in "${parts[@]}"; do
  if [ -z "$out" ]; then
    out="$p"
  else
    out="$out$(printf '\033[38;5;238m | \033[0m')$p"
  fi
done

printf '%s' "$out"
exit 0
