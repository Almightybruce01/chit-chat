"""
Multi-department simulation: each department emits insights from ScanResult only.
(No external LLM in Phase 1 — deterministic rules. Plug OpenAI later in report_generator.)
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from .scanner import ScanResult


@dataclass
class DepartmentOutput:
    name: str
    bullets: list[str]


def _top_swift_files(scan: ScanResult, n: int = 5) -> list[str]:
    swift = [f for f in scan.largest_files if f.language == "Swift"]
    return [f.path for f in swift[:n]]


def product_insights(scan: ScanResult) -> DepartmentOutput:
    bullets = []
    swift_lines = scan.by_language.get("Swift", 0)
    bullets.append(
        f"iOS surface area: ~{swift_lines:,} Swift LOC — prioritize modular splits if any file >3k lines."
    )
    if scan.todo_hits:
        bullets.append(f"Backlog signal: {len(scan.todo_hits)} TODO/FIXME markers in scanned files.")
    else:
        bullets.append("No TODO/FIXME hits in scanned extensions — good hygiene or narrow scan.")
    bullets.append(
        "Elite pattern: ship one high-retention loop daily (feed perf, cold start, or notifications)."
    )
    if getattr(scan, "modularity_signal", "neutral") == "stressed":
        bullets.append("⚠️ Modularity stressed — refactor before adding new features.")
    return DepartmentOutput("Product", bullets)


def engineering_insights(scan: ScanResult) -> DepartmentOutput:
    bullets = []
    tops = _top_swift_files(scan)
    if tops:
        bullets.append(f"Largest Swift modules to refactor first: {', '.join(tops[:3])}.")
    hotspot = getattr(scan, "swift_hotspot_score", 0)
    if hotspot >= 50:
        bullets.append(f"Heat: hotspot score {hotspot:.0f}/100 — consider extraction this week.")
    bullets.append(
        "Backend: ensure LocalBackendService boundaries — add protocol tests before Firebase scale."
    )
    bullets.append("Mobile: audit @MainActor + ObservableObject churn on main tab switches.")
    return DepartmentOutput("Engineering", bullets)


def data_ai_insights(scan: ScanResult) -> DepartmentOutput:
    bullets = [
        f"Telemetry placeholder: correlate commits ({scan.git_commits_7d or 'n/a'} in 7d) with crash-free sessions when you add logging.",
        "Suggest: structured events for tab switches, post create funnel, reel exit.",
    ]
    return DepartmentOutput("Data & AI", bullets)


def devops_insights(scan: ScanResult) -> DepartmentOutput:
    bullets = [
        "CI: enable daily report workflow + optional TestFlight nightly from main.",
        "Cache DerivedData in CI; use xcodebuild -derivedDataPath for reproducible builds.",
    ]
    return DepartmentOutput("DevOps", bullets)


def security_insights(scan: ScanResult) -> DepartmentOutput:
    bullets = [
        "Secrets: keep Firebase keys out of repo; use xcconfig + CI secrets.",
        "Auth: review token storage in Keychain vs UserDefaults for session objects.",
        "Elite: rotate keys if GoogleService-Info.plist ever lived in git history.",
    ]
    return DepartmentOutput("Security", bullets)


def growth_insights(scan: ScanResult) -> DepartmentOutput:
    bullets = [
        "Retention: ship one shareable moment/week (Stories export, referral deep link).",
        "ASO: align subtitle with one clear value prop from Marketing/AI-Promo-Pack.",
    ]
    return DepartmentOutput("Growth", bullets)


def qa_insights(scan: ScanResult) -> DepartmentOutput:
    bullets = [
        "Add UI test: tab bar navigation + Reels exit (regression-prone).",
        "Snapshot or unit test ranking weights if you change AppState scoring.",
    ]
    return DepartmentOutput("QA", bullets)


def run_all_departments(scan: ScanResult) -> dict[str, Any]:
    depts = [
        product_insights(scan),
        engineering_insights(scan),
        data_ai_insights(scan),
        devops_insights(scan),
        security_insights(scan),
        growth_insights(scan),
        qa_insights(scan),
    ]
    return {d.name: {"bullets": d.bullets} for d in depts}
