# Chit Chat Social — live links

## Repository (source of truth)

- **GitHub (only this project):** `https://github.com/Almightybruce01/chit-chat`

Everything in this repository is **Chit Chat Social** only — app, `docs/`, workflows, and dashboard. Other products belong in **other repos**, not here, so bundle IDs, Firebase, GitHub Pages, and domains never get mixed up.

## Elite Command Center (web dashboard)

- **GitHub Pages (public landing only):** [https://almightybruce01.github.io/chit-chat/ai-company/](https://almightybruce01.github.io/chit-chat/ai-company/) — stub + instructions; **no** report JSON is published there. See **[`docs/LIVE_DASHBOARD.md`](docs/LIVE_DASHBOARD.md)**.
- **Private dashboard (bookmark this after you deploy):** Cloudflare Worker in **`ops/daily_company/dashboard-worker/`** — password is stored in **Wrangler secrets**, not in HTML. Full steps in that folder’s **README.md**.
- **Safari bookmark:** `docs/Chit Chat Social Dashboard.webloc` — points at Pages; for the private UI, bookmark your Worker URL in the browser after deploy.
- **Local full dashboard:** `cd ops/daily_company/dashboard && python3 -m http.server 8765` (after `./scripts/bootstrap-ai-company.sh`).
- **Source HTML:** `ops/daily_company/dashboard/index.html` · **Deep links:** `#admin` · `#cursor` · `#pipeline`
- **Regenerate JSON + refresh Pages HTML:** `./scripts/bootstrap-ai-company.sh` then commit + push (JSON stays under `ops/daily_company/out/` and local `dashboard/`; not copied to `docs/ai-company/`).
- **Optional feedback for AI:** `ops/daily_company/data/user_signals.json` (see `.example` file).

**Enable Pages (once):** GitHub repo → **Settings → Pages → Build and deployment** → Branch **main** → folder **`/docs`** → **Save**.

## GitHub Pages (optional)

If you enable Pages for **this** repo, GitHub will show the canonical URL under **Repo → Settings → Pages** (usually `https://<username>.github.io/<repo>/…`).

- **Online dashboard / docs (when Pages is on):** `https://almightybruce01.github.io/chit-chat/`
- **Deployments:** `https://github.com/Almightybruce01/chit-chat/deployments`

**Custom domains:** A domain you use for *another* app or site should **not** be attached to this repo unless you want that URL to show *this* project’s Pages. When in doubt, use the default `*.github.io` URL for Chit Chat Social docs only.

## Actions

- **Workflows:** `https://github.com/Almightybruce01/chit-chat/actions`

## Optional: OpenAI (daily report workflow)

- **Secrets:** `https://github.com/Almightybruce01/chit-chat/settings/secrets/actions`  
  Add `OPENAI_API_KEY` if you use the optional daily report.

## Security

- `GoogleService-Info.plist` is **not** tracked. Keep your local copy for Xcode builds.
- If that file was ever committed, **rotate** Firebase keys — see `SECURITY_NOTE.md`.
