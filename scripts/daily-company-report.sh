#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PYTHONPATH="${ROOT}/ops"
exec python3 -m daily_company \
  --root "${ROOT}" \
  --out "${ROOT}/ops/daily_company/out" \
  --data "${ROOT}/ops/daily_company/data" \
  --dashboard-export "${ROOT}/ops/daily_company/out/history-export.json"
