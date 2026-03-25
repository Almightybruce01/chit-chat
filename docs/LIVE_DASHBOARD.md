# Chit Chat Social — live dashboard (canonical)

This file lives in **`Almightybruce01/chit-chat`** only — the Chit Chat Social project.

## GitHub Pages (public landing only)

**URL:** [https://almightybruce01.github.io/chit-chat/ai-company/](https://almightybruce01.github.io/chit-chat/ai-company/)

- Shows a **stub** that explains the real dashboard is private. **No** `latest-report.json` / `history-export.json` are published under `docs/ai-company/` (those files are gitignored).
- **Repo path:** `docs/ai-company/index.html`
- **Source of truth in git:** `ops/daily_company/dashboard/index.html` — run `./scripts/bootstrap-ai-company.sh` to copy HTML (+ `LATEST_REPORT.md`) into `docs/ai-company/` before pushing.

## Private Elite Command Center (recommended)

**Why:** A password checked only in the browser is visible in page source. The **Cloudflare Worker** checks your password on the server and sets an **HttpOnly** cookie; report JSON is fetched only after login.

**Deploy:** See **[`ops/daily_company/dashboard-worker/README.md`](../ops/daily_company/dashboard-worker/README.md)** (from repo root).

Summary:

1. `cd ops/daily_company/dashboard-worker && npm install`
2. `npx wrangler login` then `npx wrangler secret put DASHBOARD_PASSWORD` and `npx wrangler secret put SESSION_SECRET`
3. `npm run deploy`
4. Open the `*.workers.dev` URL shown after deploy, enter your password, use **Lock** to log out.

**Default data source:** the Worker pulls JSON from raw `main` on GitHub (`ops/daily_company/out/…`) **after** authentication. If those files stay in a **public** repo, someone could still hit the raw URLs directly — for stronger secrecy, use **Workers KV** or private URLs (Worker README).

## Local dashboard (your Mac)

```bash
./scripts/bootstrap-ai-company.sh
cd ops/daily_company/dashboard && python3 -m http.server 8765
```

Open `http://localhost:8765/` — loads JSON from the same folder (no Worker).

## Site root

[https://almightybruce01.github.io/chit-chat/](https://almightybruce01.github.io/chit-chat/) → `docs/index.html` → dashboard folder.

If the link 404s, enable **Settings → Pages → Branch `main` → folder `/docs`**.
