# Rough unit economics (~1M registered users)

These are **order-of-magnitude planning numbers**, not forecasts. Replace with your own CPM, fill rate, and infra quotes.

## Revenue levers (stack them)

| Line | What it is | Notes |
| --- | --- | --- |
| Native sponsored posts | Brands pay for feed slots, IO or self-serve | Highest control; needs moderation and measurement |
| Paid reshares | Organic post + paying brand disclosure + tap-through | Same rails as sponsored posts |
| Creator boosts | Small paid reach | Complements brand ads |
| AdSense (web only) | Display on pages you own | Not a replacement for in-app native ads on iOS |
| B2B / verified business | Subscriptions for tools | Recurring if you invest in the lane |

## Stress-test ARPU (illustrative)

Assume **10–20%** of registered users are **monthly actives** (varies wildly by product).

- If **ad ARPU** on actives is **$0.05–$0.30 / month** (mixed formats, geography, fill), then at **150k MAU** that is roughly **$7.5k–$45k / month** from ads alone before revenue share and refunds.
- **IO deals** (flat monthly minimums from a handful of brands) can anchor cash flow while self-serve ramps.

## Cost buckets to model

1. **Video storage + egress** — often the largest variable at scale.
2. **Push, APIs, worker/DB** — predictable if you cap burst.
3. **Trust & safety** — human review + tooling; scales with reports and ads volume.
4. **Support** — scales with MAU unless heavily self-serve.

**Goal:** keep **variable cost per active user** well below **expected ad + paid-feature ARPU** on that cohort; use IO and B2B to cover fixed engineering until self-serve ads mature.

## Product alignment

- **Ops dashboard** (`ads-program-config` in Workers KV): kill switches and AdSense *coordination* (web), not secrets in the app.
- **App:** sponsored posts behave like normal posts with disclosure and brand tap-through; **For You** still shows sponsored items when a local city filter would otherwise hide non-local organic posts.

When you outgrow templates, add **campaign objects** (budget, pacing, targeting), **impression/click reporting**, and **billing** (e.g. Stripe).
