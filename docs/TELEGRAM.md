# Telegram Distribution

The daily briefing is posted to a Telegram channel by `scripts/send-to-telegram.py`. Subscribers receive the briefing there.

## One-time setup

### 1. Create the bot

1. Open Telegram, search `@BotFather`, start a chat
2. Send `/newbot`, give it a name (e.g. "AI Finance Briefing") and a username ending in `bot`
3. BotFather replies with an **HTTP API token** — copy it, this is `TELEGRAM_BOT_TOKEN`

### 2. Create the channel

1. In Telegram: **New Channel** → name it → make it **Private** (or public if you prefer a shareable link)
2. Open the channel → **Manage channel** → **Administrators** → **Add Administrator**
3. Search for your bot's username, add it, give it **Post Messages** permission
4. Generate an invite link to share with subscribers (Manage → Invite Links)

### 3. Get the chat ID

Post any message in the channel, then run:

```bash
curl -s "https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates" | python3 -m json.tool
```

Look for `"chat":{"id":-100xxxxxxxxxx,...}` — that number (including the minus) is your `TELEGRAM_CHAT_ID`.

If `getUpdates` returns an empty result, forward a message from the channel to `@RawDataBot` or `@userinfobot` — it will show you the chat ID.

### 4. Store the credentials

Add to `~/.zshrc` (or wherever your shell loads env vars):

```bash
export TELEGRAM_BOT_TOKEN="123456:ABC-your-token-here"
export TELEGRAM_CHAT_ID="-1001234567890"
```

Then `source ~/.zshrc` or open a new terminal.

For Claude Code Desktop scheduled tasks to pick these up, the same variables must be set in the environment the Desktop app inherits — the simplest path is to put them in `~/.zshrc` (or `~/.zprofile`) and relaunch the app.

## Test it

```bash
scripts/send-to-telegram.py editions/2026-03-28.md
```

You should see `sent chunk 1/N` lines and a new message in the channel within a second.

## How it runs daily

The `ai-finance-briefing` skill calls the script at the end of Phase 4, right after saving the edition file. One message per day, every day of the week — on Fridays the daily file already contains the Weekly Intelligence section, and the `editions/weekly/YYYY-Wnn.md` archive file is **not** sent.

## Troubleshooting

- **`Forbidden: bot is not a member of the channel`** — re-add the bot as admin with Post Messages permission
- **`Bad Request: chat not found`** — wrong chat ID; re-check step 3
- **Message looks unformatted** — the script converts markdown to Telegram HTML; if something renders oddly, check the specific line against the conversions in `send-to-telegram.py`
- **Links not clickable** — Telegram needs the bot to have link preview permissions; `disable_web_page_preview` is set to true in the script so only the inline `<a>` links render (this is intentional to keep messages tight)
