# AI Finance Daily Briefing — Design Spec (DRAFT)

> **Status:** DRAFT — all sections subject to expert review and iteration before implementation.

---

## 1. System Overview

The system is 3 components:

1. **The Prompt** (`prompt.md`) — A scheduled task prompt that tells Claude how to research, synthesise, format, and quality-check the daily briefing.
2. **The Send Script** (`send.sh`) — Takes generated markdown, converts to HTML email, sends via Resend API.
3. **The Archive** (`editions/`) — Past editions as markdown files. Claude reads the last 7-14 to produce trajectory analysis. The archive IS the memory.

### Daily Flow

```
Claude Code scheduled task fires (6:30 AM EST / 11:30 AM UTC)
  → Claude researches via web search (2-3 minutes)
  → Writes briefing as markdown
  → Saves to editions/YYYY-MM-DD.md
  → Reads last 7-14 editions for trajectory section
  → Runs send.sh to email the briefing
  → Done
```

### Weekly Flow (Fridays)

```
Same trigger, but the prompt detects it's Friday
  → Runs the normal daily briefing PLUS
  → Reads all editions from the past 7 days
  → Appends a "Weekly Intelligence" deep analysis section
  → Saves to editions/weekly/YYYY-Wnn.md
  → Sends the extended edition
```

No database. No API server. No dependencies beyond Claude Code + a Resend API key.

---

## 2. Briefing Format (DRAFT — needs expert review)

Target: 600-900 words. Scannable in 90 seconds. Mobile-first.

```
Subject: [Metric + directional move + implication]
e.g. "NVDA +4% on H200 demand — hyperscaler capex cycle accelerating"

═══════════════════════════════════════════
AI FINANCE BRIEFING — DD Mon YYYY
═══════════════════════════════════════════

[One-line hook: the single most important thing today]

── AI MARKETS ──────────────────────────
NVDA    $142.30   +3.8%   ▲ vol
MSFT    $428.15   +1.2%
GOOGL   $178.90   -0.4%
AMD     $168.50   +2.1%   ▲ vol
TSM     $195.40   +1.7%
BOTZ    $32.80    +2.3%

── FIVE THINGS ─────────────────────────
1. **Bold lead-in** — One sentence context + one key number.
   → https://source-url.com/full-article

2. **Bold lead-in** — One sentence context + one key number.
   → https://source-url.com/full-article

3. **Bold lead-in** — One sentence context + one key number.
   → https://source-url.com/full-article

4. **Bold lead-in** — One sentence context + one key number.
   → https://source-url.com/full-article

5. **Bold lead-in** — One sentence context + one key number.
   → https://source-url.com/full-article

── DEEP DIVE ───────────────────────────
[150-300 words on one story]
[The "so what" for positioning — who wins, who loses,
 what's priced in, what the market might be missing]

── WHAT TO WATCH ───────────────────────
• Earnings: [companies reporting + relevance]
• Data: [economic releases]
• Events: [AI conferences, Fed speakers, regulatory]

── TRAJECTORY ──────────────────────────
[2-3 sentences comparing today's themes against
 the last 7-14 editions. Pattern recognition.]

── ONE CONTRARIAN THOUGHT ──────────────
[2-3 sentences. Clear stance, not hedging.]

═══════════════════════════════════════════
```

### Friday Extended Edition

Adds after the contrarian thought:

```
══ WEEKLY INTELLIGENCE ═════════════════
[500-700 words. Full week review:]
• Dominant themes and how they evolved day by day
• What gained momentum vs what faded
• Structural shifts vs noise
• Forward look: what to position for next week
═══════════════════════════════════════════
```

### Format Rules (DRAFT)

- Lead with the trade, not the tech
- One number per bullet — the one that matters
- Every story gets a full source URL — bare URL for easy tap
- Markets table only includes names that moved meaningfully (skip flat ones)
- Contrarian thought must take a stance, not hedge
- Subject line: informational, not clickbait

---

## 3. Prompt Architecture

The scheduled task prompt runs 4 phases sequentially in a single Claude session:

### Phase 1 — Research

- Web search for AI-in-finance news from the last 24 hours
- Target sources: Bloomberg, Reuters, FT, WSJ, central bank publications, tech earnings/announcements, arxiv q-fin
- Rotating search queries across categories: deals, regulation, earnings mentions, research, infrastructure/chips, enterprise deployment
- Collect full URLs for every story

