"""
Elite CLI: python -m daily_company [--root PATH] [--out DIR] [--no-trends] [--no-llm]

PYTHONPATH must include ./ops (see scripts/bootstrap-ai-company.sh).
"""

from __future__ import annotations

import argparse
from pathlib import Path

from .report_generator import build_report, write_outputs

BANNER = """
╔═══════════════════════════════════════════════════════════╗
║  ⚡ Chit Chat Social AI Company — Elite Daily Report             ║
╚═══════════════════════════════════════════════════════════╝
"""


def main() -> None:
    ap = argparse.ArgumentParser(description="Elite Daily AI Tech Company — Phases 1–3")
    ap.add_argument("--root", type=Path, default=Path.cwd(), help="Repository root")
    ap.add_argument(
        "--out",
        type=Path,
        default=None,
        help="Report output dir (default: <root>/ops/daily_company/out)",
    )
    ap.add_argument(
        "--data",
        type=Path,
        default=None,
        help="History JSON dir (default: <root>/ops/daily_company/data)",
    )
    ap.add_argument("--no-trends", action="store_true", help="Skip network trend fetch")
    ap.add_argument("--no-llm", action="store_true", help="Skip OpenAI executive summary")
    ap.add_argument(
        "--dashboard-export",
        type=Path,
        default=None,
        help="Write history JSON for dashboard (default: next to out)",
    )
    args = ap.parse_args()
    root = args.root.resolve()
    out = args.out or (root / "ops" / "daily_company" / "out")
    data_dir = args.data or (root / "ops" / "daily_company" / "data")
    dash_export = args.dashboard_export or (out / "history-export.json")

    print(BANNER)

    report = build_report(root, data_dir, skip_trends=args.no_trends, skip_llm=args.no_llm)
    write_outputs(report, out, data_dir, dashboard_json=dash_export)

    scan = report.get("scan") or {}
    if scan.get("swift_hotspot_score") is not None:
        print(f"  Metrics: hotspot {scan['swift_hotspot_score']}/100 | modularity {scan.get('modularity_signal', '—')}")
    print(f"\n  Wrote: {out / 'latest-report.json'}")
    print(f"         {out / 'LATEST_REPORT.md'}")
    print(f"         {data_dir / 'history.json'}")
    print("\n  Executive summary:")
    for line in report["executive_summary"]:
        print(f"    • {line}")
    ts = report["todays_script"]
    print(f"\n  >>> TODAY'S SCRIPT ({ts.get('script_type', 'ops')}): {ts['title']}\n")
    pi = report.get("product_intelligence") or {}
    sug = pi.get("update_suggestions") or []
    if sug:
        print("  Product update suggestions:")
        for line in sug[:7]:
            print(f"    • {line}")
    if pi.get("suggestions_note"):
        print(f"  (product LLM note: {pi['suggestions_note']})")


if __name__ == "__main__":
    main()
