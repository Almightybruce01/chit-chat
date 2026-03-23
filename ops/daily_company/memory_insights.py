"""
Phase 3: Self-improving memory — analyze run history without ML.
Surfaces repeat themes, streaks, and suggested rotation.
"""

from __future__ import annotations

from collections import Counter
from pathlib import Path
from typing import Any

from .history_store import load_history


def analyze_history(data_dir: Path) -> dict[str, Any]:
    runs = load_history(data_dir)
    if not runs:
        return {
            "run_count": 0,
            "insights": ["No prior runs — history will build after daily reports."],
            "top_script_types": [],
            "repeat_titles": [],
        }

    titles = [r.get("script_title", "") for r in runs if r.get("script_title")]
    types = [r.get("script_type", "") for r in runs if r.get("script_type")]
    title_counts = Counter(titles)
    repeat_titles = [t for t, c in title_counts.most_common(5) if c >= 2]

    insights: list[str] = []
    if repeat_titles:
        insights.append(
            f"Repeat focus areas (ship sub-tasks or close the loop): {', '.join(repeat_titles[:3])}"
        )
    swift_trend = [r for r in runs[:20] if "swift" in " ".join(r.get("trend_keywords", [])).lower()]
    if len(swift_trend) >= 5:
        insights.append("Trend memory: Swift/iOS keywords appeared often — align backlog with mobile performance.")

    lines = [r.get("scan_lines", 0) for r in runs[:10] if isinstance(r.get("scan_lines"), int)]
    if len(lines) >= 2 and lines[0] > lines[-1]:
        insights.append(f"LOC grew from {lines[-1]:,} → {lines[0]:,} — consider pruning dead code weekly.")

    return {
        "run_count": len(runs),
        "insights": insights or ["History healthy — rotate script types for breadth."],
        "top_script_types": [t for t, _ in Counter(types).most_common(5)],
        "repeat_titles": repeat_titles,
    }
