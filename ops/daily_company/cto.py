"""CTO agent: picks exactly ONE highest-ROI improvement — deduped against history + trend-aware."""

from __future__ import annotations

from typing import Any

from .scanner import ScanResult


def _candidates(scan: ScanResult, trend_keywords: list[str]) -> list[dict[str, Any]]:
    """Ordered by default priority; first match wins unless deduped later."""
    out: list[dict[str, Any]] = []
    swift_files = [f for f in scan.files if f.language == "Swift"]
    if not swift_files:
        out.append(
            {
                "title": "Add Swift sources to scan scope",
                "rationale": "No Swift files found under scan root — verify path.",
                "files_to_touch": [],
                "script_type": "ops",
                "steps": ["Run: python -m daily_company --root ."],
                "copy_paste_stub": "",
            }
        )
        return out

    biggest = max(swift_files, key=lambda f: f.lines)
    tw = set(trend_keywords)

    if biggest.lines >= 2500 and "AppState" in biggest.path:
        rationale = f"{biggest.path} is ~{biggest.lines:,} lines — split into FeedState, SocialState, SessionState."
        if tw & {"swift", "ios", "mobile", "performance", "scale"}:
            rationale += " (Trend signal: performance/scale — modular state reduces compile + runtime risk.)"
        out.append(
            {
                "title": "Modularize AppState (god object reduction)",
                "rationale": rationale,
                "files_to_touch": [biggest.path],
                "script_type": "swift_refactor",
                "steps": [
                    "Create AppState+Feed.swift with feed-related @Published + methods.",
                    "Create AppState+Session.swift for user/session.",
                    "Leave AppState as facade forwarding to child stores OR use Composition.",
                ],
                "copy_paste_stub": _stub_appstate_extension(),
            }
        )

    if biggest.lines >= 2000 and "HomeView" in biggest.path:
        out.append(
            {
                "title": "Extract HomeView sections into child views",
                "rationale": f"{biggest.path} exceeds maintainability threshold — extract Feed, Stories, Composer.",
                "files_to_touch": [biggest.path, "Chit Chat/HomeFeedSection.swift (new)"],
                "script_type": "swift_refactor",
                "steps": [
                    "Move feed Group { ... } into HomeFeedSection.swift",
                    "Keep NavigationStack + sheets in HomeView.swift only.",
                ],
                "copy_paste_stub": _stub_home_section(),
            }
        )

    if scan.todo_hits:
        first = scan.todo_hits[0]
        out.append(
            {
                "title": "Close highest-priority TODO",
                "rationale": f"Address technical debt at {first[0]}:{first[1]}.",
                "files_to_touch": [first[0]],
                "script_type": "todo",
                "steps": [
                    "Open file at line",
                    "Resolve or convert to GitHub issue with acceptance criteria.",
                ],
                "copy_paste_stub": f"// Resolved: {first[2][:80]}",
            }
        )

    # Trend-aware fallback
    security_signal = bool(tw & {"security", "auth", "privacy", "cve", "vulnerability"})
    out.append(
        {
            "title": "Add security pass: Keychain review for session tokens",
            "rationale": "Trend or backlog: prioritize secrets & auth hygiene."
            if security_signal
            else "Default rotation when no mega-file pressure.",
            "files_to_touch": ["Chit Chat/AppState.swift", "Chit Chat/LoginView.swift"],
            "script_type": "security",
            "steps": [
                "Audit UserDefaults vs Keychain for sensitive values.",
                "Document threat model in ops/README.md.",
            ],
            "copy_paste_stub": "// MARK: - Security audit notes",
        }
    )

    out.append(
        {
            "title": "Add CI smoke test for build",
            "rationale": "Codebase healthy — automated build verification.",
            "files_to_touch": [".github/workflows/ci.yml"],
            "script_type": "devops",
            "steps": [
                "Add workflow: checkout, xcodebuild build, upload log artifact.",
            ],
            "copy_paste_stub": "# See ops/daily_company/templates/ci-snippet.yml",
        }
    )

    return out


def select_todays_script(
    scan: ScanResult,
    recent_script_titles: list[str] | None = None,
    trend_keywords: list[str] | None = None,
) -> dict[str, Any]:
    recent = set(recent_script_titles or [])
    kw = list(trend_keywords or [])
    for cand in _candidates(scan, kw):
        if cand["title"] not in recent:
            return cand
    # All seen — return first anyway with note
    c = _candidates(scan, kw)[0]
    c["rationale"] = (c.get("rationale") or "") + " [Repeat: history shows this theme; ship a sub-task or close the loop.]"
    return c


def _stub_appstate_extension() -> str:
    return """
// AppState+Feed.swift (new file) — example extraction
import Foundation
import SwiftUI

extension AppState {
    // Move feed/post CRUD here in a follow-up commit
}
""".strip()


def _stub_home_section() -> str:
    return """
// HomeFeedSection.swift (new file)
import SwiftUI

struct HomeFeedSection: View {
    var body: some View {
        Text("Extract feed from HomeView")
    }
}
""".strip()
