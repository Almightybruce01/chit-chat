# Private Elite Command Center — full setup (Chit Chat Social)

Goal: **no report JSON in the public GitHub repo** and **no public raw GitHub URLs** for reports. Data lives in **Cloudflare Workers KV**. The Worker serves the UI and APIs only after a **server-checked password** (Wrangler secrets).

## One-time checklist

1. **Create KV namespace** — `cd ops/daily_company/dashboard-worker && npx wrangler login && npx wrangler kv namespace create CCS_DASHBOARD_REPORT`
2. **Put the namespace id** in `ops/daily_company/dashboard-worker/wrangler.toml` on the `REPORT_KV` `id = "…"` line (replace the placeholder UUID), then commit and push.
3. **Worker secrets:** `npx wrangler secret put DASHBOARD_PASSWORD` and `npx wrangler secret put SESSION_SECRET`
4. **GitHub Actions secrets:** `CLOUDFLARE_API_TOKEN` (token needs **Workers Scripts Edit** + **Workers KV Storage Edit**), `CLOUDFLARE_ACCOUNT_ID`, `DASHBOARD_KV_NAMESPACE_ID` (same UUID as in `wrangler.toml`)
5. **Deploy Worker:** push to `main` (workflow **Deploy dashboard Worker**) or `npm run deploy` in `dashboard-worker/`
6. **Fill KV:** run **Daily AI Company Report** manually in Actions, or upload keys `latest-report` and `history-export` with `wrangler kv key put` (see Cloudflare docs)

**Helper:** `./scripts/apply-dashboard-kv-id.sh YOUR_UUID` updates `wrangler.toml` (run from repo root).

## Reference

| Piece | Where |
|--------|--------|
| Password | Worker secret `DASHBOARD_PASSWORD` |
| Session HMAC | Worker secret `SESSION_SECRET` |
| Report JSON | KV keys `latest-report`, `history-export` |
| Public Pages | Stub: `docs/ai-company/index.html` |
| Local UI | `ops/daily_company/dashboard/` + `python3 -m http.server` after bootstrap |

More detail: `ops/daily_company/dashboard-worker/README.md` and `docs/LIVE_DASHBOARD.md`.
