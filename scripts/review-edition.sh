#!/usr/bin/env bash
# review-edition.sh — structural quality review of a generated edition file
# Grades against R001-R011 quality criteria. Exit code = number of failures.

# --- Usage ---
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ $# -eq 0 ]; then
  echo "Usage: review-edition.sh <path-to-edition.md>"
  echo ""
  echo "Structurally grades a generated edition file against quality criteria."
  echo "Exit code = number of failures (0 = all checks pass)."
  exit 0
fi

EDITION="$1"

if [ ! -f "$EDITION" ]; then
  echo "Error: file not found: $EDITION"
  exit 99
fi

PASS=0
FAIL=0
TOTAL=0

check() {
  local label="$1"
  local result="$2"  # 0 = pass, non-zero = fail
  TOTAL=$((TOTAL + 1))
  if [ "$result" -eq 0 ]; then
    PASS=$((PASS + 1))
    printf "  ✅  %s\n" "$label"
  else
    FAIL=$((FAIL + 1))
    printf "  ❌  %s\n" "$label"
  fi
}

# Helper: returns 0 if pattern found in edition, 1 if not
has() { grep -qi "$1" "$EDITION" >/dev/null 2>&1; }
has_exact() { grep -q "$1" "$EDITION" >/dev/null 2>&1; }

# Detect if this is a Friday edition (has Weekly Intelligence section)
IS_FRIDAY=0
has "Weekly Intelligence" && IS_FRIDAY=1

echo "═══════════════════════════════════════"
echo " Edition quality review: $(basename "$EDITION")"
if [ "$IS_FRIDAY" -eq 1 ]; then
  echo " (Friday extended edition detected)"
fi
echo "═══════════════════════════════════════"
echo ""

# ─────────────────────────────────────────
# 1. Section Presence
# ─────────────────────────────────────────
echo "── Section Presence ────────────────────"

# Five Things — or Three/Four Things for thin days
r=1
if has "FIVE THINGS" || has "FOUR THINGS" || has "THREE THINGS"; then
  r=0
fi
check "Section: FIVE/FOUR/THREE THINGS present" $r

has "DEEP DIVE";          check "Section: DEEP DIVE present" $?
has "WHAT TO WATCH";      check "Section: WHAT TO WATCH present" $?

# Trajectory or bootstrap note
r=1
if has "TRAJECTORY" || has "bootstrap" || has "not enough prior editions"; then
  r=0
fi
check "Section: TRAJECTORY or bootstrap note" $r

has "CONTRARIAN";         check "Section: CONTRARIAN THOUGHT present" $?

# Friday-only: Weekly Intelligence
if [ "$IS_FRIDAY" -eq 1 ]; then
  has "Weekly Intelligence"; check "Section: Weekly Intelligence (Friday)" $?
fi

echo ""

# ─────────────────────────────────────────
# 2. Format Compliance
# ─────────────────────────────────────────
echo "── Format Compliance ─────────────────"

# Bold lead-ins: **text** pattern in the Five Things section
# Extract lines between THINGS and DEEP DIVE, count bold lead-ins
things_section=$(sed -n '/THINGS/,/DEEP DIVE/p' "$EDITION" 2>/dev/null || true)
bold_count=$(echo "$things_section" | grep -c '\*\*[^*]\+\*\*' 2>/dev/null || true)
r=1
if [ "${bold_count:-0}" -ge 2 ]; then
  r=0
fi
check "Bold lead-ins in Five Things (found $bold_count, need ≥2)" $r

# URL format: → https://
url_count=$(grep -c '→.*https\?://' "$EDITION" 2>/dev/null || true)
r=1
if [ "${url_count:-0}" -ge 1 ]; then
  r=0
fi
check "URLs present with → prefix (found $url_count, need ≥1)" $r

# Key numbers in Five Things items: at least some digits in the section
digit_lines=$(echo "$things_section" | grep -c '[0-9]' 2>/dev/null || true)
r=1
if [ "${digit_lines:-0}" -ge 2 ]; then
  r=0
fi
check "Key numbers in Five Things (lines with digits: $digit_lines, need ≥2)" $r

echo ""

# ─────────────────────────────────────────
# 3. Word Count
# ─────────────────────────────────────────
echo "── Word Count ────────────────────────"

total_words=$(wc -w < "$EDITION" | tr -d ' ')

