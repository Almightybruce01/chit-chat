# AI Tech Company — public dashboard

After the first successful **Daily AI Company Report** workflow run, this folder contains:

- `index.html` — dashboard UI
- `latest-report.json` — machine-readable report
- `LATEST_REPORT.md` — same content as Markdown

## Enable GitHub Pages

1. Repo **Settings → Pages**
2. **Source**: Deploy from branch **main** (or default branch)
3. **Folder**: `/docs`
4. Your site: `https://<username>.github.io/<repo>/ai-company/`

If the path 404s, open `ai-company/index.html` explicitly.

## Local preview

```bash
./scripts/daily-company-report.sh
cp ops/daily_company/out/latest-report.json docs/ai-company/
cp ops/daily_company/dashboard/index.html docs/ai-company/
cd docs && python3 -m http.server 8765
# http://localhost:8765/ai-company/
```
