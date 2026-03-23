"""
Phase 2: Trend ingestion (no API keys) — Hacker News, RSS-style dev headlines.
Uses stdlib only: urllib + json + xml.etree for basic RSS.
"""

from __future__ import annotations

import json
import re
import ssl
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

from xml.etree import ElementTree

USER_AGENT = "ChitChat-AICompany/1.0 (+https://github.com)"


def _fetch(url: str, timeout: float = 20.0) -> bytes:
    ctx = ssl.create_default_context()
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=timeout, context=ctx) as resp:
        return resp.read()


def fetch_hacker_news_top(n: int = 8) -> dict[str, Any]:
    """HN Firebase API — public, no key."""
    try:
        raw = _fetch("https://hacker-news.firebaseio.com/v0/topstories.json?print=pretty")
        ids = json.loads(raw.decode("utf-8"))
        if not isinstance(ids, list):
            return {"error": "unexpected shape", "items": []}
        items = []
        for story_id in ids[: min(n * 2, 40)]:
            if len(items) >= n:
                break
            try:
                sraw = _fetch(f"https://hacker-news.firebaseio.com/v0/item/{story_id}.json")
                s = json.loads(sraw.decode("utf-8"))
                if not isinstance(s, dict):
                    continue
                title = s.get("title") or ""
                url = s.get("url") or f"https://news.ycombinator.com/item?id={story_id}"
                if not title:
                    continue
                items.append(
                    {"title": title, "url": url, "score": s.get("score"), "source": "Hacker News"}
                )
            except (urllib.error.URLError, json.JSONDecodeError, TimeoutError):
                continue
        return {"fetched_at": datetime.now(timezone.utc).isoformat(), "items": items}
    except (urllib.error.URLError, json.JSONDecodeError, TimeoutError) as e:
        return {"error": str(e), "items": []}


def _rss_text_to_items(xml_text: str, source: str, limit: int = 5) -> list[dict[str, Any]]:
    items: list[dict[str, Any]] = []
    try:
        root = ElementTree.fromstring(xml_text)
    except ElementTree.ParseError:
        return items
    # RSS 2.0: channel/item
    for item in root.iter():
        if item.tag.endswith("item") or item.tag == "item":
            title_el = next((c for c in item if c.tag.endswith("title") or c.tag == "title"), None)
            link_el = next((c for c in item if c.tag.endswith("link") or c.tag == "link"), None)
            title = (title_el.text or "").strip() if title_el is not None else ""
            link = (link_el.text or "").strip() if link_el is not None else ""
            if title:
                items.append({"title": title, "url": link or "#", "source": source})
            if len(items) >= limit:
                break
    return items


def fetch_rss_feed(url: str, source_label: str, limit: int = 5) -> dict[str, Any]:
    try:
        raw = _fetch(url)
        text = raw.decode("utf-8", errors="replace")
        # Strip illegal XML chars sometimes present in feeds
        text = re.sub(r"[\x00-\x08\x0B\x0C\x0E-\x1F]", "", text)
        items = _rss_text_to_items(text, source_label, limit=limit)
        return {"fetched_at": datetime.now(timezone.utc).isoformat(), "items": items}
    except (urllib.error.URLError, TimeoutError) as e:
        return {"error": str(e), "items": []}


def aggregate_trends(
    db_path: Path | None = None,
    cache_get: Callable[[str], dict[str, Any] | None] | None = None,
    cache_set: Callable[[str, dict[str, Any]], None] | None = None,
) -> dict[str, Any]:
    """
    Returns {sources: {hacker_news, dev_to}, keywords: [...]}
    Optional cache via callbacks or memory.db (import in caller).
    """
    cache_key = "aggregate_v1"
    if cache_get:
        cached = cache_get(cache_key)
        if cached:
            return cached

    hn = fetch_hacker_news_top(8)
    devto = fetch_rss_feed("https://dev.to/feed", "DEV Community", 5)

    # Extract keywords from titles
    blob = " ".join(
        [x.get("title", "") for x in hn.get("items", [])]
        + [x.get("title", "") for x in devto.get("items", [])]
    ).lower()
    words = re.findall(r"[a-z]{2,}", blob)
    stop = {
        "the", "and", "for", "with", "from", "that", "this", "have", "has", "are", "was", "how", "new", "you", "not",
        "can", "all", "one", "out", "get", "use", "app", "web", "api",
    }
    freq: dict[str, int] = {}
    for w in words:
        if w in stop or len(w) < 4:
            continue
        freq[w] = freq.get(w, 0) + 1
    top_kw = sorted(freq.keys(), key=lambda k: -freq[k])[:12]

    out = {
        "fetched_at": datetime.now(timezone.utc).isoformat(),
        "sources": {
            "hacker_news": hn,
            "dev_to": devto,
        },
        "keywords": top_kw,
    }
    if cache_set:
        cache_set(cache_key, out)
    return out
