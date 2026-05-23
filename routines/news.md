Use the ai-finance-briefing skill at `.claude/skills/ai-finance-briefing/SKILL.md` to generate today's AI Finance Briefing. Follow the skill's instructions exactly. It defines the day-of-week gate (Mon-Fri only, weekends skipped), voice, format, character caps, and Friday weekly-take handling.

After the skill saves the edition:

1. Run `scripts/review-edition.sh editions/YYYY-MM-DD.md` to confirm the post(s) are within the 280-char cap and the format is well-formed. Fix any failures before sending.
2. Run `scripts/send-to-telegram.py editions/YYYY-MM-DD.md --section news`. This sends ONLY the news post. On Fridays the take is generated into the same edition file but is held back until the 7 AM take routine.
3. Commit the new edition file(s) with message: `chore: Generated daily AI finance briefing for YYYY-MM-DD`. On Fridays the weekly archive at `editions/weekly/YYYY-Wnn.md` is part of the same commit.
