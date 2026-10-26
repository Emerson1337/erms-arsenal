#!/usr/bin/env bash
# Weekly sync: bring this machine's Claude Code setup back into the arsenal as one
# rolling pull request. Run by the scheduler that scripts/install-weekly-sync.sh
# installs; safe to run by hand.
#
#   bash scripts/weekly-sync.sh            # sync and open/update the PR
#   bash scripts/weekly-sync.sh --dry-run  # sync locally, push nothing
#
# Exit 0 = PR opened/updated or nothing to sync. Non-zero = something needs a look;
# the reason is in the log and in a desktop notification.

set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
BRANCH="arsenal-sync"
BASE="main"
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

notify() {
  echo "[arsenal-sync] $1"
  command -v osascript >/dev/null && osascript -e "display notification \"$1\" with title \"Arsenal sync\"" >/dev/null 2>&1 || true
  command -v notify-send >/dev/null && notify-send "Arsenal sync" "$1" >/dev/null 2>&1 || true
}

fail() {
  notify "$1"
  exit 1
}

for tool in git gh claude; do
  command -v "$tool" >/dev/null || fail "$tool is not installed or not on PATH"
done
gh auth status >/dev/null 2>&1 || fail "gh is not signed in — run gh auth login"

cd "$REPO"
echo "[arsenal-sync] $(date '+%Y-%m-%d %H:%M') starting in $REPO"

git diff --quiet && git diff --cached --quiet || fail "the arsenal clone has uncommitted changes; skipped this week"

AUTH_HEADER="http.https://github.com/.extraheader=Authorization: basic $(printf 'x-access-token:%s' "$(gh auth token)" | base64 | tr -d '\n')"

git -c "$AUTH_HEADER" fetch --quiet origin
git switch --quiet "$BASE"
git merge --quiet --ff-only "origin/$BASE"
git switch --quiet -C "$BRANCH" "origin/$BASE"

SUMMARY="$(mktemp)"
export ARSENAL_SYNC_SUMMARY="$SUMMARY"

claude -p "Run the arsenal-sync skill now, following it exactly." \
  --permission-mode acceptEdits \
  --add-dir "$CONFIG_DIR" \
  --allowedTools "Read" "Write" "Edit" "Glob" "Grep" \
    "Bash(diff *)" "Bash(ls *)" "Bash(find *)" "Bash(cat *)" "Bash(cp *)" "Bash(mkdir *)" \
    "Bash(readlink *)" "Bash(git diff *)" "Bash(git status *)" "Bash(bash scripts/check-generic.sh)" \
  --disallowedTools "Edit(~/.claude/**)" "Bash(git push *)" "Bash(git commit *)" "Bash(rm *)" \
  || fail "the Claude session failed; see the log"

git add -A
git diff --cached --quiet && {
  echo "[arsenal-sync] nothing to sync"
  git switch --quiet "$BASE"
  exit 0
}

bash scripts/check-generic.sh || fail "leak check failed; changes kept on the local $BRANCH branch, nothing pushed"

DATE="$(date +%Y-%m-%d)"
git commit --quiet -m "chore(sync): bring presets up to date with the local setup ($DATE)"

if [ "$DRY_RUN" -eq 1 ]; then
  notify "dry run: changes committed on the local $BRANCH branch, nothing pushed"
  exit 0
fi

git -c "$AUTH_HEADER" push --quiet --force-with-lease origin "$BRANCH"

BODY="$(mktemp)"
{
  echo "## Summary"
  echo
  echo "Weekly sync of the local Claude Code setup into the arsenal ($DATE), rewritten in generic form."
  echo
  cat "$SUMMARY" 2>/dev/null || true
  echo
  echo "## Test plan"
  echo
  echo "### 1. A fresh install picks up the synced presets"
  echo "path: a fresh clone of this branch"
  echo "action: Run \`claude\` in the clone -> type \"/arsenal-setup --check\" -> read the report"
  echo
  echo "| Before | After (expected) |"
  echo "| --- | --- |"
  echo "| Synced items absent from the report | Each synced item listed as new or differs |"
  echo "| — | \`bash scripts/check-generic.sh\` prints clean |"
} > "$BODY"

EXISTING="$(gh pr list --head "$BRANCH" --state open --json number --jq '.[0].number // empty')"
if [ -n "$EXISTING" ]; then
  gh pr edit "$EXISTING" --body-file "$BODY" >/dev/null
  notify "PR #$EXISTING updated with this week's changes"
else
  URL="$(gh pr create --base "$BASE" --head "$BRANCH" --title "chore(sync): weekly preset sync" --body-file "$BODY")"
  notify "opened $URL"
fi

git switch --quiet "$BASE"
