# Chit Chat Elite Launch Plan

## 0) Non-Negotiable Principles

1. Keep user trust first (no ad overload, transparent paid badge, strict safety).
2. Monetize from day one, but make monetization feel native to the product.
3. Focus on one high-value niche first, then expand.
4. Keep infra variable-cost and serverless as long as possible.

---

## 1) First 30 Days (Pre-Scale Setup)

### Product foundations
- Enforce unique usernames for all users.
- Launch two verification types:
  - Paid badge (publicly labeled when tapped).
  - Official internal verified badge (admin-only approval).
- Enable communities (public/private/password).
- Enable shop + live selling + product feed.
- Enable Pulse (public short-post feed).

### Revenue systems to turn on immediately
- Paid verification: $7.99/month.
- Creator tools pro tier: $9.99/month.
- Post boosts:
  - 24h: $5
  - 7d: $15
  - 30d: $39
- Marketplace transaction fee: 4.5%.

### Early distribution
- Start with local creators + schools + service businesses.
- Require first 50 business accounts to buy one paid placement package.

---

## 2) Month 2-3 (Get Cashflow Stable)

### Ad strategy (low-noise, Instagram style)
- Keep ads light:
  - 1 sponsored post every 20-25 feed posts.
  - 1 shop-sponsored placement in product scroll each 15 items.
  - No interstitial spam.
- Sell direct ad placements to local businesses:
  - Featured account: $120/month
  - Feed sponsor slot: $180/month
  - Community sponsor: $250/month

### Sales target
- 25 advertisers x average $180/month = $4,500/month.
- 1,000 paid verifications x $7.99 = $7,990/month gross.
- 400 pro users x $9.99 = $3,996/month gross.

---

## 3) Cost Control Model (Avoid Debt Spiral)

### Infra
- Keep backend on Firebase + serverless functions.
- Media storage: Cloudflare R2 (primary), fallback Wasabi.
- Cache hot feeds and shop pages aggressively.
- Move heavy recommendation jobs to nightly batch runs.

### Budget guardrails
- Cap monthly infra spend at 20% of monthly gross.
- If spend >20%, pause non-essential features and reduce media quality defaults.
- Keep at least 4 months runway in reserve before major hires.

### Operating policy
- No full-time ad sales team until recurring revenue > $25k MRR.
- Use commission-only partner reps first.

---

## 4) Sponsorship and Partnership Track

### Sponsor ladder
1. Local sponsor packs (city-level).
2. Regional brand bundles (multi-city creator campaigns).
3. National partner pilots (sportswear, food, education).

### Partnership assets you need
- Monthly audience report template.
- Community engagement snapshots.
- Shop conversion metrics.
- Brand safety report (nudity blocked, moderation actions).

### Brand categories to prioritize
- Education tools
- Fitness + sports brands
- Food + beverage
- Mobile accessories

---

## 5) 1M User Readiness Plan

### Architecture milestones
- 0-100k users: single-region serverless.
- 100k-500k users: split read/write paths, introduce queue processing.
- 500k-1M users: multi-region read replicas + CDN edge cache + async fanout feeds.

### Team milestones
- 0-100k: founder-led + 1 backend + 1 iOS + 1 moderation ops.
- 100k-500k: add data engineer + trust/safety lead + partner manager.
- 500k-1M: add SRE on-call and commerce ops lead.

---

## 6) Monetization Mix (Balanced, Not Spammy)

Target revenue split:
- 35% subscriptions (paid badge + pro).
- 30% commerce fees (shop + dropship).
- 25% direct ad/sponsor placements.
- 10% boosts and premium discovery.

This keeps UX premium while still funding growth.

---

## 7) Weekly KPI Dashboard (Must Track)

- DAU / MAU
- D1, D7, D30 retention
- Paid verification conversion
- Pro plan conversion
- Shop GMV and take rate
- Ad fill from direct sponsors
- CAC and payback period
- Moderation rate and false positives

If D7 retention drops below 25%, stop adding new monetization surfaces and fix feed quality first.

---

## 8) Immediate Action Checklist

1. Launch paid + official verification system.
2. Start internal admin verification dashboard operations.
3. Enable communities + shop + pulse.
4. Onboard 10 local sponsors before scale ads.
5. Publish creator onboarding kit and pricing page.
6. Run first 30-day city launch campaign.
7. Review KPI dashboard every Monday and Thursday.
