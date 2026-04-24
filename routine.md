Use the ai-finance-briefing skill at `.claude/skills/ai-finance-briefing/SKILL.md` to generate today's AI Finance Briefing. Follow the skill's instructions exactly — it defines the voice, format, word limits, and Friday weekly handling.

After the skill saves the edition:

1. Run `scripts/send-to-telegram.py editions/YYYY-MM-DD.md` to post it to the Telegram channel. This is the only Telegram send, every day of the week — on Fridays the daily file already contains the Weekly Intelligence section, and the `editions/weekly/YYYY-Wnn.md` file is a repo archive only (do **not** send it).
2. Commit the new edition file(s) with message: `chore: Generated daily AI finance briefing for YYYY-MM-DD`
