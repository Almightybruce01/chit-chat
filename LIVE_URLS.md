# Your live links (account: **Almightybruce01**)

## Repository
- **Code:** https://github.com/Almightybruce01/chit-chat

## AI Company dashboard (GitHub Pages)
- **Standard URL:** https://almightybruce01.github.io/chit-chat/ai-company/
- **Pages status:** https://github.com/Almightybruce01/chit-chat/deployments (look for *github-pages*)

Your GitHub account uses a **custom domain** (`investli.org`) for Pages. If that domain’s DNS points to **Vercel** instead of **GitHub**, the redirect from `github.io` can 404. Fix one of:

1. **GitHub → your profile → Settings → Pages** — review **Custom domain** (or remove it to use only `*.github.io`).
2. **DNS** — for `investli.org`, ensure GitHub Pages CNAME/A records per [GitHub docs](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site).

Until DNS matches GitHub, use the **repository’s** Pages link from:  
**Repo → Settings → Pages** (GitHub shows the working “Visit site” URL after build).

## Actions (daily report)
- https://github.com/Almightybruce01/chit-chat/actions

## Optional: OpenAI executive bullets
- **Secrets:** https://github.com/Almightybruce01/chit-chat/settings/secrets/actions  
- New secret: `OPENAI_API_KEY`

## Security (read this)
- `GoogleService-Info.plist` is **no longer tracked**. Keep your local copy for Xcode builds.
- Because the plist was in **earlier commits**, **rotate** the Firebase Web API key in [Google Cloud Console](https://console.cloud.google.com/) / Firebase — see `SECURITY_NOTE.md`.
