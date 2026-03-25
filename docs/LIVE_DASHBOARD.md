# Chit Chat Social — live dashboard (canonical)

This file lives in **`Almightybruce01/chit-chat`** only — the Chit Chat Social project.

## GitHub Pages (public landing only)

**URL:** [https://almightybruce01.github.io/chit-chat/ai-company/](https://almightybruce01.github.io/chit-chat/ai-company/)

- **Stub only** — no report JSON, no `LATEST_REPORT.md` on Pages.
- **Repo path:** `docs/ai-company/index.html`
- **Source of truth in git:** `ops/daily_company/dashboard/index.html` — run `./scripts/bootstrap-ai-company.sh` to copy HTML into `docs/ai-company/` before pushing.

## Private Elite Command Center (Cloudflare Worker + KV)

**Data:** Report JSON exists **only in Workers KV** (keys `latest-report`, `history-export`). It is **not** committed to this public repo and the Worker does **not** read public `raw.githubusercontent.com` URLs.

**Full setup:** **[`docs/PRIVATE_DASHBOARD_SETUP.md`](PRIVATE_DASHBOARD_SETUP.md)**

**Short path:**

1. Create KV namespace, put id in `ops/daily_company/dashboard-worker/wrangler.toml`, commit.
2. `npx wrangler secret put DASHBOARD_PASSWORD` and `SESSION_SECRET` in `dashboard-worker/`.
3. GitHub repo secrets: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, `DASHBOARD_KV_NAMESPACE_ID`.
4. Actions → **Deploy dashboard Worker** (workflow_dispatch).
5. Actions → **Daily AI Company Report** (uploads JSON to KV).

**Technical README:** [`ops/daily_company/dashboard-worker/README.md`](../ops/daily_company/dashboard-worker/README.md)

## Local dashboard (your Mac)

```bash
./scripts/bootstrap-ai-company.sh
cd ops/daily_company/dashboard && python3 -m http.server 8765
```

Open `http://localhost:8765/` — loads JSON from the same folder (no Worker).

## Site root

[https://almightybruce01.github.io/chit-chat/](https://almightybruce01.github.io/chit-chat/) → `docs/index.html` → dashboard folder.

If the link 404s, enable **Settings → Pages → Branch `main` → folder `/docs`**.
