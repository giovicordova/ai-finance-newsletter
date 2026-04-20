#!/usr/bin/env bash
# review-edition.sh — structural quality review of a generated edition file.
# Enforces the 1-minute read contract: 250-word daily cap, 500-word weekly cap
# (body only — link text and URLs are excluded from the count).

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ $# -eq 0 ]; then
  echo "Usage: review-edition.sh <path-to-edition.md>"
  echo ""
  echo "Checks the edition meets the 1-minute read spec."
  echo "Exit code = number of failures (0 = all checks pass)."
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

has()       { grep -qi "$1" "$EDITION" >/dev/null 2>&1; }

# Body-word-counter: strip markdown links entirely (both label and URL), drop
# the title line, date line, section dividers, and code fences. Count what's left.
body_words() {
  local scope_file="${1:-$EDITION}"
  sed -E \
    -e 's/\[[^]]*\]\([^)]*\)//g'   `# remove [label](url) entirely` \
    -e '/^#[[:space:]]/d'           `# drop H1 title` \
    -e '/^\*\*[0-9]+ [A-Za-z]+ [0-9]{4}\*\*$/d' `# drop date line` \
    -e '/^[[:space:]]*-{3,}[[:space:]]*$/d' \
    -e '/^```/d' \
    "$scope_file" | wc -w | tr -d ' '
}

IS_FRIDAY=0
has "Weekly Intelligence" && IS_FRIDAY=1

echo "═══════════════════════════════════════"
echo " Edition quality review: $(basename "$EDITION")"
if [ "$IS_FRIDAY" -eq 1 ]; then
  echo " (Friday extended edition detected)"
fi
echo "═══════════════════════════════════════"
echo ""

# ── Sections ──────────────────────────────
echo "── Section Presence ────────────────────"

r=1; has "^## Today" && r=0
check "Section: Today (stories section) present" $r

has "Contrarian";         check "Section: One Contrarian Thought present" $?

if [ "$IS_FRIDAY" -eq 1 ]; then
  has "Weekly Intelligence"; check "Section: Weekly Intelligence (Friday)" $?
fi

# Removed-section guard: these should NOT appear in the new format.
r=0; (has "## Deep Dive" || has "## What to Watch" || has "^## Trajectory") && r=1
check "No removed sections (Deep Dive / What to Watch / Trajectory)" $r

echo ""

# ── Format ────────────────────────────────
echo "── Format Compliance ──────────────────"

stories_section=$(sed -n '/^## Today/,/^## /p' "$EDITION" 2>/dev/null | sed '$d' || true)
bold_count=$(printf "%s\n" "$stories_section" | grep -c '\*\*[^*]\+\*\*' 2>/dev/null || true)
r=1; [ "${bold_count:-0}" -ge 2 ] && r=0
check "Bold headlines in Today section (found $bold_count, need ≥2)" $r

url_count=$(grep -c 'https\?://' "$EDITION" 2>/dev/null || echo 0)
r=1; [ "${url_count:-0}" -ge 1 ] && r=0
check "At least 1 URL present (found $url_count)" $r

digit_lines=$(printf "%s\n" "$stories_section" | grep -c '[0-9]' 2>/dev/null || true)
r=1; [ "${digit_lines:-0}" -ge 2 ] && r=0
check "Key numbers in Today section (lines with digits: $digit_lines, need ≥2)" $r

echo ""

# ── Word count (body only, excludes link text + URLs) ──
echo "── Word Count (body only, 1-minute read gate) ────────"

if [ "$IS_FRIDAY" -eq 1 ]; then
  # Daily portion = everything BEFORE Weekly Intelligence
  daily_portion=$(mktemp); weekly_portion=$(mktemp)
  awk '/^## Weekly Intelligence/{flag=1} !flag{print}' "$EDITION" > "$daily_portion"
  awk '/^## Weekly Intelligence/{flag=1} flag{print}'  "$EDITION" > "$weekly_portion"

  daily_words=$(body_words "$daily_portion")
  weekly_words=$(body_words "$weekly_portion")

  r=1; [ "${daily_words:-0}" -le 260 ] && r=0
  check "Daily body ≤ 260 words (10w slack on 250; actual: $daily_words)" $r

  r=1; [ "${weekly_words:-0}" -le 520 ] && r=0
  check "Weekly body ≤ 520 words (20w slack on 500; actual: $weekly_words)" $r

  rm -f "$daily_portion" "$weekly_portion"
else
  body=$(body_words)
  r=1; [ "${body:-0}" -le 260 ] && r=0
  check "Daily body ≤ 260 words (10w slack on 250; actual: $body)" $r
fi

echo ""

# ── Voice anti-patterns ───────────────────
echo "── Voice Anti-patterns ────────────────"

hedge_count=0
for phrase in "it remains to be seen" "only time will tell" "markets were mixed"; do
  grep -qi "$phrase" "$EDITION" 2>/dev/null && hedge_count=$((hedge_count + 1))
done
r=0; [ "$hedge_count" -gt 0 ] && r=1
check "No hedge phrases (found $hedge_count)" $r

filler_count=0
for phrase in "in conclusion" "as we all know" "it goes without saying" "needless to say"; do
  grep -qi "$phrase" "$EDITION" 2>/dev/null && filler_count=$((filler_count + 1))
done
r=0; [ "$filler_count" -gt 0 ] && r=1
check "No filler phrases (found $filler_count)" $r

exclaim_count=$(grep -c '!' "$EDITION" 2>/dev/null || true)
emoji_count=$(grep -o '[😀-🙏🌀-🗿🚀-🛿🤀-🧿☀-♿✀-➿]' "$EDITION" 2>/dev/null | wc -l | tr -d ' ')
: "${emoji_count:=0}"
r=0; { [ "${exclaim_count:-0}" -gt 3 ] || [ "${emoji_count:-0}" -gt 1 ]; } && r=1
check "No Morning-Brew tone (exclaims: $exclaim_count ≤3, emoji: $emoji_count ≤1)" $r

echo ""

# ── Anti-features ─────────────────────────
echo "── Anti-features ──────────────────────"

ticker_count=$(grep -o '\$[A-Z][A-Z][A-Z]*' "$EDITION" 2>/dev/null | wc -l | tr -d ' ')
: "${ticker_count:=0}"
r=0; [ "${ticker_count:-0}" -gt 0 ] && r=1
check "No \$TICKER symbols (found $ticker_count)" $r

rec_count=0
for phrase in "buy recommendation" "sell recommendation" "we recommend buying" "we recommend selling" "strong buy" "strong sell" "price target"; do
  grep -qi "$phrase" "$EDITION" 2>/dev/null && rec_count=$((rec_count + 1))
done
r=0; [ "$rec_count" -gt 0 ] && r=1
check "No buy/sell recommendation language (found $rec_count)" $r

echo ""

# ── Summary ───────────────────────────────
echo "═══════════════════════════════════════"
printf " Results: %d/%d passed" "$PASS" "$TOTAL"
[ "$FAIL" -gt 0 ] && printf ", %d failed" "$FAIL"
echo ""
echo "═══════════════════════════════════════"

exit "$FAIL"
