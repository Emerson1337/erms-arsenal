#!/bin/sh
input=$(cat)

# ANSI color codes
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
GREEN="\033[32m"
BRIGHT_GREEN="\033[92m"
YELLOW="\033[33m"
RED="\033[31m"
WHITE="\033[97m"
GRAY="\033[90m"

# ---------------------------------------------------------------------------
# Line 1: [Model] 📁 dirname | 🌿 branch
# ---------------------------------------------------------------------------

# Short model name: strip "Claude " prefix and version suffixes like " 3.5 Sonnet"
# Keep just the tier word: Opus, Sonnet, Haiku, etc.
raw_model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
short_model=$(echo "$raw_model" | sed 's/Claude //I' | awk '{print $1}')

cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
dirname=""
branch_segment=""

if [ -n "$cwd" ]; then
  dirname=$(basename "$cwd")
  branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    branch_segment=$(printf " ${GRAY}|${RESET} ${YELLOW}🌿 %s${RESET}" "$branch")
  fi
fi

line1=$(printf "${GREEN}${BOLD}[%s]${RESET} ${WHITE}📁 %s${RESET}%s" \
  "$short_model" "$dirname" "$branch_segment")

# ---------------------------------------------------------------------------
# Line 2: [████▒▒▒▒▒▒] 42% | ⏱ 5h 34% · resets in 2h47m
# ---------------------------------------------------------------------------

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

if [ -n "$used_pct" ]; then
  bar_filled=$(awk "BEGIN {printf \"%.0f\", $used_pct * 0.20}")
  bar_empty=$((20 - bar_filled))

  # Bar fill color shifts with usage
  if [ "$bar_filled" -ge 16 ]; then
    BAR_COLOR="$RED"
  elif [ "$bar_filled" -ge 10 ]; then
    BAR_COLOR="$YELLOW"
  else
    BAR_COLOR="$BRIGHT_GREEN"
  fi

  filled_blocks=""
  i=0
  while [ "$i" -lt "$bar_filled" ]; do
    filled_blocks="${filled_blocks}█"
    i=$((i + 1))
  done

  empty_blocks=""
  i=0
  while [ "$i" -lt "$bar_empty" ]; do
    empty_blocks="${empty_blocks}▒"
    i=$((i + 1))
  done

  pct_int=$(printf "%.0f" "$used_pct")
  bar_str=$(printf "${BAR_COLOR}${filled_blocks}${RESET}${GRAY}${empty_blocks}${RESET}")
  ctx_part=$(printf "%s ${WHITE}${BOLD}%s%%${RESET}" "$bar_str" "$pct_int")
else
  ctx_part=$(printf "${GRAY}▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ --%${RESET}")
fi

# 5h session usage + reset countdown
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
session_part=""

if [ -n "$five_pct" ] && [ -n "$five_resets" ]; then
  now=$(date +%s)
  diff=$((five_resets - now))
  if [ "$diff" -le 0 ]; then
    time_left="resets now"
  else
    hrs=$((diff / 3600))
    mins=$(( (diff % 3600) / 60 ))
    time_left=$(printf "%dh%02dm" "$hrs" "$mins")
  fi

  five_int=$(printf "%.0f" "$five_pct")

  if [ "$five_int" -ge 80 ]; then
    SESSION_COLOR="$RED"
  elif [ "$five_int" -ge 50 ]; then
    SESSION_COLOR="$YELLOW"
  else
    SESSION_COLOR="$BRIGHT_GREEN"
  fi

  session_part=$(printf " ${GRAY}|${RESET} ${YELLOW}⏱ ${SESSION_COLOR}${BOLD}%s%%${RESET} ${GRAY}·${RESET} ${YELLOW}%s${RESET}" \
    "$five_int" "$time_left")
fi

line2=$(printf "%s%s" "$ctx_part" "$session_part")

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
printf "%s\n" "$line1"
printf "%s\n" "$line2"
