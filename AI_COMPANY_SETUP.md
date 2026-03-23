# AI Tech Company — all 3 phases (you run **one** script)

Everything is automated. You only need to copy-paste these commands once.

## What you get

| Phase | What it does |
|-------|----------------|
| **1** | Scans your codebase, simulates Product/Eng/Data/DevOps/Security/Growth/QA, CTO picks **one** daily script |
| **2** | Pulls **live trends** (Hacker News + DEV RSS), merges “department” insights, optional **GitHub API** meta |
| **3** | **History JSON** (self-improving memory), optional **OpenAI** executive bullets, **dashboard** + **GitHub Actions** daily |

---

## Step A — Run locally (Mac, in Terminal)

```bash
cd "/Users/brianbruce/Desktop/Chit Chat"
chmod +x scripts/bootstrap-ai-company.sh scripts/daily-company-report.sh
./scripts/bootstrap-ai-company.sh
```

That will:

- `git init` if needed  
- Generate reports under `ops/daily_company/out/`  
- Copy the public dashboard to `docs/ai-company/`  

**Daily** (after you change code):

```bash
./scripts/daily-company-report.sh
```

Skip network (no trends) if offline:

```bash
export PYTHONPATH="$(pwd)/ops"
python3 -m daily_company --root "$(pwd)" --no-trends
```

---

## Step B — Public dashboard (survives if your Mac dies)

1. Create an **empty** repo on GitHub (no README).
2. In Terminal (same folder as this project):

```bash
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git add -A
git commit -m "Chit Chat + AI Company pipeline"
git push -u origin main
```

3. On GitHub: **Settings → Pages → Branch: `main` → Folder `/docs` → Save**
4. Open: **`https://YOUR_USERNAME.github.io/YOUR_REPO/ai-company/`**

The workflow **`.github/workflows/daily-company-report.yml`** runs **every day** and updates the site.

---

## Optional secrets (GitHub → Settings → Secrets → Actions)

| Secret | Effect |
|--------|--------|
| `OPENAI_API_KEY` | Richer executive summary (3–5 bullets via API) |
| *(none)* | `GITHUB_TOKEN` is automatic in Actions for repo API |

---

## Files that matter

- `ops/daily_company/` — Python engine  
- `scripts/bootstrap-ai-company.sh` — first-time setup  
- `scripts/daily-company-report.sh` — daily local run  
- `docs/ai-company/` — what GitHub Pages serves  
- `.github/workflows/daily-company-report.yml` — cloud cron  

---

## Troubleshooting

- **404 on Pages** — Use URL ending in `/ai-company/` or `/ai-company/index.html`
- **Workflow doesn’t push** — Branch protection may block bots; allow GitHub Actions or use a PAT
- **Trends fail in CI** — Transient network; next run succeeds. Use `--no-trends` locally if needed
