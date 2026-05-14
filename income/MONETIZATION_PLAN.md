# Monetization plan (scale-oriented)

## How Instagram-style apps make money

Meta’s consumer apps monetize mainly through **advertising**: brands pay for reach (feed, Stories, Reels), plus **shopping** and **creator** tools. You are not obligated to copy their exact stack; the lesson is **multiple revenue lines** so traffic spikes do not collapse margin.

## Recommended mix for Chit Chat Social

1. **Native sponsored posts (in feed)**  
   Brands pay for posts or **paid reshares** of organic content, clearly labeled (e.g. “Sponsored”, `#ad`). You control eligibility, pricing, and frequency in product and ops policy.

2. **Direct sponsorships / IO deals**  
   Flat fees for takeovers, series, or category exclusives. Simple to bill; scales with sales, not only MAU.

3. **Self-serve boosts (creators)**  
   Small purchases to amplify reach — complements big-brand sales and uses the same delivery rails as ads.

4. **Google AdSense (and similar) on web**  
   Use on **your website** (help, landing, future web app). AdSense is **not** a substitute for native mobile feed ads; Apple’s IAP rules and UX expectations differ. Keep AdSense configuration and slot notes in the private dashboard KV (`ads-program-config`).

5. **B2B / enterprise**  
   Corporate profiles, hiring, verified business tools — recurring SaaS-style revenue if you invest in that lane.

## Cost reality at ~1 million users

Largest buckets are usually **media storage and egress** (video), **push/infrastructure**, **moderation**, and **support**. Revenue per user from ads must exceed **variable cost per active user** plus a share of fixed engineering. Model with ranges:

- **Ad ARPU** depends on geography, format, and fill; stress-test pessimistic CPMs.
- **Infra** scales with video minutes stored and delivered — compress, tier storage, and cap autoplay quality where possible.

## What we ship in product today (baseline)

- Sponsored post model on `PostItem` + **Monetization Lab** and **Post composer** for AI-style copy (on-device templates) and publish.
- **Sponsored repost** flow with brand handle + optional external URL.
- **Ops dashboard** JSON for program-level flags and AdSense notes (`/api/ops/ads-config`).
- **For You** feed: when the user sets a **local city**, organic posts stay city-scoped; **sponsored posts** still appear (so paid reach is not accidentally zeroed by geography).

Next steps when you are ready: server-side **campaign objects** (budget, targeting, pacing), **reporting** (impressions, clicks), and **billing** (Stripe, invoicing for IO deals).
