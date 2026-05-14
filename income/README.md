# Income & monetization

Internal product notes for how Chit Chat Social can make money at scale, alongside the **in-app** sponsored post model and **ops dashboard** controls.

| Doc | Purpose |
| --- | --- |
| [`MONETIZATION_PLAN.md`](MONETIZATION_PLAN.md) | Revenue streams (native ads, AdSense on web, sponsors), cost drivers, and a sanity check for ~1M users. |
| [`SCALE_ECONOMICS.md`](SCALE_ECONOMICS.md) | Illustrative ARPU vs cost buckets and what to build next (campaigns, reporting, billing). |

## Implemented hooks (codebase)

- **Feed posts:** `PostItem.isSponsoredAd`, `sponsorBrandHandle`, `sponsorExternalURL`, `sponsoredSourcePostID` — disclosure (`#ad`) and tap-through to brand (placeholder web URL until in-app brand profiles ship).
- **Monetization Lab + post composer (iOS):** on-device ad copy templates and publish as sponsored posts.
- **Sponsored repost:** repost menu / context menu — paying brand handle + optional offer URL.
- **Private dashboard:** Workers KV key `ads-program-config`, edited under **Ads & AdSense** after unlock; API `GET`/`POST` `/api/ops/ads-config`.

Google **AdSense** belongs on **web surfaces you own** (marketing site, blog, future web client). The dashboard JSON is for coordination and notes; do not embed secrets in the app or in public HTML.
