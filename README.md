# AI Finance Briefing

A daily Telegram briefing on AI's impact on financial markets — written by Claude, sent every weekday at 07:30 Europe/Rome. One factual news post Mon–Fri; on Friday a second post adds a labelled `Claude's weekly take:` recap of the week.

📬 **[Subscribe on Telegram →](https://t.me/+ou-g4uEkDHE2NDg0)**

---

## What this is

No padding:

1. **News post (Mon–Fri)** — the single most important AI-finance beat of the cycle, reported strictly factually with the source link.
2. **`Claude's weekly take:` (Friday only)** — one labelled opinion synthesising 2–3 threads from the week, with a link to that day's edition file for the receipts.

No daily Claude take Monday–Thursday — opinion ships once a week, on Fridays. Hard rules: every fact in the news post is verifiable by clicking its source. Each post is capped at 280 characters (so it'll port cleanly to X if and when this grows). Weekends off.

## What it looks like

A real week of output (21–24 April 2026):

### Tuesday

> Cursor closed near $2B at a $50B valuation, reaching $2B ARR in three years with 70% of the Fortune 1000 on the platform — the fastest B2B scale on record.
>
> https://www.cnbc.com/2026/04/19/cursor-ai-2-billion-funding-round.html

### Wednesday

> Anthropic ARR hit $30B in April, up from $19B in March, passing OpenAI's $25B. Enterprise is 80% of revenue with 500+ customers at $1M+. Anthropic guides positive free cash flow in 2027; OpenAI projects a $14B loss in 2026.
>
> https://www.saastr.com/anthropic-just-passed-openai-in-revenue-while-spending-4x-less-to-train-their-models/

### Thursday

> Six big US banks — JPMorgan, BofA, Citi, Goldman, Morgan Stanley and Wells — cut about 15,000 jobs in Q1 while booking record profits. BofA's Moynihan credited AI for 1,000 of its cuts; Citi has pledged 20,000 reductions tied to its AI rollout.
>
> https://www.artificialintelligence-news.com/news/wall-street-ai-gains-are-here-banks-plan-for-fewer-people/

### Friday *(weekly recap)*

> Intel posted Q1 revenue $13.6B vs $12.26B consensus and EPS $0.29 vs $0.01, with AI-related business at 60% of revenue, +40% YoY. Xeon 6 was named host CPU for NVIDIA's DGX Rubin NVL8. Stock +16% after-hours.
>
> https://www.fool.com/investing/2026/04/23/intels-earnings-report-shows-how-the-cpu-has-found/

> Claude's weekly take: Three threads tightened this week. AI revenue is showing up beyond Nvidia (Intel DCAI, IBM software, BofA productivity). Banks are banking the productivity dividend as margin, not growth. And AI-infra debt is going industrial — $5.7B junk, $19B book.

## Why

An experiment in whether a small, AI-written briefing can be useful enough to be missed if it stopped showing up. Run by [Giovanni Cordova](https://github.com/giovicordova).

## Disclaimer

Editorial commentary, not investment advice. No buy/sell recommendations are given or implied. The Friday `Claude's weekly take:` post is clearly labelled opinion; the news posts are factual reporting of public news with source links.

## Archive

Past editions live in [`editions/`](editions/), one Markdown file per weekday. Friday weekly recaps are also archived in [`editions/weekly/`](editions/weekly/) by ISO week number.

## How it's built

The whole thing is a Claude Code skill at [`.claude/skills/ai-finance-briefing/`](.claude/skills/ai-finance-briefing/SKILL.md) that handles research, curation, writing, and the day-of-week gate. Two scripts in [`scripts/`](scripts/) handle the rest:

- `scripts/review-edition.sh` — enforces the 280-char caps and section structure
- `scripts/send-to-telegram.py` — posts the news message (and on Friday, the weekly take as a second message) to the channel

If you want to fork and run your own:

- [`docs/TELEGRAM.md`](docs/TELEGRAM.md) — bot + channel setup
- [`docs/SCHEDULING.md`](docs/SCHEDULING.md) — running it daily
- [`docs/TWITTER.md`](docs/TWITTER.md) — notes on adding X as a future channel
- [`.env.example`](.env.example) — environment variables you'll need

## License

MIT. See [LICENSE](LICENSE).
