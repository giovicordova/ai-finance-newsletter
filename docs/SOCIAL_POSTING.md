# Social posting plan (free, automated)

Goal: cross-post the daily briefing from Telegram to social, automatically, for free.

In scope (this doc): **Threads**, **Instagram** (image cards). Out of scope: X (no longer free since Feb 2026, see `TWITTER.md`), Bluesky, LinkedIn, Mastodon.

## Architecture

Single Python entrypoint called after the existing Telegram send. Each platform = one small module. Fan out. Idempotency guard re-used from the Telegram script (skip if today's post ID is already recorded).

```
scripts/
  send-to-telegram.py        (existing)
  publish-socials.py         (new orchestrator)
  publishers/
    threads.py               (new)
    instagram.py             (new)
    card_renderer.py         (new, shared 1080x1080 PNG card)
state/
  posted.json                (new, per-platform post IDs by date)
```

Routine.md gets one extra step: `python scripts/publish-socials.py` after the Telegram step.

## Threads

### Prerequisites
- Meta developer account at developers.facebook.com (free, instant).
- A Threads account for the new AI finance page, logged in.
- Same person logged in on Meta dev portal and Threads.

### One-time setup
1. developers.facebook.com → My Apps → Create App → use case **"Access the Threads API"** → name it (e.g. `ai-finance-briefing`).
2. App dashboard → Threads → Setup → add the Threads account as a tester, accept invite from the account.
3. App dashboard → Threads → Use API → generate a short-lived user access token (`threads_basic`, `threads_content_publish` scopes).
4. Exchange for a long-lived token (60 days):
   ```
   GET https://graph.threads.net/access_token
     ?grant_type=th_exchange_token
     &client_secret=<APP_SECRET>
     &access_token=<SHORT_LIVED_TOKEN>
   ```
5. Note the `user_id` returned by `GET https://graph.threads.net/v1.0/me?fields=id&access_token=<LONG_TOKEN>`.

### .env additions
```
THREADS_USER_ID=...
THREADS_ACCESS_TOKEN=...
THREADS_APP_SECRET=...           # for token refresh
```

### Publishing flow (two HTTP calls)
1. **Create container**
   ```
   POST https://graph.threads.net/v1.0/{user_id}/threads
     ?media_type=TEXT
     &text=<urlencoded post body, max 500 chars>
     &access_token=<long_token>
   ```
   Response: `{ "id": "<creation_id>" }`

2. **Publish**
   ```
   POST https://graph.threads.net/v1.0/{user_id}/threads_publish
     ?creation_id=<creation_id>
     &access_token=<long_token>
   ```
   Response: `{ "id": "<post_id>" }` → store in `state/posted.json`.

### Token refresh (handled in code)
Run weekly: `GET /refresh_access_token?grant_type=th_refresh_token&access_token=<token>`. Updates `.env` in place. Long-lived token must be at least 24h old before first refresh.

### Limits
- 500 chars per post (we send 280, well under).
- 250 posts per 24h (we do 2).
- No image required for text posts.

## Instagram (image cards)

### Why image cards
IG Graph API requires media (no text-only posts). We render today's briefing as a branded 1080x1080 PNG, host it publicly, and post via the same Meta Graph token system as Threads.

### Prerequisites
- Instagram **Business** account (convert from personal in IG app → Settings → Account type → Switch to Professional → Business).
- A Facebook Page linked to the IG Business account (required by Meta, free, takes 2 min).
- The Meta dev app from the Threads section, with the **Instagram Graph API** product added.

### One-time setup
1. Meta dev app → Add Product → Instagram Graph API.
2. Permissions to request: `instagram_basic`, `instagram_content_publish`, `pages_show_list`, `pages_read_engagement`.
3. Generate user access token via Graph API Explorer, exchange for long-lived (60-day) page token.
4. Get the IG Business account ID:
   ```
   GET /me/accounts?access_token=<TOKEN>       # returns Page IDs
   GET /{page_id}?fields=instagram_business_account&access_token=<TOKEN>
   ```

### .env additions
```
IG_USER_ID=...                   # IG Business account ID, not page ID
IG_ACCESS_TOKEN=...              # long-lived page token
```

### Image hosting (free options, pick one)
- **GitHub raw**: push the PNG to a `cards/` folder in this repo, use `https://raw.githubusercontent.com/...` URL. Free, simple, works since the repo is private only to humans (raw URLs need a token if private, so this needs the repo public OR a dedicated public assets repo).
- **Cloudflare R2**: 10GB free, public bucket, predictable URL. Best choice.
- **Imgur API**: anonymous upload, free, but ToS-fragile for automation.

Recommended: **dedicated public GitHub repo** `ai-finance-cards` for image assets only. Zero cost, zero auth complexity.

### Card rendering
`scripts/publishers/card_renderer.py`:
- Input: today's edition markdown.
- Output: `cards/YYYY-MM-DD.png` (1080x1080).
- Stack: `playwright` (Chromium) renders an HTML template, screenshots the page. Pure-Python alternative: `Pillow` directly, but typography is uglier.
- Template: minimalist, large headline, 2-3 bullet lines, date footer, AI Finance brand mark.

### Publishing flow (two HTTP calls, mirrors Threads)
1. **Create media container**
   ```
   POST https://graph.facebook.com/v21.0/{ig_user_id}/media
     ?image_url=<public PNG URL>
     &caption=<urlencoded caption, up to 2200 chars>
     &access_token=<token>
   ```
2. **Publish**
   ```
   POST https://graph.facebook.com/v21.0/{ig_user_id}/media_publish
     ?creation_id=<creation_id>
     &access_token=<token>
   ```

### Limits
- 25 posts per 24h (more than enough).
- Caption max 2200 chars, 30 hashtags.
- Image must be publicly reachable for 24h (we keep it indefinitely).

## X / Twitter — status

Not implemented under "free only" rule. X moved to pay-per-use in Feb 2026: $0.010 per post = ~$0.30/month for daily briefings. Full notes in `TWITTER.md`. Decision: revisit if Threads + IG traction warrants it.

## Sequence to ship

1. **You**: create Meta dev app, get Threads tester invite accepted, get long-lived Threads token. Drop in `.env`.
2. **Me**: write `publishers/threads.py` + orchestrator + idempotency guard. Wire into routine. Ship + test with one real post.
3. **You**: convert IG to Business, link Facebook Page, add IG Graph API product to the same Meta dev app, generate page token.
4. **Me**: build `card_renderer.py` with the HTML template, set up the public assets repo for image hosting, write `publishers/instagram.py`. Wire in. Test.

Stage 1+2 = ~2 hours total. Stage 3+4 = ~3 hours total. Both stages can ship independently.

## Failure modes to handle in code

- **Token expired**: catch 401, attempt refresh (Threads), then re-post. Log and skip on second failure rather than blocking the routine.
- **Rate limit**: catch 429, log, skip for the day.
- **Duplicate post**: idempotency guard in `state/posted.json` keyed by `(platform, date)`.
- **Image upload race**: IG sometimes 400s if the image URL isn't reachable yet. Add a 10s sleep + 1 retry after pushing the PNG to the public host.
- **Partial failure**: Threads succeeds, IG fails. Routine continues, IG retries next run is not automatic. Log to a daily summary line.

## Sources

- [Threads API: Posts](https://developers.facebook.com/docs/threads/posts) — two-step container+publish flow, 250/day, 500 chars
- [Threads API: Long-lived tokens](https://developers.facebook.com/docs/threads/get-started/long-lived-tokens) — 60-day token + refresh
- [Instagram Graph API: Content Publishing](https://developers.facebook.com/docs/instagram-platform/content-publishing) — image_url + caption, 25/day, 2200 chars
- [Cloudflare R2 free tier](https://developers.cloudflare.com/r2/pricing/) — 10GB storage free
