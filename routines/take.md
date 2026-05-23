Friday-only routine. Sends Claude's weekly take, one hour after the daily news post.

Today's edition file (`editions/YYYY-MM-DD.md`) was already generated, reviewed, committed, and the news post sent by the 6 AM news routine. The same file already contains the take section under `## Telegram — Take Post`. No skill invocation, no generation, no commit.

Steps:

1. Confirm `editions/YYYY-MM-DD.md` exists and contains `## Telegram — Take Post`. If either is false, stop and surface the error. Do not regenerate the edition.
2. Run `scripts/send-to-telegram.py editions/YYYY-MM-DD.md --section take`. This sends ONLY the take post. The idempotency log prevents double-sending if the routine fires twice.
