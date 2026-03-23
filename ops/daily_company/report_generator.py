"""Build unified daily JSON + Markdown — Phases 1–3."""

from __future__ import annotations

import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from .collaboration import merge_insights
from .cto import select_todays_script
from .departments import run_all_departments
from .github_remote import detect_owner_repo_from_git, fetch_repo_meta
from .history_store import append_run, export_for_dashboard, recent_titles
from .llm_optional import maybe_enrich_executive_summary
from .memory_insights import analyze_history
from .scanner import ScanResult, scan_project
from .trends import aggregate_trends


def _git_remote_url(root: Path) -> str | None:
    try:
        out = subprocess.run(
            ["git", "-C", str(root), "remote", "get-url", "origin"],
            capture_output=True,
            text=True,
            timeout=15,
        )
        if out.returncode == 0 and out.stdout.strip():
            return out.stdout.strip()
    except (subprocess.SubprocessError, FileNotFoundError):
        pass
    return None


def build_report(
    root: Path,
    data_dir: Path,
    skip_trends: bool = False,
    skip_llm: bool = False,
) -> dict[str, Any]:
    scan = scan_project(root)
    departments = run_all_departments(scan)

    trends: dict[str, Any] = {"skipped": True, "keywords": []}
    if not skip_trends:
        try:
            trends = aggregate_trends()
        except Exception as e:  # noqa: BLE001 — network/rss must not kill report
            trends = {"error": str(e), "keywords": []}

    recent = recent_titles(data_dir)
    memory = analyze_history(data_dir)
    kw = trends.get("keywords", []) if isinstance(trends, dict) else []
    script = select_todays_script(scan, recent_script_titles=recent, trend_keywords=kw if isinstance(kw, list) else [])
    collab = merge_insights(departments, trends if isinstance(trends, dict) else {}, scan)

    gh_meta: dict[str, Any] = {}
    remote = _git_remote_url(root)
    owner_repo = detect_owner_repo_from_git(remote)
    if owner_repo:
        gh_meta = fetch_repo_meta(owner_repo)

    base_summary = [
        f"Scanned {len(scan.files)} files, {scan.total_lines:,} total lines.",
        f"Git (7d commits): {scan.git_commits_7d if scan.git_commits_7d is not None else 'n/a'}",
        f"Today's single focus: {script['title']}",
    ]
    if isinstance(trends, dict) and trends.get("keywords"):
        base_summary.append(f"Trend keywords: {', '.join(trends['keywords'][:6])}")

    ctx_for_llm = {
        "departments": departments,
        "todays_script": script,
        "trends": trends,
        "collaboration": collab,
    }
    bullets, llm_err = ([], None)
    if not skip_llm:
        bullets, llm_err = maybe_enrich_executive_summary(base_summary, ctx_for_llm)
    exec_summary = bullets if bullets and len(bullets) >= 3 else base_summary

    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "repo_root": str(root),
        "phases": {
            "p1_scan": True,
            "p2_trends_collab": not skip_trends,
            "p3_history": True,
            "p3_llm_enrichment": not skip_llm,
        },
        "executive_summary": exec_summary,
        "llm_note": llm_err,
        "github": {"remote": remote, "owner_repo": owner_repo, "api": gh_meta},
        "collaboration": collab,
        "memory": memory,
        "departments": departments,
        "trends": trends if isinstance(trends, dict) else {},
        "scan": scan.to_dict(),
        "problems": [
            "Large Swift files increase merge conflict risk."
            if any(f.lines > 2000 for f in scan.files if f.language == "Swift")
            else "No mega-files detected in scan scope.",
            "TODO markers indicate unfinished work." if scan.todo_hits else "No TODO/FIXME in scanned files.",
        ],
        "opportunities": [
            "Ship one measurable improvement from today's script.",
            "Optional: set OPENAI_API_KEY for richer executive bullets.",
        ],
        "todays_script": script,
        "expected_impact": {
            "performance": "Focused refactors reduce compile time and state churn.",
            "ux": "Smaller views = fewer SwiftUI regressions.",
            "revenue": "Faster iteration on monetization experiments.",
            "scalability": "Modular state scales with contributors.",
        },
    }
    return report


