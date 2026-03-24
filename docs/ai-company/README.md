# Chit Chat Social — public dashboard (GitHub Pages)

This folder is **exactly** what GitHub Pages serves at:

## [https://almightybruce01.github.io/chit-chat/ai-company/](https://almightybruce01.github.io/chit-chat/ai-company/)

| File | Role |
|------|------|
| `index.html` | Elite Command Center UI (PIN **5505**) |
| `latest-report.json` | AI pipeline report data |
| `history-export.json` | Run history for the dashboard |
| `LATEST_REPORT.md` | Human-readable report |

**Repo layout:** `docs/ai-company/` on branch `main` → live URL above when Pages uses **`/docs`**.

**Update flow:** edit `ops/daily_company/dashboard/index.html` (and run the report), then:

```bash
./scripts/bootstrap-ai-company.sh
git add docs/ai-company && git commit -m "chore: refresh dashboard" && git push
```

See also: [`../LIVE_DASHBOARD.md`](../LIVE_DASHBOARD.md) and root [`LIVE_URLS.md`](../../LIVE_URLS.md).
