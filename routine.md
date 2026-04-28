Use the ai-finance-briefing skill at `.claude/skills/ai-finance-briefing/SKILL.md` to generate today's AI Finance Briefing. Follow the skill's instructions exactly — it defines the day-of-week gate (Mon-Fri only, weekends skipped), voice, format, character caps, and Friday weekly handling.

After the skill saves the edition:

1. Run `scripts/review-edition.sh editions/YYYY-MM-DD.md` to confirm the post(s) are within the 280-char cap and the format is well-formed. Fix any failures before sending.
2. Run `scripts/send-to-telegram.py editions/YYYY-MM-DD.md`. Mon-Thu it sends one message (the news post). Friday it sends two (news + `Claude's weekly take:`). The script reads `## Telegram — News Post` (always) and `## Telegram — Take Post` (only if present, Friday only); the `## Notes` section is archive-only and never sent.
3. Commit the new edition file(s) with message: `chore: Generated daily AI finance briefing for YYYY-MM-DD`. On Fridays the weekly archive at `editions/weekly/YYYY-Wnn.md` is also part of the same commit.
