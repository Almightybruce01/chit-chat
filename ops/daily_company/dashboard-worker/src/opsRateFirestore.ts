/**
 * Hit-A-Lick–style failed-auth rate limiting in Firestore `_opsAuthRate/{sanitizedIp}`.
 * Falls back to KV when service account is unavailable. Uses same window/max as KV path.
 */

import type { Env } from "./env";
import { getFirestoreAccessToken } from "./firestore";

const COLLECTION = "_opsAuthRate";
export const OPS_RATE_WINDOW_MS = 15 * 60 * 1000;
export const OPS_RATE_MAX_FAIL = 24;

function safeDocId(ip: string): string {
  const s = ip.replace(/[^a-zA-Z0-9_.~-]/g, "_").slice(0, 150);
  return s || "unknown";
}

function intField(n: number): Record<string, unknown> {
  return { integerValue: String(Math.floor(n)) };
}

function readIntField(f: Record<string, unknown> | undefined): number {
  if (!f || typeof f !== "object") return 0;
  if ("integerValue" in f) return Number((f as { integerValue: string }).integerValue) || 0;
  return 0;
}

function docUrl(projectId: string, docId: string): string {
  const enc = encodeURIComponent(docId);
  return `https://firestore.googleapis.com/v1/projects/${encodeURIComponent(projectId)}/databases/(default)/documents/${COLLECTION}/${enc}`;
}

/** @returns true if blocked, false if under limit, null if Firestore path skipped */
export async function recordOpsAuthFailureFirestore(env: Env, ip: string): Promise<boolean | null> {
  const raw = env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim();
  if (!raw) return null;

  const auth = await getFirestoreAccessToken(raw);
  if (!auth) return null;

  const docId = safeDocId(ip);
  const url = docUrl(auth.projectId, docId);
  const headers = { Authorization: `Bearer ${auth.token}`, Accept: "application/json" };

  const gr = await fetch(url, { headers });
  const now = Date.now();
  let count = 0;
  let windowStart = now;

  if (gr.ok) {
    try {
      const d = (await gr.json()) as { fields?: Record<string, Record<string, unknown>> };
      const f = d.fields || {};
      count = readIntField(f.count);
      windowStart = readIntField(f.windowStart) || now;
    } catch {
      count = 0;
      windowStart = now;
    }
    if (now - windowStart > OPS_RATE_WINDOW_MS) {
      count = 0;
      windowStart = now;
    }
    count += 1;
  } else if (gr.status === 404) {
    count = 1;
    windowStart = now;
    const cr = await fetch(
      `https://firestore.googleapis.com/v1/projects/${encodeURIComponent(auth.projectId)}/databases/(default)/documents/${COLLECTION}?documentId=${encodeURIComponent(docId)}`,
      {
        method: "POST",
        headers: { ...headers, "content-type": "application/json" },
        body: JSON.stringify({
          fields: {
            count: intField(count),
            windowStart: intField(windowStart),
          },
        }),
      }
    );
    if (!cr.ok) return null;
    return count > OPS_RATE_MAX_FAIL;
  } else {
    return null;
  }

  const patchUrl = `${url}?updateMask.fieldPaths=count&updateMask.fieldPaths=windowStart`;
  const pr = await fetch(patchUrl, {
    method: "PATCH",
    headers: { ...headers, "content-type": "application/json" },
    body: JSON.stringify({
      fields: {
        count: intField(count),
        windowStart: intField(windowStart),
      },
    }),
  });
  if (!pr.ok) return null;
  return count > OPS_RATE_MAX_FAIL;
}

export async function clearOpsAuthFailuresFirestore(env: Env, ip: string): Promise<void> {
  const raw = env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim();
  if (!raw) return;
  const auth = await getFirestoreAccessToken(raw);
  if (!auth) return;
  const docId = safeDocId(ip);
  await fetch(docUrl(auth.projectId, docId), {
    method: "DELETE",
    headers: { Authorization: `Bearer ${auth.token}` },
  });
}
