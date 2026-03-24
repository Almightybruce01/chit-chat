# Chit Chat Social — live links

## Repository (source of truth)

- **Code:** `https://github.com/Almightybruce01/chit-chat`

This repo is **only** for the Chit Chat Social app. Keep other products in **separate** repositories so bundle IDs, Firebase, Pages, and domains never get mixed up.

## Elite Command Center (web dashboard)

- **Public site (GitHub Pages, when enabled):** `https://almightybruce01.github.io/chit-chat/ai-company/`  
  Opens the same dashboard as in the repo; **4-digit PIN** `5505` unlocks (stored in browser until you tap **Lock** or close the tab).  
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
