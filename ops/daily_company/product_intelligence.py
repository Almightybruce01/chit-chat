"""Product intelligence: self-diagnosis from scan + optional user signals + update suggestions."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .llm_optional import maybe_product_update_suggestions


DEFAULT_USER_SIGNALS: dict[str, Any] = {
    "version": 1,
    "sessions_last_7d_estimate": None,
    "top_user_pain_points": [],
    "feature_requests": [],
    "review_snippets": [],
    "analytics_notes": "",
    "support_tickets_summary": "",
}


def load_user_signals(data_dir: Path) -> dict[str, Any]:
    path = data_dir / "user_signals.json"
    if not path.is_file():
        return dict(DEFAULT_USER_SIGNALS)
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
        merged = dict(DEFAULT_USER_SIGNALS)
        if isinstance(raw, dict):
            merged.update(raw)
        return merged
    except (json.JSONDecodeError, OSError):
        return dict(DEFAULT_USER_SIGNALS)


def build_self_diagnosis(scan: dict[str, Any]) -> dict[str, Any]:
    """Structured self-diagnosis from scanner output (no user PII)."""
    largest = scan.get("largest_files") or []
    top = largest[:5] if isinstance(largest, list) else []
    todos = scan.get("todo_hits") or []
    todo_n = len(todos) if isinstance(todos, list) else 0

    hotspots = [
        f"{x.get('path', '?')} ({x.get('lines', 0)} lines, {x.get('language', '')})"
        for x in top
        if isinstance(x, dict)
    ]

    diagnosis_lines: list[str] = [
        f"Swift/code health score (hotspot): {scan.get('swift_hotspot_score', 'n/a')}/100; "
        f"modularity signal: {scan.get('modularity_signal', 'unknown')}.",
        f"Repository scale: {scan.get('total_files', 0)} files, {scan.get('total_lines', 0):,} lines.",
        f"Open TODO/FIXME markers in scan: {todo_n}.",
    ]
    if scan.get("git_commits_7d") is not None:
        diagnosis_lines.append(f"Git commits (last 7d): {scan['git_commits_7d']}.")
    if hotspots:
        diagnosis_lines.append("Largest files (refactor pressure): " + "; ".join(hotspots[:3]) + ".")

    return {
        "summary_lines": diagnosis_lines,
        "metrics": {
            "swift_hotspot_score": scan.get("swift_hotspot_score"),
            "modularity_signal": scan.get("modularity_signal"),
            "total_files": scan.get("total_files"),
            "total_lines": scan.get("total_lines"),
            "todo_count": todo_n,
            "git_commits_7d": scan.get("git_commits_7d"),
        },
        "largest_files_preview": top,
    }


def build_product_intelligence(
    scan: dict[str, Any],
    user_signals: dict[str, Any],
    departments: dict[str, Any],
    todays_script: dict[str, Any],
    problems: list[str],
    opportunities: list[str],
    skip_llm: bool,
) -> dict[str, Any]:
    self_dx = build_self_diagnosis(scan)

    heuristic_suggestions: list[str] = [
        "Triage one item from the largest Swift files list to reduce compile-time and merge risk.",
        "Address or ticket the highest-signal TODO/FIXME in scanned files.",
        "Ship the smallest slice of today's one script that improves UX or stability.",
    ]
    if user_signals.get("top_user_pain_points"):
        heuristic_suggestions.insert(
            0,
            "Prioritize backlog items that map to recorded user pain points (see user_signals).",
        )

    suggestions: list[str] = list(heuristic_suggestions)
    note: str | None = None
    llm_product_ok = False
    if not skip_llm:
        sug, note = maybe_product_update_suggestions(
            self_diagnosis=self_dx,
            user_signals=user_signals,
            departments=departments,
            todays_script=todays_script,
            problems=problems,
            opportunities=opportunities,
        )
        if sug and len(sug) >= 3:
            suggestions = sug
            llm_product_ok = True

    return {
        "self_diagnosis": self_dx,
        "user_signals": user_signals,
        "update_suggestions": suggestions[:10],
        "suggestions_note": note,
        "sources": {
            "code_scan": True,
            "user_signals_file": "user_signals.json (optional)",
            "llm_product_suggestions": llm_product_ok,
        },
    }
