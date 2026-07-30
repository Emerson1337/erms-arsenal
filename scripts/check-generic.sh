#!/usr/bin/env bash
# Guard: fail if anything identifying leaked into this repository.
#
#   bash scripts/check-generic.sh
#
# It greps for PATTERN CLASSES, never for literal values — so this script itself
# carries no IDs, no org names, no handles, and no paths.
#
# Two tiers, because a class that is always a leak should be checked everywhere,
# while a class that appears naturally in code examples should not produce noise
# that trains you to ignore the output:
#
#   TIER 1 — every file, no exceptions. These never legitimately appear here:
#            absolute home paths, chat/workspace object IDs, workspace hosts,
#            non-empty values in config templates.
#
#   TIER 2 — authored files only (see REFERENCE_SKILLS). Ticket keys, long
#            numeric IDs, emails, and foreign GitHub references are ordinary
#            content inside the language/framework reference skills — those are
#            documentation with no integrations, and they were audited clean when
#            imported. In files this arsenal authors, the same patterns are
#            suspicious. If you add a NEW skill under profile/skills, do not add
#            it to REFERENCE_SKILLS — it should be covered by tier 2.
#
# Exit 0 = clean. Exit 1 = at least one hit, printed with file:line.

set -uo pipefail
cd "$(dirname "$0")/.."

# The repo's own address is the single allowed identifier — it is how the
# marketplace gets installed. Read it from git rather than hardcoding it.
SELF_SLUG="$(git config --get remote.origin.url 2>/dev/null \
  | sed -E 's#(git@|https://)github\.com[:/]##; s#\.git$##')"

BASE_EXCLUDES=(
  --exclude-dir=.git
  --exclude-dir=node_modules
  --exclude=check-generic.sh
)

# Imported-verbatim reference documentation: generic best-practice guides, full
# of synthetic code examples, no integrations, no config.
REFERENCE_SKILLS=(
  --exclude-dir=frontend-accessibility-best-practices
  --exclude-dir=frontend-async-best-practices
  --exclude-dir=frontend-internationalization-best-practices
  --exclude-dir=frontend-js-best-practices
  --exclude-dir=frontend-react-best-practices
  --exclude-dir=frontend-react-native-expo-best-practices
  --exclude-dir=frontend-react-router-best-practices
  --exclude-dir=frontend-tailwind-best-practices
  --exclude-dir=frontend-testing-best-practices
  --exclude-dir=owasp-security-check
  --exclude-dir=skill-writing-best-practices
)

fail=0

report() {
  local label="$1" hits="$2"
  if [ -n "$hits" ]; then
    printf '\n✗ %s\n' "$label"
    printf '%s\n' "$hits" | sed 's/^/    /'
    fail=1
  fi
}

# tier1 <label> <regex>
tier1() {
  report "$1" "$(grep -rInE "$2" . "${BASE_EXCLUDES[@]}" 2>/dev/null)"
}

# tier2 <label> <regex>
tier2() {
  report "$1 [authored files]" \
    "$(grep -rInE "$2" . "${BASE_EXCLUDES[@]}" "${REFERENCE_SKILLS[@]}" 2>/dev/null)"
}

# ===== TIER 1 =============================================================

tier1 "Absolute home paths (leak a username and a machine layout)" \
  '(/Users/|/home/)[a-z]'

# Chat/workspace object IDs: a C/D/G/U/T/W prefix then 8+ uppercase
# alphanumerics, at least one of which is a digit (so words like an all-caps
# filename don't match).
report "Chat/workspace object IDs" \
  "$(grep -roInE '\b[CDGUTW][A-Z0-9]{8,}\b' . "${BASE_EXCLUDES[@]}" 2>/dev/null \
     | awk -F: '$NF ~ /[0-9]/')"

tier1 "Workspace-specific hosts" \
  '\b[a-z0-9-]+\.(slack|atlassian|clickup)\.com'

# ===== TIER 2 =============================================================

# Tracker ticket keys (PREFIX-1234). Placeholders like <KEY>-<n> don't match.
# Standards and crypto suite names share the shape, so they're excluded by name.
report "Tracker ticket keys [authored files]" \
  "$(grep -roInE '\b[A-Z]{2,10}-[0-9]{2,6}\b' . "${BASE_EXCLUDES[@]}" "${REFERENCE_SKILLS[@]}" 2>/dev/null \
     | grep -vE ':(AES|SHA|RSA|DSA|ECDSA|HMAC|GCM|CBC|PBKDF|ISO|RFC|UTF|CVE|HTTP|TLS|SSL|SP|NIST|OWASP|WCAG|ES)-[0-9]+$')"

tier2 "Long numeric identifiers" \
  '(^|[^0-9A-Za-z_./:=-])[0-9]{7,}([^0-9A-Za-z_.-]|$)'

tier2 "Email addresses" \
  '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'

# Foreign GitHub references — any owner/repo other than this repo's own address.
hits="$(grep -rIonE '(github\.com[:/])[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+' . \
          "${BASE_EXCLUDES[@]}" "${REFERENCE_SKILLS[@]}" 2>/dev/null \
        | grep -vE '/(anthropics|warpdotdev)/' \
        | grep -vE '<(owner|slug|org|repo)>' \
        | { [ -n "$SELF_SLUG" ] && grep -vF "$SELF_SLUG" || cat; })"
report "GitHub references to other owners/repos [authored files]" "$hits"

# ===== TIER 1: config templates must ship empty ===========================

while IFS= read -r f; do
  # Any string value that isn't empty, a <placeholder>, an a|b|c enum (values
  # may be kebab-case), the $comment key, or a documented structural default.
  hits="$(grep -nE '"[a-zA-Z_$]+"[[:space:]]*:[[:space:]]*"[^"]+"' "$f" \
    | grep -vE '"\$comment"' \
    | grep -vE ':[[:space:]]*"<[^"]*>"' \
    | grep -vE ':[[:space:]]*"[a-z]+(-[a-z]+)*(\|[a-z]+(-[a-z]+)*)+"' \
    | grep -vE '"(tagPrefix|mergeMethod|path|commentTemplate)"' \
    | sed "s|^|$f:|")"
  report "Non-empty value in template $f" "$hits"
done < <(find . -name '*.example.json' -not -path './.git/*')

# ===== verdict ============================================================

if [ "$fail" -eq 0 ]; then
  echo "✓ clean — no identifying values found"
else
  printf '\nReview each hit. If one is a legitimate placeholder or public upstream\nreference, narrow that pattern — do not delete the check.\n'
fi

exit "$fail"