def write_outputs(
    report: dict[str, Any],
    out_dir: Path,
    data_dir: Path,
    dashboard_json: Path | None = None,
) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    json_path = out_dir / "latest-report.json"
    json_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    md_path = out_dir / "LATEST_REPORT.md"
    md_path.write_text(_markdown_report(report), encoding="utf-8")

    append_run(
        data_dir,
        report["todays_script"],
        report["scan"],
        report.get("trends", {}),
    )
    dash = dashboard_json or (out_dir / "history-export.json")
    export_for_dashboard(data_dir, dash)


def _markdown_report(r: dict[str, Any]) -> str:
    lines: list[str] = []
    lines.append("# Daily Company Report (Phases 1–3)\n")
    lines.append(f"_Generated: {r['generated_at']}_\n")
    phases = r.get("phases", {})
    lines.append(
        f"_Automation: P1={phases.get('p1_scan')}, P2={phases.get('p2_trends_collab')}, "
        f"P3 history+memory={phases.get('p3_history')}, LLM={phases.get('p3_llm_enrichment')}_\n"
    )
    lines.append("## 1. Executive Summary\n")
    for b in r["executive_summary"]:
        lines.append(f"- {b}")
    if r.get("llm_note"):
        lines.append(f"\n_LLM note: {r['llm_note']}_\n")
    lines.append("\n## 2. Trends (ingested)\n")
    tr = r.get("trends") or {}
    if tr.get("skipped"):
        lines.append("- Trends skipped for this run.")
    elif tr.get("error"):
        lines.append(f"- Error: {tr['error']}")
    else:
        for src, payload in (tr.get("sources") or {}).items():
            items = (payload or {}).get("items") or []
            lines.append(f"### {src}\n")
            for it in items[:5]:
                lines.append(f"- [{it.get('title', '')}]({it.get('url', '#')})")
        if tr.get("keywords"):
            lines.append(f"\n**Keywords:** {', '.join(tr['keywords'][:10])}")
    lines.append("\n## 3. Memory (Phase 3 self-improving)\n")
    mem = r.get("memory") or {}
    for ins in mem.get("insights", []):
        lines.append(f"- {ins}")
    if mem.get("top_script_types"):
        lines.append(f"- **Script types seen:** {', '.join(mem['top_script_types'])}")
    lines.append("\n## 4. Collaboration resolution\n")
    for k, v in (r.get("collaboration") or {}).items():
        if isinstance(v, list):
            lines.append(f"- **{k}**:")
            for item in v:
                lines.append(f"  - {item}")
        else:
            lines.append(f"- **{k}**: {v}")
    lines.append("\n## 5. Department Insights\n")
    for name, body in r["departments"].items():
        lines.append(f"### {name}\n")
        for bullet in body.get("bullets", []):
            lines.append(f"- {bullet}")
        lines.append("")
    lines.append("## 6. Key Problems\n")
    for p in r["problems"]:
        lines.append(f"- {p}")
    lines.append("\n## 7. Opportunities\n")
    for o in r["opportunities"]:
        lines.append(f"- {o}")
    lines.append("\n## 8. TODAY'S ONE SCRIPT\n")
    ts = r["todays_script"]
    lines.append(f"**{ts['title']}**\n")
    lines.append(f"- Rationale: {ts['rationale']}")
    lines.append(f"- Type: {ts['script_type']}")
    if ts.get("files_to_touch"):
        lines.append("- Files:")
        for f in ts["files_to_touch"]:
            lines.append(f"  - `{f}`")
    lines.append("- Steps:")
    for s in ts.get("steps", []):
        lines.append(f"  1. {s}")
    if ts.get("copy_paste_stub"):
        lines.append("\n```")
        lines.append(ts["copy_paste_stub"])
        lines.append("```\n")
    lines.append("## 9. Expected Impact\n")
    for k, v in r["expected_impact"].items():
        lines.append(f"- **{k}**: {v}")
    gh = r.get("github") or {}
    if gh.get("owner_repo"):
        lines.append(f"\n## GitHub\n- Repo: `{gh.get('owner_repo')}`\n")
    lines.append("\n---\n*Chit Chat AI Company — automated pipeline*\n")
    return "\n".join(lines)
