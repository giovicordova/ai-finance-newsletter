Use the ai-finance-briefing skill at `.claude/skills/ai-finance-briefing/SKILL.md` to generate today's AI Finance Briefing. Follow the skill's instructions exactly — it defines the day-of-week gate (Mon-Fri only, weekends skipped), voice, format, character caps, and Friday weekly handling.

After the skill saves the edition:

1. Run `scripts/review-edition.sh editions/YYYY-MM-DD.md` to confirm both posts are within the 280-char cap and the format is well-formed. Fix any failures before sending.
2. Run `scripts/send-to-telegram.py editions/YYYY-MM-DD.md` to post both posts (news + take) as two separate Telegram messages. The script reads only the `## Telegram — News Post` and `## Telegram — Take Post` sections; the `## Notes` section is archive-only and never sent.
3. Commit the new edition file(s) with message: `chore: Generated daily AI finance briefing for YYYY-MM-DD`. On Fridays the weekly archive at `editions/weekly/YYYY-Wnn.md` is also part of the same commit.
