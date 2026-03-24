#!/usr/bin/env bash
# One-shot: git init (if needed), run first report, print next steps for GitHub Pages.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -d .git ]]; then
  echo "Initializing git repository..."
  git init
  git branch -M main 2>/dev/null || true
fi

export PYTHONPATH="${ROOT}/ops"
python3 -m daily_company --root "$ROOT" --out "$ROOT/ops/daily_company/out" \
  --data "$ROOT/ops/daily_company/data" \
  --dashboard-export "$ROOT/ops/daily_company/out/history-export.json"

mkdir -p docs/ai-company
cp -f ops/daily_company/out/latest-report.json docs/ai-company/
cp -f ops/daily_company/out/LATEST_REPORT.md docs/ai-company/
cp -f ops/daily_company/out/history-export.json docs/ai-company/
cp -f ops/daily_company/dashboard/index.html docs/ai-company/
cp -f "ops/daily_company/dashboard/Chit Chat Social Dashboard.webloc" docs/

# Same JSON next to dashboard HTML so local open works: file:// or python -m http.server
cp -f ops/daily_company/out/latest-report.json ops/daily_company/dashboard/
cp -f ops/daily_company/out/history-export.json ops/daily_company/dashboard/

echo ""
echo "✅ Done. Next steps (once):"
echo "  1. Create a repo on github.com (empty, no README)."
echo "  2:  git remote add origin https://github.com/YOU/REPO.git   (create empty repo on GitHub first)"
echo "  3:  git add -A && git commit -m 'Add AI Company pipeline' && git push -u origin main"
echo "  4:  Settings → Pages → Branch main, folder /docs"
echo "  5:  Optional repo secrets: OPENAI_API_KEY, GITHUB_TOKEN (usually automatic in Actions)"
echo "  6:  Site: https://YOU.github.io/REPO/ai-company/  (PIN 5505 on first load)"
echo "  7:  Bookmark: docs/Chit Chat Social Dashboard.webloc → open or drag to Desktop"
echo ""
