Use the ai-finance-briefing skill at `.claude/skills/ai-finance-briefing/SKILL.md` to generate today's AI Finance Briefing. Follow the skill's instructions exactly — it defines the voice, format, word limits, and Friday weekly handling.

After the skill saves the edition:

1. Run `scripts/send-to-telegram.py editions/YYYY-MM-DD.md` to post it to the Telegram channel.
2. If today is Friday, also run `scripts/send-to-telegram.py editions/weekly/YYYY-Wnn.md`.
3. Commit the new edition file(s) with message: `chore: Generated daily AI finance briefing for YYYY-MM-DD`
