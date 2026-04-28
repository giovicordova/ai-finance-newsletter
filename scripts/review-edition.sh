#!/usr/bin/env bash
# review-edition.sh — structural quality gate for a generated edition file.
#
# Enforces the Telegram contract from .claude/skills/ai-finance-briefing/SKILL.md:
#   - News post body ≤ 280 chars (excluding URL on its own line) and exactly 1 URL
#   - Take post is OPTIONAL (Friday only). If present:
#       * body ≤ 280 chars including the "Claude's weekly take: " prefix
#       * exactly one URL
#       * starts with "Claude's weekly take:"
#   - Notes section is present
#
# Exit code = number of failures (0 = all checks pass).

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ $# -eq 0 ]; then
  cat <<EOF
Usage: review-edition.sh <path-to-edition.md>

Checks the edition meets the Telegram spec (news post required;
weekly take post optional, Friday only).
EOF
  exit 0
fi

EDITION="$1"

if [ ! -f "$EDITION" ]; then
  echo "Error: file not found: $EDITION"
  exit 99
fi

PASS=0; FAIL=0; TOTAL=0

check() {
  local label="$1"; local result="$2"
  TOTAL=$((TOTAL + 1))
  if [ "$result" -eq 0 ]; then
    PASS=$((PASS + 1)); printf "  ✅  %s\n" "$label"
  else
    FAIL=$((FAIL + 1)); printf "  ❌  %s\n" "$label"
  fi
}

# Extract a section body between "## <heading>" and the next "## " or EOF.
extract_section() {
  local heading="$1"
  awk -v h="$heading" '
    $0 == h { capture=1; next }
    capture && /^## / { exit }
    capture { print }
  ' "$EDITION"
}

# Body chars excluding URL-only lines.
body_chars() {
  printf '%s' "$1" | awk '
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*https?:\/\// { next }
    { gsub(/^[[:space:]]+|[[:space:]]+$/, ""); printf "%s", $0 }
  ' | wc -c | tr -d ' '
}

count_urls() {
  printf '%s' "$1" | grep -cE '^[[:space:]]*https?://' || true
}

NEWS_SECTION=$(extract_section "## Telegram — News Post")
TAKE_SECTION=$(extract_section "## Telegram — Take Post")
NOTES_SECTION=$(extract_section "## Notes (archive only — not sent to Telegram)")

echo "Checking $EDITION"
echo ""

# News post checks
if [ -z "$NEWS_SECTION" ]; then
  check "News post section present" 1
else
  check "News post section present" 0
  NEWS_CHARS=$(body_chars "$NEWS_SECTION")
  NEWS_URLS=$(count_urls "$NEWS_SECTION")
  if [ "$NEWS_CHARS" -le 280 ]; then check "News post body ≤ 280 chars (got $NEWS_CHARS)" 0
  else check "News post body ≤ 280 chars (got $NEWS_CHARS)" 1; fi
  if [ "$NEWS_URLS" -eq 1 ]; then check "News post has exactly 1 URL" 0
  else check "News post has exactly 1 URL (got $NEWS_URLS)" 1; fi
fi

# Take post checks (optional — only validated when present)
if [ -z "$TAKE_SECTION" ]; then
  echo "  ℹ️  Take post section absent (expected Mon-Thu; required Fri)"
else
  TAKE_CHARS=$(body_chars "$TAKE_SECTION")
  TAKE_URLS=$(count_urls "$TAKE_SECTION")
  if [ "$TAKE_CHARS" -le 280 ]; then check "Take post body ≤ 280 chars (got $TAKE_CHARS)" 0
  else check "Take post body ≤ 280 chars (got $TAKE_CHARS)" 1; fi
  if [ "$TAKE_URLS" -eq 1 ]; then check "Take post has exactly 1 URL" 0
  else check "Take post has exactly 1 URL (got $TAKE_URLS)" 1; fi
  if printf '%s' "$TAKE_SECTION" | grep -qE "^Claude's weekly take:"; then
    check "Take post starts with Claude's weekly take: prefix" 0
  else
    check "Take post starts with Claude's weekly take: prefix" 1
  fi
fi

# Notes section
if [ -n "$NOTES_SECTION" ]; then check "Notes section present" 0
else check "Notes section present" 1; fi

echo ""
printf "Result: %d/%d passed\n" "$PASS" "$TOTAL"
exit "$FAIL"
