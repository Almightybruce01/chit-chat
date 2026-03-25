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
   npx wrangler secret put OPS_DASHBOARD_PIN   # preferred name; or use DASHBOARD_PASSWORD
   npx wrangler secret put SESSION_SECRET
   ```
   Use **`OPS_DASHBOARD_PIN`** in production. Failed PIN/login attempts are **rate-limited per IP** (KV `opsrl:*` on `REPORT_KV`).

3. **KV populated** — keys `latest-report` and `history-export` (JSON bodies). GitHub Action **Daily AI Company Report** uploads them when repo secrets `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, `DASHBOARD_KV_NAMESPACE_ID` are set. See **[`docs/PRIVATE_DASHBOARD_SETUP.md`](../../../docs/PRIVATE_DASHBOARD_SETUP.md)**.

4. **User pool (optional):** `npx wrangler secret put FIREBASE_SERVICE_ACCOUNT_JSON` — paste the Firebase **service account JSON** (Firestore access). Enables `GET /api/ops/admin/users` and `PATCH /api/ops/admin/users/{uid}` when authenticated (session cookie, **`X-Ops-Pin`**, or **`Authorization: Bearer`** plus a Firebase ID token with `aud` = service account `project_id`). Deploy rules from **`firebase/firestore.rules`**.

## Deploy

```bash
npm install
npm run deploy
```

`npm run deploy` copies `../dashboard/index.html` into `static/` then runs `wrangler deploy`.

## API (same origin as Worker)

**Auth (any):** valid **`X-Ops-Pin`**, or **`Authorization: Bearer`** Firebase ID token (see above), or HttpOnly session after login.

- `POST /api/ops/login` — body `{ "password": "…" }` or header `X-Ops-Pin`, sets session cookie. Legacy: `POST /login`.
- `GET /api/ops/session` — `{ "ok": true }` if authorized. Legacy: `GET /api/session`.
- `GET /api/ops/latest-report` / `GET /api/ops/history-export` — JSON from KV; **401** / **429** when unauthorized or rate-limited; **503** if KV empty. Legacy paths `/api/latest-report`, `/api/history-export` still work.
- `GET /api/ops/admin/users?q=&limit=` — Firestore user directory (requires `FIREBASE_SERVICE_ACCOUNT_JSON`). Legacy `/api/admin/users`.
- `PATCH /api/ops/admin/users/{uid}` — JSON body with allowed fields (`username`, `displayName`, `handle`, `email`, `verificationStatus`, …). Legacy `/api/admin/users/{uid}`.
- `GET /api/ops/dashboard` — metadata / auth hint (no default PINs in JSON).

## Local dashboard (no Cloudflare)

```bash
cd ../dashboard && python3 -m http.server 8765
```

After `./scripts/bootstrap-ai-company.sh` from repo root, JSON sits beside that HTML on your machine only.
