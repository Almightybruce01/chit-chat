"""
Phase 3: Append-only history in JSON (git-friendly, CI-safe).
Replaces SQLite for the default path so cloud runs can commit without DB merge hell.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def _path(data_dir: Path) -> Path:
    data_dir.mkdir(parents=True, exist_ok=True)
    return data_dir / "history.json"


def load_history(data_dir: Path) -> list[dict[str, Any]]:
    p = _path(data_dir)
    if not p.is_file():
        return []
    try:
        data = json.loads(p.read_text(encoding="utf-8"))
        return data.get("runs", []) if isinstance(data, dict) else []
    except json.JSONDecodeError:
        return []


def recent_titles(data_dir: Path, days: int = 14) -> list[str]:
    from datetime import timedelta

    runs = load_history(data_dir)
    cutoff = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()
    titles = []
    for r in runs:
        if r.get("generated_at", "") >= cutoff:
            t = r.get("script_title")
            if t:
                titles.append(t)
    return titles


def append_run(
    data_dir: Path,
    script: dict[str, Any],
    scan: dict[str, Any],
    trends: dict[str, Any],
) -> None:
    p = _path(data_dir)
    runs = load_history(data_dir)
    kw = trends.get("keywords", []) if isinstance(trends, dict) else []
    entry = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "script_title": script.get("title", ""),
        "script_type": script.get("script_type", ""),
        "script": script,
        "scan_lines": scan.get("total_lines", 0),
        "scan_files": scan.get("total_files", 0),
        "trend_keywords": kw[:20] if isinstance(kw, list) else [],
    }
    runs.insert(0, entry)
    runs = runs[:120]
    p.write_text(json.dumps({"runs": runs, "updated_at": datetime.now(timezone.utc).isoformat()}, indent=2), encoding="utf-8")


def export_for_dashboard(data_dir: Path, out_json: Path) -> None:
    """Copy shape for static site."""
    runs = load_history(data_dir)
    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(
        json.dumps(
            {
                "runs": runs[:60],
                "exported_at": datetime.now(timezone.utc).isoformat(),
            },
            indent=2,
        ),
        encoding="utf-8",
    )
