# Push to GitHub (2 minutes) — only step left for public site

Your Mac is ready: **git is initialized** and **first commit is done**.

## 1. Create the repo

1. Open https://github.com/new  
2. Repository name: e.g. `chit-chat`  
3. **Do not** add README, .gitignore, or license (empty repo)  
4. Click **Create repository**

## 2. Paste in Terminal (replace YOUR_USER and YOUR_REPO)

```bash
cd "/Users/brianbruce/Desktop/Chit Chat"
git remote add origin https://github.com/YOUR_USER/YOUR_REPO.git
git push -u origin main
```

- If GitHub asks for login: use a **Personal Access Token** as the password (GitHub → Settings → Developer settings → Personal access tokens), or use **GitHub Desktop** / **SSH**.

## 3. Turn on Pages

GitHub repo → **Settings** → **Pages** → **Source**: Deploy from branch **main** → **Folder** `/docs` → **Save**

## 4. Open your dashboard

Wait ~1 minute, then open:

`https://YOUR_USER.github.io/YOUR_REPO/ai-company/`

Daily updates run automatically via **Actions** (`.github/workflows/daily-company-report.yml`).
