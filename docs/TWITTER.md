# Publishing the briefing to X (Twitter)

Notes for swapping or adding X as a distribution channel alongside Telegram.

## What changed in Feb 2026

X retired the old fixed tiers (Free / Basic $200 / Pro $5,000) as the default for new developers and moved to **pay-per-use**. Existing subscribers keep their tier; new sign-ups go straight to pay-per-use.

Source: [X Developers — Announcing Pay-Per-Use Pricing](https://devcommunity.x.com/t/announcing-the-launch-of-x-api-pay-per-use-pricing/256476), [X API pricing docs](https://docs.x.com/x-api/getting-started/pricing).

## Real costs (pay-per-use)

| Action | Cost |
|---|---|
| Create a post (tweet) | **$0.010 per post** |
| Read a post | $0.005 per post |
| Read user profile | $0.010 per user |
| Monthly read cap | 2M posts (above that → Enterprise) |
| Minimum spend | None. No subscription, no contract. |
| Free credit on signup | $10 voucher if migrating from legacy Free tier |

Credits are pre-purchased in the Developer Console and drawn down per request. Same resource within a 24-hour UTC window is deduplicated (not charged twice).

### What our use case actually costs

A daily briefing posts once per day. Format options:

- **Single tweet** (headline + key line): 1 post/day → ~30 posts/month → **$0.30/month**
- **Thread of 5–8 tweets** (full briefing split): ~210 posts/month → **~$2.10/month**
- **Thread of 10 tweets** (long-form): ~300 posts/month → **$3.00/month**

Reads are essentially zero for our use case (we only post). Realistic monthly cost: **under $5**.

For comparison, the legacy Basic tier was $200/month for 10K posts — pay-per-use is ~98% cheaper at our volume.

## What's needed to ship this

1. **X developer account** — sign up at [developer.x.com](https://developer.x.com), create an app, enable OAuth 2.0 in app settings to get Client ID + Secret. ([Elfsight 2026 setup guide](https://elfsight.com/blog/how-to-get-x-twitter-api-key-in-2026/))
2. **Buy credits** in the Developer Console. $10 covers ~3 years of daily threads.
3. **Add `X_API_KEY` / `X_API_SECRET` / `X_BEARER_TOKEN`** (or OAuth 2.0 client creds) to `.env` locally and to the remote scheduler env panel — same pattern as Telegram credentials.
4. **New send script** alongside the Telegram one — calls `POST /2/tweets`. For threads, chain posts via `reply.in_reply_to_tweet_id`.
5. **Decide format** — see below.

## Format decision: single post vs. thread

The briefing today is ~250–500 words. X caps each post at 280 chars.

| Option | Pros | Cons |
|---|---|---|
| **Single teaser tweet** | Higher reach (X algo penalises threads), simple code | Loses the briefing content — you'd need to host the full version somewhere (we don't currently) |
| **Thread (5–10 posts)** | Full briefing on platform, no external hosting | Lower per-post reach, more work to chunk well, ~$2–3/month |
| **Image of full briefing** | Full content in one post, good reach | Not searchable, bad for accessibility |

Recommendation if we go ahead: **thread**, since we already have the full text and no public web home for it. Cost is trivial.

## Open questions before building

- Keep Telegram running in parallel, or replace it? (Adding X is cheap — running both makes sense.)
- Personal account or new dedicated account?
- Who owns the X login / 2FA?

## Sources

- [X Developers — Pay-Per-Use Launch Announcement](https://devcommunity.x.com/t/announcing-the-launch-of-x-api-pay-per-use-pricing/256476)
- [X API Pricing Docs](https://docs.x.com/x-api/getting-started/pricing)
- [Postproxy — X API Pricing in 2026](https://postproxy.dev/blog/x-api-pricing-2026/)
- [WeAreFounders — X API Pricing Every Tier Explained](https://www.wearefounders.uk/the-x-api-price-hike-a-blow-to-indie-hackers/)
- [Elfsight — How to Get X API Key 2026](https://elfsight.com/blog/how-to-get-x-twitter-api-key-in-2026/)
- [Medianama — X Revamps Developer API Pricing](https://www.medianama.com/2026/02/223-x-developer-api-pricing-pay-per-use-model/)
