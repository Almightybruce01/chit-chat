"""
Phase 2: Lightweight 'collaboration' — merge department outputs + trends, resolve conflicts.
Conflict: if Growth suggests viral feature but Engineering flags mega-file, CTO weights stability first.
"""

from __future__ import annotations

from typing import Any

from .scanner import ScanResult


def merge_insights(
    departments: dict[str, Any],
    trends: dict[str, Any],
    scan: ScanResult,
) -> dict[str, Any]:
    keywords = trends.get("keywords", []) if isinstance(trends, dict) else []
    stress = []
    if any(f.lines > 2500 for f in scan.files if f.language == "Swift"):
        stress.append("engineering")
    if keywords and any(k in ("swift", "ios", "mobile", "security") for k in keywords):
        stress.append("growth")
    resolved = {
        "priority_stack": ["stability", "security", "growth", "experimentation"],
        "active_trend_keywords": keywords[:8],
        "conflict_notes": [],
    }
    if "engineering" in stress and keywords:
        resolved["conflict_notes"].append(
            "Engineering priority: large Swift files; defer trend-chasing until refactor landed."
        )
    return resolved
