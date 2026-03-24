# Chit Chat Social - Elite Social Platform (MVP Foundation)

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

- **Chit Chat Social** lives in its **own** GitHub repo (`chit-chat`). That keeps it isolated from other apps (different Firebase projects, bundle IDs, and marketing sites).
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
