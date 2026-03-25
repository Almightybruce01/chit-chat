#!/usr/bin/env bash
# Replace REPORT_KV namespace id in wrangler.toml. Usage: ./scripts/apply-dashboard-kv-id.sh <uuid>
set -euo pipefail
NEW_ID="${1:?Usage: $0 <kv-namespace-uuid>}"
export NEW_ID
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export DASH_WRANGLER_TOML="$ROOT/ops/daily_company/dashboard-worker/wrangler.toml"
test -f "$DASH_WRANGLER_TOML" || { echo "Missing $DASH_WRANGLER_TOML" >&2; exit 1; }
python3 <<'PY'
import os, pathlib, re, sys
path = pathlib.Path(os.environ["DASH_WRANGLER_TOML"])
new_id = os.environ["NEW_ID"]
text = path.read_text()
pattern = r'(binding = "REPORT_KV"\s*\n)id = "[^"]*"'
repl = r'\1id = "' + new_id + '"'
text2, n = re.subn(pattern, repl, text, count=1)
if n != 1:
    print("Could not patch REPORT_KV id line in", path, file=sys.stderr)
    sys.exit(1)
path.write_text(text2)
print("Updated", path)
PY
