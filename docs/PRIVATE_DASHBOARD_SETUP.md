# Private Elite Command Center — full setup (Chit Chat Social)

Goal: **no report JSON in the public GitHub repo** and **no public raw GitHub URLs** for reports. Data lives in **Cloudflare Workers KV**. The Worker serves the UI and APIs only after **server-side auth**: **`OPS_DASHBOARD_PIN`** (preferred) or legacy **`DASHBOARD_PASSWORD`**, optional **Firebase ID token** (`Authorization: Bearer …`), or an HttpOnly session after **`POST /api/ops/login`**. The dashboard sends **`X-Ops-Pin`** on ops API calls (constant-time compare). **Failed auth** (wrong PIN, bad Bearer, bad session cookie) is **rate-limited per IP**: Firestore **`_opsAuthRate/{ip}`** when **`FIREBASE_SERVICE_ACCOUNT_JSON`** is set, otherwise KV keys **`opsrl:*`**. Anonymous **401** (e.g. first-load session probe with no cookie) does **not** increment the counter. Static GitHub Pages HTML has **no PIN/secrets**—only `noindex` + CSP meta. Optional **Firebase Hosting** headers for a static ops copy: `firebase/firebase.json` (`no-store`, `X-Frame-Options`, `X-Robots-Tag`, CSP on `/ops-dashboard.html` and `/ops/**`).

## One-time checklist

1. **Create KV namespace** — `cd ops/daily_company/dashboard-worker && npx wrangler login && npx wrangler kv namespace create CCS_DASHBOARD_REPORT`
2. **Put the namespace id** in `ops/daily_company/dashboard-worker/wrangler.toml` on the `REPORT_KV` `id = "…"` line (replace the placeholder UUID), then commit and push.
3. **Worker secrets:** `npx wrangler secret put OPS_DASHBOARD_PIN` (or `DASHBOARD_PASSWORD`) and `npx wrangler secret put SESSION_SECRET`
4. **GitHub Actions secrets:** `CLOUDFLARE_API_TOKEN` (token needs **Workers Scripts Edit** + **Workers KV Storage Edit**), `CLOUDFLARE_ACCOUNT_ID`, `DASHBOARD_KV_NAMESPACE_ID` (same UUID as in `wrangler.toml`)
5. **Deploy Worker:** push to `main` (workflow **Deploy dashboard Worker**) or `npm run deploy` in `dashboard-worker/`
6. **Fill KV:** run **Daily AI Company Report** manually in Actions, or upload keys `latest-report` and `history-export` with `wrangler kv key put` (see Cloudflare docs)
7. **User pool (Firestore):** Firebase Console → Project settings → Service accounts → **Generate new private key**. Run `npx wrangler secret put FIREBASE_SERVICE_ACCOUNT_JSON` in `dashboard-worker/` and paste the full JSON. Redeploy the Worker. Deploy Firestore rules: `cd firebase && firebase deploy --only firestore:rules` — rules allow user `users/{uid}` self-access and **deny** client access to **`_opsAuthRate`** (Worker-only counters).
8. **Desktop bookmark:** Copy **`config/DASHBOARD_BOOKMARK_URL.example`** to **`config/DASHBOARD_BOOKMARK_URL`**, set one line to your Worker `https://` URL from `wrangler deploy`, then run **`./scripts/sync-dashboard-webloc.sh`**.
9. **(Optional)** Firebase Hosting for ops static assets: `cd firebase && firebase deploy --only hosting` after placing files under `firebase/hosting-public/`. The Worker remains the primary ops API and HTML source.

**Helper:** `./scripts/apply-dashboard-kv-id.sh YOUR_UUID` updates `wrangler.toml` (run from repo root).

## Reference

| Piece | Where |
|--------|--------|
| Ops PIN | Worker secret `OPS_DASHBOARD_PIN` or `DASHBOARD_PASSWORD` |
| Session HMAC | Worker secret `SESSION_SECRET` |
| Report JSON | KV keys `latest-report`, `history-export` |
| User pool | Firestore `users/{uid}` + Worker `FIREBASE_SERVICE_ACCOUNT_JSON` |
| Public Pages | Stub: `docs/ai-company/index.html` |
| Local UI | `ops/daily_company/dashboard/` + `python3 -m http.server` after bootstrap |

More detail: `ops/daily_company/dashboard-worker/README.md` and `docs/LIVE_DASHBOARD.md`.
