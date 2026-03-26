#!/usr/bin/env bash
# verify-prompt.sh — structural verification of prompt.md against requirements and decisions

PROMPT="${PROMPT_FILE:-.claude/skills/ai-finance-briefing/SKILL.md}"
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

# Helper: returns 0 if pattern found, 1 if not
has() { grep -qi "$1" "$PROMPT" >/dev/null 2>&1; }
has_exact() { grep -q "$1" "$PROMPT" >/dev/null 2>&1; }

echo "═══════════════════════════════════════"
echo " prompt.md structural verification"
echo "═══════════════════════════════════════"
echo ""

# --- Section presence (6 sections) ---
echo "── Section Presence ────────────────────"

has "Identity.*Voice\|Voice.*Identity";      check "Section: Identity & Voice" $?
has "Format Specification";                   check "Section: Format Specification" $?
has "Phase 1.*Research";                      check "Section: Phase 1 Research" $?
has "Phase 2.*Curate";                        check "Section: Phase 2 Curate & Rank" $?
has "Phase 3.*Trajectory";                    check "Section: Phase 3 Trajectory Analysis" $?
has "Phase 4.*Write.*Save";                   check "Section: Phase 4 Write & Save" $?

echo ""

# --- Requirement coverage ---
echo "── Requirement Coverage ────────────────"

# R002: Voice — office pal / warm / institutional
r=1; has "office pal" && has "warm" && has "institutional" && r=0
check "R002: Voice (office pal + warm + institutional)" $r

# R003: Five Things with bold lead-in and source URLs
r=1; has "FIVE THINGS" && has_exact '\*\*Bold lead-in\*\*' && has_exact '→.*https://' && r=0
check "R003: Five Things format (bold lead-in + source URLs)" $r

# R004: Deep Dive 150-300 words
r=1; has "DEEP DIVE" && has_exact '150.*300\|150–300' && r=0
check "R004: Deep Dive section (150-300 word guidance)" $r

# R005: Trajectory analysis reading prior editions
r=1; has "TRAJECTORY" && has "prior editions" && r=0
check "R005: Trajectory analysis (reads prior editions)" $r

# R006: Contrarian thought — stance / not hedge
r=1; has "CONTRARIAN" && has "stance\|not hedg\|hedging is not" && r=0
check "R006: Contrarian thought (stance, not hedge language)" $r

# R007: Friday detection + Weekly Intelligence
r=1; has "friday" && has "Weekly Intelligence" && r=0
check "R007: Friday detection + Weekly Intelligence section" $r

# R008: Thin-day / no-padding handling
r=1; has "thin.day\|thin day\|fewer than 5" && has "never pad\|no.*pad" && r=0
check "R008: Thin-day / no-padding handling" $r

# R009: URL verification (only URLs actually accessed)
r=1; has "actually accessed\|only.*url.*actually" && r=0
check "R009: URL verification (only URLs actually accessed)" $r

# R010: Archive format editions/YYYY-MM-DD.md
r=1; has_exact 'editions/YYYY-MM-DD\.md' && r=0
check "R010: Archive format (editions/YYYY-MM-DD.md)" $r

# R011: Source tier system with public sources
r=1; has "tier 1" && has "tier 2" && has "tier 3" && r=0
check "R011: Source tier system (Tier 1/2/3)" $r

# R013: Bootstrap / graceful handling < 7 editions
r=1; has "fewer than 7\|bootstrap" && r=0
check "R013: Bootstrap handling (fewer than 7 editions)" $r

echo ""

# --- Decision compliance ---
echo "── Decision Compliance ────────────────"

# D002: No markets price table — prohibition present, no positive build instructions
r=1
if has "never.*price table\|no.*price table"; then
  # Count lines with positive "include/add/create price table" NOT preceded by never/no
  positive=$(grep -i "include.*price table\|add.*price table\|create.*price table" "$PROMPT" 2>/dev/null | grep -iv "never\|not\|no " | wc -l | tr -d ' ')
  [ "${positive:-0}" -eq 0 ] && r=0
fi
check "D002: No markets price table (prohibition present, no positive instructions)" $r

# D003: Office pal voice spec
has "office pal"; check "D003: Office pal voice specification present" $?

# D004: Public sources only — no Bloomberg/FT/Reuters as primary
r=0; has "bloomberg\|financial times\|reuters" && r=1
check "D004: No Bloomberg/FT/Reuters as primary sources" $r

echo ""

# --- Anti-features ---
echo "── Anti-features ──────────────────────"

# R020: No trading signals constraint
r=1; has "never.*trading signal\|no.*trading signal\|not.*advisory" && r=0
check "R020: No trading signals constraint present" $r

echo ""

# --- Directory structure ---
echo "── Directory Structure ─────────────────"

r=0; [ -d "editions" ] || r=1;        check "editions/ directory exists" $r
r=0; [ -d "editions/weekly" ] || r=1;  check "editions/weekly/ directory exists" $r

echo ""

# --- Summary ---
echo "═══════════════════════════════════════"
printf " Results: %d/%d passed" "$PASS" "$TOTAL"
if [ "$FAIL" -gt 0 ]; then
  printf ", %d failed" "$FAIL"
fi
echo ""
echo "═══════════════════════════════════════"

exit "$FAIL"
