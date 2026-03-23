"""
GitHub API (optional token). Without token: only public rate limits.
"""

from __future__ import annotations

import json
import os
import ssl
import urllib.error
import urllib.request
from typing import Any


def fetch_repo_meta(owner_repo: str, token: str | None = None) -> dict[str, Any]:
    """
    owner_repo like 'octocat/Hello-World'. Requires GITHUB_TOKEN for private repos.
    """
    token = token or os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    url = f"https://api.github.com/repos/{owner_repo}"
    headers = {
        "User-Agent": "ChitChat-AICompany/1.0",
        "Accept": "application/vnd.github+json",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, headers=headers)
    ctx = ssl.create_default_context()
    try:
        with urllib.request.urlopen(req, timeout=20, context=ctx) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError, json.JSONDecodeError) as e:
        return {"error": str(e)}


def detect_owner_repo_from_git(remote_url: str | None) -> str | None:
    """
    Parse git@github.com:org/repo.git or https://github.com/org/repo
    """
    if not remote_url:
        return None
    u = remote_url.strip()
    if "github.com" not in u:
        return None
    if u.startswith("git@"):
        # git@github.com:org/repo.git
        part = u.split(":", 1)[-1].replace(".git", "")
        return part if "/" in part else None
    if "github.com/" in u:
        tail = u.split("github.com/", 1)[-1].split("/")
        if len(tail) >= 2:
            return f"{tail[0]}/{tail[1].replace('.git', '')}"
    return None