# Range: 500-1200 (accommodates thin days and Friday extended)
r=1
if [ "$total_words" -ge 500 ] && [ "$total_words" -le 1200 ]; then
  r=0
fi
check "Total word count in 500-1200 range (actual: $total_words)" $r

echo ""

# ─────────────────────────────────────────
# 4. Deep Dive Length
# ─────────────────────────────────────────
echo "── Deep Dive Length ───────────────────"

# Extract Deep Dive section: from DEEP DIVE to the next section header (WHAT TO WATCH)
deep_dive=$(sed -n '/DEEP DIVE/,/WHAT TO WATCH/{/WHAT TO WATCH/d;p;}' "$EDITION" 2>/dev/null || true)
dd_words=$(echo "$deep_dive" | wc -w | tr -d ' ')

r=1
if [ "${dd_words:-0}" -ge 100 ] && [ "${dd_words:-0}" -le 400 ]; then
  r=0
fi
check "Deep Dive word count in 100-400 range (actual: $dd_words)" $r

echo ""

# ─────────────────────────────────────────
# 5. Voice Anti-patterns
# ─────────────────────────────────────────
echo "── Voice Anti-patterns ────────────────"

# Hedge phrases
hedge_count=0
for phrase in "it remains to be seen" "only time will tell" "markets were mixed"; do
  if grep -qi "$phrase" "$EDITION" 2>/dev/null; then
    hedge_count=$((hedge_count + 1))
  fi
done
r=0; [ "$hedge_count" -gt 0 ] && r=1
check "No hedge phrases (found $hedge_count)" $r

# Filler phrases
filler_count=0
for phrase in "in conclusion" "as we all know" "it goes without saying" "needless to say"; do
  if grep -qi "$phrase" "$EDITION" 2>/dev/null; then
    filler_count=$((filler_count + 1))
  fi
done
r=0; [ "$filler_count" -gt 0 ] && r=1
check "No filler phrases (found $filler_count)" $r

# Morning-Brew-goofy markers: excessive emoji, exclamation marks galore
exclaim_count=$(grep -c '!' "$EDITION" 2>/dev/null || true)
emoji_count=$(grep -o '[😀-🙏🌀-🗿🚀-🛿🤀-🧿☀-♿✀-➿]' "$EDITION" 2>/dev/null | wc -l | tr -d ' ')
: "${emoji_count:=0}"
r=0
if [ "${exclaim_count:-0}" -gt 5 ] || [ "${emoji_count:-0}" -gt 3 ]; then
  r=1
fi
check "No Morning-Brew tone (exclaims: $exclaim_count ≤5, emoji: $emoji_count ≤3)" $r

echo ""

# ─────────────────────────────────────────
# 6. Anti-features
# ─────────────────────────────────────────
echo "── Anti-features ──────────────────────"

# No ticker symbols with $ prefix (like $AAPL, $MSFT)
ticker_count=$(grep -o '\$[A-Z][A-Z][A-Z]*' "$EDITION" 2>/dev/null | wc -l | tr -d ' ')
: "${ticker_count:=0}"
r=0; [ "${ticker_count:-0}" -gt 0 ] && r=1
check "No \$TICKER symbols (found $ticker_count)" $r

# No buy/sell recommendation language
rec_count=0
for phrase in "buy recommendation" "sell recommendation" "we recommend buying" "we recommend selling" "strong buy" "strong sell" "price target"; do
  if grep -qi "$phrase" "$EDITION" 2>/dev/null; then
    rec_count=$((rec_count + 1))
  fi
done
r=0; [ "$rec_count" -gt 0 ] && r=1
check "No buy/sell recommendation language (found $rec_count)" $r

echo ""

# ─────────────────────────────────────────
# 7. URL Count
# ─────────────────────────────────────────
echo "── URL Count ──────────────────────────"

total_urls=$(grep -c 'https\?://' "$EDITION" 2>/dev/null || echo 0)
r=1
if [ "${total_urls:-0}" -ge 1 ]; then
  r=0
fi
check "At least 1 URL present (found $total_urls)" $r

echo ""

# ─────────────────────────────────────────
# Summary
# ─────────────────────────────────────────
echo "═══════════════════════════════════════"
printf " Results: %d/%d passed" "$PASS" "$TOTAL"
if [ "$FAIL" -gt 0 ]; then
  printf ", %d failed" "$FAIL"
fi
echo ""
echo "═══════════════════════════════════════"

exit "$FAIL"