### Phase 2 — Curate & Rank

- Select the 5 most consequential stories from all findings
- Ranking criteria: "What moves money? What changes positioning? What would a portfolio manager not already know from their Bloomberg Terminal?"
- Select one story for the deep dive — the one with the most second-order implications

### Phase 3 — Trajectory Analysis

- Read the last 7-14 archived editions from `editions/`
- Identify recurring themes, accelerating/decelerating trends
- Write the trajectory section and contrarian thought
- On Fridays: read all 5 editions, write the extended Weekly Intelligence section
- Skip trajectory until 7+ editions exist

### Phase 4 — Format & Send

- Assemble the briefing in the format from Section 2
- Save to `editions/YYYY-MM-DD.md`
- Execute `send.sh` to deliver via Resend

---

## 4. File Structure

```
ai-finance-newsletter/
├── prompt.md                  # The scheduled task prompt (the brain)
├── recipients.json            # Email list ["gio@example.com", ...]
├── send.sh                    # Shell script: md → HTML → Resend API
├── .env                       # RESEND_API_KEY (gitignored)
├── editions/
│   ├── 2026-03-26.md          # Daily archive
│   └── weekly/
│       └── 2026-W13.md        # Friday extended editions
└── docs/
    └── superpowers/specs/
        └── this file
```

### Email Delivery

- **Service:** Resend
- **Recipients:** `recipients.json` — array of email addresses. Swap for Resend audience when scaling.
- **Format:** Minimal HTML preserving monospace/plain aesthetic. Finance people don't want fancy HTML emails.
- **`send.sh`:** Reads latest edition markdown → converts to HTML → sends via `curl` to Resend API → logs success/failure.

### Scheduled Task

- Claude Code desktop scheduled task
- Cron: daily at 6:30 AM EST (11:30 AM UTC)
- Single edition for global audience
- Task command points to `prompt.md`

---

## 5. Risks & Limitations (DRAFT)

| Risk | Impact | Mitigation |
|------|--------|------------|
| Mac asleep at send time | No send | macOS wake schedule, or accept delayed send |
| Web search quality varies | Thin/noisy edition | Prompt handles thin news days gracefully (shorter output, no padding) |
| No real-time market data | Markets table is approximate/delayed | Frame as directional, not trading-grade |
| Source URLs may break | Dead links in briefing | Prompt instructs URL verification, but not bulletproof |
| Trajectory needs history | No trajectory first 2 weeks | Skip section until 7+ editions exist |

### What This System Is NOT

- Not a trading signal
- Not real-time
- Not a replacement for Bloomberg Terminal
- It's a curated morning read that saves 30+ minutes of scanning multiple sources

---

## 6. Iteration Path

1. Launch with pure prompt approach (Approach A)
2. Expert reviews the draft format, tweak
3. Run for 2 weeks, review edition quality
4. If source quality is weak → upgrade to Firecrawl MCP tools
5. If outgrow local → move to GitHub Actions

---

## 7. Competitive Landscape

**Existing products and the gap:**

| Product | What it does | Gap this fills |
|---------|-------------|----------------|
| Bloomberg Daybreak | General markets, unbeatable on speed | Not AI-specific |
| Matt Levine's Money Stuff | Finance commentary, great voice | Not AI-focused, not daily data |
| The Daily Shot (WSJ) | Chart-heavy macro | No AI lens |
| Linas's Newsletter | Fintech + AI, 120k subs | Human-written, broader than AI-finance, VC-oriented not institutional |
| Import AI / The Neuron | AI newsletters | Tech perspective, not markets perspective |

**The whitespace:** AI as it directly impacts financial markets, from a markets perspective — not a tech blog perspective. Lead with the trade, not the tech.

---

## Research Sources for Expert Review

These are the source tiers the prompt should target:

**Tier 1 — Institutional:**
Bloomberg, Reuters, Financial Times, WSJ, JP Morgan AI Research, Goldman Sachs research

**Tier 2 — Specialist:**
Markets Media, Seeking Alpha, Bank of England/FCA, BIS (Bank for International Settlements)

**Tier 3 — Quality independent:**
Linas's Newsletter, Gradient Flow, Ethan Mollick's "One Useful Thing"

**Academic:**
arxiv.org (cs.CE and q-fin categories)

---

*Design created: 26 March 2026*
*Status: DRAFT — all sections pending expert review and iteration*
