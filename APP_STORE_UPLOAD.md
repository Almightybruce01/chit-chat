# Chit Chat Social — App Store Upload Guide

## Prerequisites

- [ ] Apple Developer account ($99/year)
- [ ] Xcode installed, project builds without errors
- [ ] App icons in all required sizes (see `Assets.xcassets/AppIcon.appiconset`)
- [ ] **Privacy Policy URL** (required for apps with auth/accounts and UGC)
- [ ] **Support URL** (required)
- [ ] Marketing / contact email you monitor (for Resolution Center)

---

## Step 1: Prepare in Xcode

1. **Select your project** → target **Chit Chat Social** → **General**
   - Set **Version** (e.g. `1.0.0`) — marketing version shown on the store
   - Set **Build** (e.g. `1`) — increment for **every** upload; must be unique per app
   - Verify **Bundle Identifier** matches the App Store Connect app (e.g. `com.yourcompany.chitchatsocial`)

2. **Display name (home screen)**  
   Target → **General** → **Display Name** — e.g. `Chit Chat Social` (short enough for the icon label).

3. **Signing & Capabilities**
   - Select your **Team**
   - Enable **Automatically manage signing**
   - Ensure provisioning profile is valid for **App Store** distribution

4. **Build for release**
   - **Product → Archive** (uses Release)

---

## Step 2: Upload to App Store Connect

1. After Archive completes, **Organizer** opens  
2. Select your archive → **Distribute App**  
3. **App Store Connect** → **Upload**  
4. Options:
   - [x] Upload your app's symbols (recommended for crash logs)
   - [x] Manage version and build number automatically (optional)
5. **Upload** and wait for processing (often **10–45 minutes**). You’ll get an email when the build is ready.

---

## Step 3: App Store Connect — App record

