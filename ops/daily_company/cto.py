"""CTO agent: picks exactly ONE highest-ROI improvement — deduped, trend-aware, elite priority scoring."""

from __future__ import annotations

from typing import Any

from .scanner import ScanResult

# Elite ROI weights: stability/security > refactor > todo > ux > devops > ops
ROI_WEIGHTS = {"security": 1.0, "swift_refactor": 0.95, "todo": 0.9, "ux": 0.85, "devops": 0.75, "ops": 0.6}


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
                "files_to_touch": [biggest.path, "Chit Chat Social/HomeFeedSection.swift (new)"],
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
            "files_to_touch": ["Chit Chat Social/AppState.swift", "Chit Chat Social/LoginView.swift"],
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

    # Elite: performance & accessibility
    if any("View" in f.path for f in scan.files if f.language == "Swift"):
        out.append(
            {
                "title": "Add accessibility audit: VoiceOver labels on key flows",
                "rationale": "HIG compliance — improves App Store review readiness and inclusivity.",
                "files_to_touch": ["Chit Chat Social/HomeView.swift", "Chit Chat Social/MainTabView.swift"],
                "script_type": "ux",
                "steps": [
                    "Add .accessibilityLabel() to primary buttons (Create, Reels, Home).",
                    "Ensure feed cards have meaningful accessibilityHint.",
                ],
                "copy_paste_stub": ".accessibilityLabel(\"Create post\")",
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
    candidates = _candidates(scan, kw)

    # Elite: score unseen candidates by ROI weight, then pick highest
    scored = []
    for c in candidates:
        if c["title"] in recent:
            continue
        w = ROI_WEIGHTS.get(c.get("script_type", ""), 0.5)
        # Boost if hotspot stressed and script is refactor
        if scan.modularity_signal == "stressed" and c.get("script_type") == "swift_refactor":
            w *= 1.15
        scored.append((w, c))

    if scored:
        scored.sort(key=lambda x: -x[0])
        return scored[0][1]

    # All seen — return highest-ROI with repeat note
    scored_all = [(ROI_WEIGHTS.get(c.get("script_type", ""), 0.5), c) for c in candidates]
    scored_all.sort(key=lambda x: -x[0])
    c = scored_all[0][1].copy()
    c["rationale"] = (c.get("rationale") or "") + " [Repeat: ship a sub-task or close the loop.]"
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
