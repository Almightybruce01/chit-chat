# Private Elite Command Center (Cloudflare Worker)

Report data is served **only from Workers KV** after login. There is **no** fallback to public GitHub `raw.githubusercontent.com` URLs.

## Prerequisites

1. **KV namespace** bound in `wrangler.toml` (`REPORT_KV` → real namespace id). Create with:
   ```bash
   npx wrangler kv namespace create CCS_DASHBOARD_REPORT
   ```
   Then set the id in `wrangler.toml` or run from repo root:
   ```bash
   ./scripts/apply-dashboard-kv-id.sh "<paste-id-here>"
   ```

2. **Worker secrets** (not in git):
   ```bash
   npx wrangler secret put DASHBOARD_PASSWORD
   npx wrangler secret put SESSION_SECRET
   ```

3. **KV populated** — keys `latest-report` and `history-export` (JSON bodies). GitHub Action **Daily AI Company Report** uploads them when repo secrets `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, `DASHBOARD_KV_NAMESPACE_ID` are set. See **[`docs/PRIVATE_DASHBOARD_SETUP.md`](../../../docs/PRIVATE_DASHBOARD_SETUP.md)**.

4. **User pool (optional):** `npx wrangler secret put FIREBASE_SERVICE_ACCOUNT_JSON` — paste the Firebase **service account JSON** (Firestore access). Enables `GET /api/admin/users` and `PATCH /api/admin/users/{uid}` after the same dashboard session cookie. Deploy rules from **`firebase/firestore.rules`**.

## Deploy

```bash
npm install
npm run deploy
```

`npm run deploy` copies `../dashboard/index.html` into `static/` then runs `wrangler deploy`.

## API (same origin as Worker)

- `POST /login` — body `{ "password": "…" }`, sets HttpOnly session cookie.
- `GET /api/session` — `{ "ok": true }` if cookie valid.
- `GET /api/latest-report` / `GET /api/history-export` — JSON if logged in and KV has data; **401** if not logged in; **503** if KV empty or unbound.
- `GET /api/admin/users?q=&limit=` — Firestore user directory (requires `FIREBASE_SERVICE_ACCOUNT_JSON`).
- `PATCH /api/admin/users/{uid}` — JSON body with allowed fields (`username`, `displayName`, `handle`, `email`, `verificationStatus`, …).

## Local dashboard (no Cloudflare)

```bash
cd ../dashboard && python3 -m http.server 8765
```

After `./scripts/bootstrap-ai-company.sh` from repo root, JSON sits beside that HTML on your machine only.
