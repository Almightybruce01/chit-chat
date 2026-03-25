# Private Elite Command Center (Cloudflare Worker)

GitHub Pages **cannot** keep a password secret (anything in the browser is visible). This Worker checks your password **on Cloudflare’s servers**, sets an **HttpOnly** session cookie, and only then serves report JSON. Your password lives in **Wrangler secrets**, not in the repo.

## What you get

- **No password in HTML or JavaScript** — unlock is `POST /login` with JSON `{ "password": "…" }`.
- **Report API requires session** — `GET /api/latest-report` and `GET /api/history-export` return **401** without a valid cookie.
- **GitHub Pages** shows a **landing page only** (no pipeline JSON there).

## One-time setup

1. Install [Node.js](https://nodejs.org/) and the [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/) (this folder uses `npx wrangler`).
2. From this directory:
   ```bash
   npm install
   npm run prep
   ```
3. Log in and create the worker:
   ```bash
   npx wrangler login
   npx wrangler deploy
   ```
   First deploy may warn about missing secrets — set them next.

4. Set secrets (pick a **strong** password; you can still use `5505` if you want, but it is no longer in source):
   ```bash
   npx wrangler secret put DASHBOARD_PASSWORD
   npx wrangler secret put SESSION_SECRET
   ```
   Use a long random string for `SESSION_SECRET` (e.g. 32+ characters from a password manager).

5. Deploy again so bindings are active:
   ```bash
   npm run deploy
   ```

## Daily use

- Open your Worker URL (shown after deploy), e.g. `https://chit-chat-dashboard.<your-subdomain>.workers.dev/`.
- Enter the password you stored in `DASHBOARD_PASSWORD`.
- **Lock** calls `POST /logout` and clears the cookie.

## Where report JSON comes from

By default the Worker fetches (only **after** login):

- `ops/daily_company/out/latest-report.json`
- `ops/daily_company/out/history-export.json`

from the **public** `main` branch on GitHub. Anyone who guesses those raw URLs could still download them if your repo is public — the Worker stops **casual** use of your dashboard UI, not **determined** scraping of committed files.

**Stronger options:**

- Stop committing those JSON files and upload them to **Workers KV** (uncomment `REPORT_KV` in `wrangler.toml`, create a namespace, bind it). The Worker reads KV first when bound.
- Or set **`REPORT_JSON_URL` / `HISTORY_JSON_URL`** in the Cloudflare dashboard (Worker → Settings → Variables) to a **private** URL only you control.

## Local dashboard (no Worker)

From the repo: `cd ops/daily_company/dashboard && python3 -m http.server 8765` — loads JSON from the same folder (your machine only).
