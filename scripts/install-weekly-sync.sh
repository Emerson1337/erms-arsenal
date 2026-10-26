#!/usr/bin/env bash
# Schedule scripts/weekly-sync.sh on this machine: macOS uses a LaunchAgent,
# Linux uses the user crontab. Re-running replaces the existing schedule.
#
#   bash scripts/install-weekly-sync.sh              # Sundays at 10:00
#   SYNC_WEEKDAY=0 SYNC_HOUR=20 bash scripts/install-weekly-sync.sh
#   bash scripts/install-weekly-sync.sh --uninstall
#
# SYNC_WEEKDAY: 0 = Sunday ... 6 = Saturday. SYNC_HOUR: 0-23, local time.

set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
LOG_DIR="$CONFIG_DIR/arsenal/logs"
LOG="$LOG_DIR/weekly-sync.log"
WEEKDAY="${SYNC_WEEKDAY:-0}"
HOUR="${SYNC_HOUR:-10}"
LABEL="erms-arsenal.weekly-sync"
CRON_TAG="# $LABEL"

install_macos() {
  local plist="$HOME/Library/LaunchAgents/$LABEL.plist"
  local domain="gui/$(id -u)"
  launchctl bootout "$domain/$LABEL" >/dev/null 2>&1 || true
  if [ "${1:-}" = "uninstall" ]; then
    rm -f "$plist"
    echo "Removed the weekly sync LaunchAgent."
    return
  fi
  mkdir -p "$HOME/Library/LaunchAgents" "$LOG_DIR"
  cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$REPO/scripts/weekly-sync.sh</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Weekday</key><integer>$WEEKDAY</integer>
    <key>Hour</key><integer>$HOUR</integer>
    <key>Minute</key><integer>0</integer>
  </dict>
  <key>StandardOutPath</key><string>$LOG</string>
  <key>StandardErrorPath</key><string>$LOG</string>
</dict>
</plist>
PLIST
  launchctl bootstrap "$domain" "$plist"
  echo "Scheduled: weekday $WEEKDAY at $HOUR:00 (runs at next wake if asleep). Log: $LOG"
}

install_linux() {
  local current
  current="$(crontab -l 2>/dev/null | grep -vF "$CRON_TAG" || true)"
  if [ "${1:-}" = "uninstall" ]; then
    printf '%s\n' "$current" | crontab -
    echo "Removed the weekly sync cron entry."
    return
  fi
  mkdir -p "$LOG_DIR"
  printf '%s\n0 %s * * %s bash "%s/scripts/weekly-sync.sh" >> "%s" 2>&1 %s\n' \
    "$current" "$HOUR" "$WEEKDAY" "$REPO" "$LOG" "$CRON_TAG" | sed '/^$/d' | crontab -
  echo "Scheduled: weekday $WEEKDAY at $HOUR:00. Log: $LOG"
}

ACTION=""
[ "${1:-}" = "--uninstall" ] && ACTION="uninstall"

case "$(uname -s)" in
  Darwin) install_macos "$ACTION" ;;
  Linux) install_linux "$ACTION" ;;
  *) echo "Unsupported OS: $(uname -s)"; exit 1 ;;
esac