1. [App Store Connect](https://appstoreconnect.apple.com) → **My Apps**  
2. **+** → **New App** (or open the existing record)

Fill in:

| Field | Guidance |
|--------|-----------|
| **Platforms** | iOS |
| **Name** | **Chit Chat Social** (up to **30 characters**; this is the **customer-facing App Store name**) |
| **Primary language** | English (U.S.) or your primary |
| **Bundle ID** | Must match Xcode exactly |
| **SKU** | Any unique string you never change, e.g. `chit-chat-social-001` |
| **User access** | Full Access for your main account |

**Note:** The **name** here is not the same as **subtitle** or **keywords** (you already have those). If Apple says the name is taken, try a ranked alternative from `APP_NAMES.md`.

---

## Step 4: App Information (app level)

- **Category:** Primary **Social Networking**; secondary optional (e.g. Entertainment).  
- **Content rights:** Confirm you have rights to assets you use.  
- **Age rating:** Complete the questionnaire. Social + UGC often lands **12+** or **17+** depending on moderation and features.  
- **App Privacy:** Declare data you collect (account info, user content, identifiers, etc.). Must align with your Privacy Policy.

---

## Step 5: Pricing and availability

- **Price:** Free (or set tier)  
- **Availability:** Countries/regions  

---

## Step 6: Version page — metadata you already have

Attach your **subtitle**, **keywords**, **description**, and **promotional text** in:

**App Store** → your app → **iOS App** → **[version]** → **App Store** tab.

Keep these aligned with the **Chit Chat Social** brand (avoid mixing in old “Chitchat-only” copy unless that’s still your legal/marketing name).

**Support URL** (required) — help page, GitHub README, or dedicated support site.  
**Marketing URL** (optional).

---

## Step 7: Screenshots and preview

Required sizes depend on devices you support. Common:

- **6.7"** (e.g. iPhone 15 Pro Max): **1290 × 2796**  
- **6.5"** / **5.5"** if you support older size classes  

You need **3–10** screenshots per required size. Capture from Simulator (**⌘S**) or device.

Optional: **App Preview** video.

---

## Step 8: Build + “What’s New”

1. In the same version, under **Build**, click **+** and select the processed build.  
2. **What’s New in This Version** — e.g. “Initial release of Chit Chat Social.”

---

## Step 9: App Review Information (login + testers)

Apple needs a way to review **sign-in** and **main flows**.

### A. Demo account for reviewers (most important)

In **App Store Connect** → your app → **App Information** (or version) → **App Review Information**:

- **Sign-in required?** Yes, if users must log in.  
- **User name** / **Password:** a **dedicated** reviewer-only account (not your personal Apple ID).  
  - Example: `reviewer+chitchatsocial@yourdomain.com` with a strong password you control.  
- **Notes:** Short path: tap Sign in → email/password (or Apple/Google). Mention any **2FA** exceptions (review accounts should avoid 2FA if possible, or document backup codes in private notes only if Apple allows).

**Review notes template** (paste and customize):

```
App: Chit Chat Social

Demo account for review:
Email: [YOUR_REVIEW_EMAIL]
Password: [YOUR_REVIEW_PASSWORD]

Flows to test: sign in → home feed → create post (optional) → profile → messages (if enabled).

Sign in with Apple / Google: [enabled or not — if enabled, still provide email/password demo if available].

Moderation: [brief note — e.g. AI warning on sensitive content, reporting path].

Thank you.
```

### B. Sandbox testers (only if you sell **In-App Purchases** or subscriptions)

This is **not** the same as the App Review demo account.

1. App Store Connect → **Users and Access** → **Sandbox** → **Testers**  
2. Add testers with **sandbox Apple IDs** (separate from production Apple ID).  
3. Use them on device: **Settings → App Store → Sandbox Account** (iOS) to test purchases before submission.

If you have **no IAP**, you can skip sandbox testers.

### C. TestFlight (optional but useful)

- **Internal testing:** up to 100 people on your team; fast.  
- **External testing:** requires Beta App Review for the first build. Good for friends/family before App Review.

---

## Step 10: Compliance toggles (version submission)

When you click **Submit for Review**, you’ll confirm:

- **Export compliance** — For most apps using HTTPS only: typically **“No”** to special encryption beyond standard (confirm against Apple’s questions).  
- **Advertising Identifier (IDFA)** — **No** unless you use ad tracking.  
- **Content rights** — Confirm.  
- **Third-party content** — Accurate for UGC/social.

---

## Step 11: Submit for Review

Checklist right before submit:

- [ ] Build selected and not expired  
- [ ] Screenshots for all **required** device sizes  
- [ ] Privacy Policy URL live  
- [ ] Support URL live  
- [ ] Age rating complete  
- [ ] App Privacy questionnaire complete  
- [ ] **Demo account** (if login required) + clear review notes  
- [ ] IAP: sandbox tested (if applicable)  
- [ ] Version and build in Xcode match what you expect  

Then **Submit for Review**.

---

## Step 12: After submission

- **Waiting for Review** → **In Review** → **Pending Developer Release** / **Ready for Sale**  
- Watch **Resolution Center** and your email  
- **Phased release** (optional): release gradually over 7 days  

---

## In-app admin (verification & users)

**Chit Chat Social** includes an **admin dashboard inside the iOS app** (not the static HTML AI dashboard):

- **Who can access:** accounts whose **username** (lowercased) is one of: `almighty_bruce_`, `admin`, `owner` (see `AppState.canAccessInternalDashboard`).  
- **Where:** **Profile** → **Chit Chat Social admin**, or **Corporate** hub → **Open Chit Chat Social admin**.  
- **Features:** auto-verification pass (IG signal), verification queue, **search all users**, **rename username**, **remove user from local directory**, grant official / paid verification.

Removing a user in the app **does not** delete their **Firebase Authentication** user or remote data by itself — it updates the **on-device** directory used by the MVP. For full cloud deletion, use **Firebase Console** (Authentication + Firestore) or add backend admin tools later.

---

## If “App name already in use”

1. Check **My Apps** for another record you already created.  
2. If another developer owns the name, use the next option in `APP_NAMES.md` (e.g. **Chit Chat Elite**, **Chitter**).

---

## Quick checklist (copy/paste)

- [ ] Version & build set in Xcode; archive uploaded  
- [ ] App record + bundle ID aligned  
- [ ] Subtitle, description, keywords, promotional text  
- [ ] Screenshots (3+ per required size)  
- [ ] Privacy Policy + Support URLs  
- [ ] Age rating + App Privacy  
- [ ] Demo login + review notes (if sign-in required)  
- [ ] Sandbox testers (only if IAP)  
- [ ] Submit for Review  
