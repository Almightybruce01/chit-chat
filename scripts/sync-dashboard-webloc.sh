#!/usr/bin/env bash
# Point webloc bookmarks at your private Worker URL (one line in config/DASHBOARD_BOOKMARK_URL).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
URL_FILE="${1:-$ROOT/config/DASHBOARD_BOOKMARK_URL}"
if [[ ! -f "$URL_FILE" ]]; then
  echo "Missing $URL_FILE — copy config/DASHBOARD_BOOKMARK_URL.example and paste your Worker https URL." >&2
  exit 1
fi
URL=$(head -1 "$URL_FILE" | tr -d '\r\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
if [[ -z "$URL" || "$URL" == *YOUR_* || "$URL" == *REPLACE* || "$URL" == *NOT-YET* ]]; then
  echo "Edit $URL_FILE with your real Worker URL from wrangler deploy, then run again." >&2
  exit 1
fi
export SYNC_ROOT="$ROOT"
export SYNC_DASH_URL="$URL"
python3 <<'PY'
import os, plistlib, pathlib
root = pathlib.Path(os.environ["SYNC_ROOT"])
url = os.environ["SYNC_DASH_URL"]
files = [
    root / "docs" / "Chit Chat Social Dashboard.webloc",
    root / "ops" / "daily_company" / "dashboard" / "Chit Chat Social Dashboard.webloc",
    pathlib.Path.home() / "Desktop" / "Chit Chat Social - Live Dashboard.webloc",
]
for p in files:
    if not p.exists():
        print("skip missing", p)
        continue
    with open(p, "rb") as f:
        pl = plistlib.load(f)
    pl["URL"] = url
    with open(p, "wb") as f:
        plistlib.dump(pl, f)
    print("updated", p)
PY
