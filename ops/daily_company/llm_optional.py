"""
Optional LLM enrichment (OpenAI-compatible). No pip: stdlib urllib + json.
Set OPENAI_API_KEY in environment or GitHub Secrets.
"""

from __future__ import annotations

import json
import os
import ssl
import urllib.error
import urllib.request
from typing import Any


def maybe_enrich_executive_summary(
    base_bullets: list[str],
    report_context: dict[str, Any],
) -> tuple[list[str], str | None]:
    """
    Returns (bullets, error_or_none).
    If no API key, returns base_bullets unchanged.
    """
    key = os.environ.get("OPENAI_API_KEY") or os.environ.get("OPENAI_KEY")
    if not key:
        return base_bullets, None

    model = os.environ.get("OPENAI_MODEL", "gpt-4o-mini")
    payload = {
        "model": model,
        "messages": [
            {
                "role": "system",
                "content": "You are CTO of a mobile software company. Output 3-5 tight bullets; no fluff.",
            },
            {
                "role": "user",
                "content": json.dumps(
                    {
                        "existing_bullets": base_bullets,
                        "context": report_context,
                    },
                    ensure_ascii=False,
                )[:12000],
            },
        ],
        "temperature": 0.35,
        "max_tokens": 400,
    }
    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        "https://api.openai.com/v1/chat/completions",
        data=body,
        method="POST",
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {key}",
        },
    )
    ctx = ssl.create_default_context()
    try:
        with urllib.request.urlopen(req, timeout=60, context=ctx) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        text = (data.get("choices") or [{}])[0].get("message", {}).get("content") or ""
        lines = [ln.strip().lstrip("-• ") for ln in text.splitlines() if ln.strip()]
        if len(lines) >= 3:
            return lines[:6], None
    except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError, json.JSONDecodeError, KeyError) as e:
        return base_bullets, str(e)
    return base_bullets, "empty_llm_response"
