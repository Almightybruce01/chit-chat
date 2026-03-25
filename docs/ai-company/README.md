# Chit Chat Social — GitHub Pages (`/ai-company/`)

This folder is what GitHub Pages serves at:

## [https://almightybruce01.github.io/chit-chat/ai-company/](https://almightybruce01.github.io/chit-chat/ai-company/)

| File | Role |
|------|------|
| `index.html` | Landing stub + same UI for **local** / **Cloudflare Worker** (no password in source) |
| `LATEST_REPORT.md` | Human-readable report (optional publish) |

**Report JSON** (`latest-report.json`, `history-export.json`) is **not** published here — those paths are gitignored so a public Pages site cannot ship pipeline data. Use:

- **Private dashboard:** `ops/daily_company/dashboard-worker/` (see **README.md** there) — password lives in **Wrangler secrets**.
- **Local:** `ops/daily_company/dashboard/` + `python3 -m http.server` after bootstrap copies JSON into that folder.

**Update flow:** edit `ops/daily_company/dashboard/index.html`, run:

```bash
./scripts/bootstrap-ai-company.sh
git add docs/ai-company && git commit -m "chore: refresh dashboard" && git push
```

See also: [`../LIVE_DASHBOARD.md`](../LIVE_DASHBOARD.md) and root [`LIVE_URLS.md`](../../LIVE_URLS.md).
