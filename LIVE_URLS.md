# Chit Chat Social — live links

## Repository (source of truth)

- **GitHub (only this project):** `https://github.com/Almightybruce01/chit-chat`

Everything in this repository is **Chit Chat Social** only — app, `docs/`, workflows, and dashboard. Other products belong in **other repos**, not here, so bundle IDs, Firebase, GitHub Pages, and domains never get mixed up.

## Elite Command Center (web dashboard)

- **Canonical live URL (bookmark this):** [https://almightybruce01.github.io/chit-chat/ai-company/](https://almightybruce01.github.io/chit-chat/ai-company/) — matches **`docs/ai-company/`** in this repo on **`main`**.  
  Also documented in **[`docs/LIVE_DASHBOARD.md`](docs/LIVE_DASHBOARD.md)**.
- **4-digit PIN** `5505` unlocks (session in browser until **Lock** or tab close).  
  **Note:** On a public repo the PIN is visible in page source—it keeps casual visitors out, not determined attackers. For real access control use a private repo, Cloudflare Access, or VPN.
- **Safari bookmark file (double-click on Mac):** `docs/Chit Chat Social Dashboard.webloc` — drag to your Desktop or Dock for one-click access to the public URL above.
- **On your Mac (local file):** `/Users/brianbruce/Desktop/Chit Chat Social/ops/daily_company/dashboard/index.html`
- **File in repo (browse):** `https://github.com/Almightybruce01/chit-chat/blob/main/ops/daily_company/dashboard/index.html`
- **Deep links:** `#admin` · `#cursor` · `#pipeline`
- **Regenerate JSON + publish to `docs/ai-company/`:** `./scripts/bootstrap-ai-company.sh` then commit + push so Pages updates.
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
