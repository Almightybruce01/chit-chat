# Chit Chat Social — GitHub Pages (`/ai-company/`)

This folder is what GitHub Pages serves at:

## [https://almightybruce01.github.io/chit-chat/ai-company/](https://almightybruce01.github.io/chit-chat/ai-company/)

| File | Role |
|------|------|
| `index.html` | Landing stub + same UI for **local** / **Cloudflare Worker** (no password in source) |

**Report JSON** is **not** in git or on Pages. Private dashboard reads **Workers KV** after login. Use:

- **Private dashboard:** `ops/daily_company/dashboard-worker/` + **`docs/PRIVATE_DASHBOARD_SETUP.md`** — password in **Wrangler secrets**, data in **KV**.
- **Local:** `ops/daily_company/dashboard/` + `python3 -m http.server` after bootstrap copies JSON into that folder.

**Update flow:** edit `ops/daily_company/dashboard/index.html`, run:

```bash
./scripts/bootstrap-ai-company.sh
git add docs/ai-company && git commit -m "chore: refresh dashboard" && git push
```

See also: [`../LIVE_DASHBOARD.md`](../LIVE_DASHBOARD.md) and root [`LIVE_URLS.md`](../../LIVE_URLS.md).
