# Ops — AI Tech Company (Phases 1–3)

## Phase 1 — Scan & simulate

- `scanner.py` walks the repo (skips `DerivedData`, `.git`, etc.)
- `departments.py` rule-based “teams”
- `cto.py` picks **one** script; dedupes using **history**
- CLI: `python3 -m daily_company` (with `PYTHONPATH=ops`)

## Phase 2 — Trends & collaboration

- `trends.py` — HN API + DEV RSS (stdlib `urllib`, no pip)
- `collaboration.py` — priority stack when trends vs engineering conflict
- `github_remote.py` — optional `GITHUB_TOKEN` for repo metadata

## Phase 3 — Memory & optional LLM

- `history_store.py` — `ops/daily_company/data/history.json` (append-only, git-friendly)
- `memory_insights.py` — repeat themes, LOC trend hints
- `llm_optional.py` — `OPENAI_API_KEY` for executive bullets (optional)

## Outputs

- `out/latest-report.json` — full report
- `out/LATEST_REPORT.md` — human-readable
- `out/history-export.json` — last 60 runs for dashboard
- `data/history.json` — full memory (trimmed to 120 runs)

## Dashboard

- `daily_company/dashboard/index.html` — static UI; copy to `docs/ai-company/` with JSON sidecars

## One command

From repo root:

```bash
./scripts/bootstrap-ai-company.sh   # first time
./scripts/daily-company-report.sh # daily
```

See **`AI_COMPANY_SETUP.md`** in the project root for GitHub Pages + Actions.
