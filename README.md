# Chit Chat Social - Elite Social Platform (MVP Foundation)

## Live dashboard

**Public site (`www`):** hub [https://www.chitchatsocials.com/](https://www.chitchatsocials.com/) → [/support/](https://www.chitchatsocials.com/support/) (App&nbsp;Store &amp; help) · [/ai-company/](https://www.chitchatsocials.com/ai-company/) landing. DNS (**Namecheap**): point **`www`** → CNAME **`almightybruce01.github.io`** and apex **`@`** → four GitHub **A** records (below); then GitHub repo **Pages** → Custom domain **`www.chitchatsocials.com`** + **`chitchatsocials.com`** and **Enforce HTTPS**. Hosted from this repo (Actions artifact + `deploy-support/CNAME`).

**Private UI:** Cloudflare Worker + **Workers KV** only (no report JSON in this public repo). See [`docs/PRIVATE_DASHBOARD_SETUP.md`](docs/PRIVATE_DASHBOARD_SETUP.md) and [`ops/daily_company/dashboard-worker/`](ops/daily_company/dashboard-worker/). **Local:** `ops/daily_company/dashboard/` + `python3 -m http.server` after `./scripts/bootstrap-ai-company.sh`.

**Namecheap apex `A` @ host `Record`:** `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, `185.199.111.153`. **CNAME:** Host **`www`** → **`almightybruce01.github.io`**. Repo paths: [`docs/ai-company/`](docs/ai-company/) · duplicate support [`docs/support/`](docs/support/). **`deploy-support/CNAME`** is `www.chitchatsocials.com`. Use **Pages → Source: GitHub Actions**. Canonical docs: [`docs/LIVE_DASHBOARD.md`](docs/LIVE_DASHBOARD.md).

**If URLs 404:** Repo **Settings → Pages → Custom domains** must include **`www.chitchatsocials.com`** (+ apex **`chitchatsocials.com`**); DNS alone isn’t enough. **Remove every `investli.org` hostname** from this repo’s Pages domains — **`https://almightybruce01.github.io/chit-chat/`** can still **301 → investli** until that’s gone (Investli/Vercel 404).

**HTTPS:** Use **`https://www.chitchatsocials.com/support/`** in App&nbsp;Store Connect (not **`http://`**, even if **`github.io/.../support/`** temporarily redirects to HTTP — Enforce HTTPS on `www` in Pages).

---

Chit Chat Social is a social app concept focused on creator content, direct messaging, conference calls, live DJ rooms, and strong moderation defaults.

## Current MVP Foundation

- Onboarding slides for product intro and safety expectations
- Home with swipe modes:
  - Left: Reels mode
  - Center: Feed
  - Right: Direct message mode
- Tab layout:
  - Home
  - Search
  - Create (posts & reels)
  - Reels
  - Profile

## Repository scope (keep projects separate)

- **This repo is only the Chit Chat Social app** (App Store / product name: **Chit Chat Social**). GitHub remote: `https://github.com/Almightybruce01/chit-chat` — do not mix in other products, sites, or unrelated documentation here; use separate repositories for anything else.
- The GitHub repo slug (`chit-chat`) can differ from the app name; set the repo **Description** and **About** on GitHub to **Chit Chat Social** so the project page matches the brand.
- Using GitHub for source control and optional **GitHub Pages** for repo docs is fine; just attach **this** repo’s Pages to **this** repo’s URL — don’t point another product’s custom domain here unless you mean to.
- Chat room prototypes:
  - 1-on-1 call
  - Group call + DJ mode
  - Executive/business call with notes
- Post tools prototypes:
  - camera/gallery upload
  - collab posting
  - screen-share drafting
  - scan import placeholder
  - live DJ toggle
- Safety controls:
  - block nudity content setting
  - violence consent gate setting
  - moderation AI guidance copy
- Shared app state and models:
  - users, posts, stories, chats, call rooms, song queue
  - publish flow wired with moderation checks
- Backend service layer:
  - Firestore sync stubs for user profile, posts, moderation events
- Search with AI "people you may know" mock suggestions
- Verification growth copy for early profile verification flow
- Auth options:
  - working: Google, Apple
  - placeholders: Phone, Email, Facebook, Instagram, Gmail

## Moderation Design (Production Target)

- Block nudity automatically at upload time and review time
- For violence:
  - classify risk level
  - blur and gate high-risk content
  - require user consent before reveal
- Add human moderation queue for uncertain or appealed decisions
- Keep auditable logs for moderation actions and appeals

## Next Build Phases

1. Real-time backend
   - Firestore collections for users, chats, call rooms, live sessions, stories
   - Cloud Functions for fan-out notifications and moderation pipelines
2. Live and call stack
   - integrate WebRTC/Twilio/Agora for audio/video and screen sharing
   - role-based room permissions (DJ, host, audience)
3. Creator toolchain
   - in-app intro templates, clip trimming, overlays, and captions
4. Account graph and recommendations
   - production ranker for people-you-may-know and follow suggestions
5. Marketplace/business mode
   - optional business profiles, product shelves, and collab contracts

## Connect This Project to GitHub

1. Create a new empty GitHub repository.
2. In this project folder run:

```bash
git init
git add .
git commit -m "Initial Chit Chat Social MVP foundation"
git branch -M main
git remote add origin https://github.com/<your-username>/<repo-name>.git
git push -u origin main
```

## Important Notes

- This repository currently contains your Firebase config file. Keep secrets and production keys protected.
- Before launch, add legal docs: Terms, Privacy, moderation policy, and user appeal flow.
