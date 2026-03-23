"""
Codebase scanner: file counts, lines, hotspots, TODOs, git activity.
Skips build artifacts and common junk dirs.
"""

from __future__ import annotations

import os
import re
import subprocess
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

SKIP_DIR_NAMES = {
    ".git",
    "DerivedData",
    "build",
    "Build",
    "node_modules",
    ".build",
    "Pods",
    "Carthage",
    ".swiftpm",
    "__pycache__",
    ".venv",
    "venv",
    ".idea",
    ".cursor",
}

SKIP_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".ico", ".pdf", ".zip", ".xcuserstate"}


@dataclass
class FileStat:
    path: str
    lines: int
    language: str


@dataclass
class ScanResult:
    root: str
    files: list[FileStat] = field(default_factory=list)
    total_lines: int = 0
    by_language: dict[str, int] = field(default_factory=dict)
    todo_hits: list[tuple[str, int, str]] = field(default_factory=list)
    largest_files: list[FileStat] = field(default_factory=list)
    git_commits_7d: int | None = None
    git_last_commit: str | None = None

    def to_dict(self) -> dict:
        return {
            "root": self.root,
            "total_files": len(self.files),
            "total_lines": self.total_lines,
            "by_language": dict(sorted(self.by_language.items(), key=lambda x: -x[1])),
            "largest_files": [
                {"path": f.path, "lines": f.lines, "language": f.language}
                for f in self.largest_files[:15]
            ],
            "todo_hits": [
                {"path": p, "line": n, "snippet": s[:200]}
                for p, n, s in self.todo_hits[:40]
            ],
            "git_commits_7d": self.git_commits_7d,
            "git_last_commit": self.git_last_commit,
        }


def _lang_for_suffix(suffix: str) -> str:
    m = {
        ".swift": "Swift",
        ".py": "Python",
        ".ts": "TypeScript",
        ".tsx": "TypeScript",
        ".js": "JavaScript",
        ".json": "JSON",
        ".md": "Markdown",
        ".yml": "YAML",
        ".yaml": "YAML",
        ".html": "HTML",
        ".css": "CSS",
    }
    return m.get(suffix.lower(), suffix.lstrip(".") or "other")


def _should_skip_dir(path: Path) -> bool:
    return path.name in SKIP_DIR_NAMES


def walk_code_files(root: Path) -> Iterable[Path]:
    for dirpath, dirnames, filenames in os.walk(root):
        # prune
        dirnames[:] = [d for d in dirnames if not _should_skip_dir(Path(dirpath) / d)]
        for name in filenames:
            p = Path(dirpath) / name
            if p.suffix.lower() in SKIP_EXTENSIONS:
                continue
            if p.suffix.lower() in {".swift", ".py", ".ts", ".tsx", ".js", ".md", ".json", ".yml", ".yaml"}:
                yield p


TODO_RE = re.compile(r"(TODO|FIXME|HACK|XXX)(\s*:|)", re.I)


def scan_project(root: str | Path) -> ScanResult:
    root = Path(root).resolve()
    result = ScanResult(root=str(root))
    files: list[FileStat] = []

    for path in walk_code_files(root):
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        lines = text.count("\n") + (1 if text and not text.endswith("\n") else 0)
        rel = str(path.relative_to(root))
        lang = _lang_for_suffix(path.suffix)
        files.append(FileStat(path=rel, lines=lines, language=lang))
        result.by_language[lang] = result.by_language.get(lang, 0) + lines
        result.total_lines += lines
        for i, line in enumerate(text.splitlines(), 1):
            if TODO_RE.search(line):
                result.todo_hits.append((rel, i, line.strip()))

    files.sort(key=lambda f: -f.lines)
    result.files = files
    result.largest_files = files[:20]

    # Git (optional)
    git_dir = root / ".git"
    if git_dir.is_dir():
        try:
            out = subprocess.run(
                ["git", "-C", str(root), "rev-list", "--count", "--since=7.days ago", "HEAD"],
                capture_output=True,
                text=True,
                timeout=30,
            )
            if out.returncode == 0 and out.stdout.strip().isdigit():
                result.git_commits_7d = int(out.stdout.strip())
        except (subprocess.SubprocessError, FileNotFoundError, ValueError):
            pass
        try:
            out = subprocess.run(
                ["git", "-C", str(root), "log", "-1", "--format=%ci %s"],
                capture_output=True,
                text=True,
                timeout=15,
            )
            if out.returncode == 0:
                result.git_last_commit = out.stdout.strip() or None
        except (subprocess.SubprocessError, FileNotFoundError):
            pass

    return result
