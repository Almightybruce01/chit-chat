/**
 * Ops surface auth: X-Ops-Pin (constant-time), optional Firebase ID Bearer, or HttpOnly session.
 * Failed attempts: Firestore `_opsAuthRate/{ip}` when service account is configured (Hit-A-Lick pattern),
 * else KV keys `opsrl:*` on REPORT_KV.
 */

import type { Env } from "./env";
import { clearOpsAuthFailuresFirestore, recordOpsAuthFailureFirestore } from "./opsRateFirestore";

const WINDOW_MS = 15 * 60 * 1000;
const MAX_FAIL = 24;
const RATE_KEY_PREFIX = "opsrl:";

function json(body: unknown, status = 200, headers: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", ...headers },
  });
}

export function getOpsPin(env: Env): string {
  return (env.OPS_DASHBOARD_PIN || env.DASHBOARD_PASSWORD || "").trim();
}

export function clientIp(request: Request): string {
  return request.headers.get("CF-Connecting-IP") || request.headers.get("X-Forwarded-For")?.split(",")[0]?.trim() || "unknown";
}

const SESSION_COOKIE = "ccs_sess";

/** True if the client sent something we should treat as an auth attempt (wrong attempts are rate-limited). Anonymous probes (e.g. session check on first load) are not counted. */
export function hasOpsCredentialSignal(request: Request): boolean {
  if ((request.headers.get("X-Ops-Pin") ?? "").trim().length > 0) return true;
  const authz = request.headers.get("Authorization") || "";
  if (authz.startsWith("Bearer ") && authz.slice(7).trim().length > 0) return true;
  const raw = request.headers.get("Cookie") || "";
  const m = raw.match(new RegExp(`(?:^|;\\s*)${SESSION_COOKIE}=([^;]*)`));
  return !!(m && decodeURIComponent((m[1] || "").trim()).length > 0);
}

async function timingSafeEqualUtf8(a: string, b: string): Promise<boolean> {
  const te = new TextEncoder();
  const ea = te.encode(a);
  const eb = te.encode(b);
  if (ea.length !== eb.length) return false;
  let x = 0;
  for (let i = 0; i < ea.length; i++) x |= ea[i] ^ eb[i];
  return x === 0;
}

/** Constant-time compare against configured ops PIN. */
export async function compareOpsPin(candidate: string, env: Env): Promise<boolean> {
  const expected = getOpsPin(env);
  if (!expected) return false;
  return timingSafeEqualUtf8(candidate, expected);
}

async function recordFailureKv(kv: KVNamespace | undefined, ip: string): Promise<boolean> {
  if (!kv) return false;
  const key = RATE_KEY_PREFIX + ip.slice(0, 200);
  let raw: { c: number; t: number } | null = null;
  try {
    raw = JSON.parse((await kv.get(key)) || "null") as { c: number; t: number } | null;
  } catch {
    raw = null;
  }
  const now = Date.now();
  let c = 1;
  let t = now;
  if (raw && now - raw.t < WINDOW_MS) {
    c = raw.c + 1;
    t = raw.t;
  }
  await kv.put(key, JSON.stringify({ c, t }), { expirationTtl: 960 });
  return c > MAX_FAIL;
}

async function clearFailuresKv(kv: KVNamespace | undefined, ip: string): Promise<void> {
  if (!kv) return;
  await kv.delete(RATE_KEY_PREFIX + ip.slice(0, 200));
}

/** Firestore first (if configured), else KV. @returns true if rate-limited (block request). */
async function recordFailureCombined(env: Env, ip: string): Promise<boolean> {
  const fr = await recordOpsAuthFailureFirestore(env, ip);
  if (fr !== null) return fr;
  return recordFailureKv(env.REPORT_KV, ip);
}

async function clearFailuresCombined(env: Env, ip: string): Promise<void> {
  await clearOpsAuthFailuresFirestore(env, ip);
  await clearFailuresKv(env.REPORT_KV, ip);
}

function parseServiceAccountProjectId(jsonStr: string): string | null {
  try {
    const j = JSON.parse(jsonStr) as { project_id?: string };
    return j.project_id?.trim() || null;
  } catch {
    return null;
  }
}

async function verifyFirebaseBearer(token: string, expectedProjectId: string | null): Promise<boolean> {
  if (!expectedProjectId || !token) return false;
  const r = await fetch(`https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=${encodeURIComponent(token)}`, {
    headers: { Accept: "application/json" },
  });
  if (!r.ok) return false;
  let j: { aud?: string; exp?: string };
  try {
    j = (await r.json()) as { aud?: string; exp?: string };
  } catch {
    return false;
  }
  if (j.aud !== expectedProjectId) return false;
  const exp = Number(j.exp);
  if (!Number.isFinite(exp) || exp < Math.floor(Date.now() / 1000)) return false;
  return true;
}

export type SessionCheck = (request: Request, env: Env) => Promise<boolean>;

export async function requireOpsAccess(request: Request, env: Env, verifyCookieSession: SessionCheck): Promise<Response | null> {
  const ip = clientIp(request);
  const pin = getOpsPin(env);
  let ok = false;

  if (pin) {
    const headerPin = request.headers.get("X-Ops-Pin") ?? "";
    ok = await compareOpsPin(headerPin.trim(), env);
  }

  if (!ok) {
    const authz = request.headers.get("Authorization") || "";
    if (authz.startsWith("Bearer ")) {
      const tok = authz.slice(7).trim();
      const pid = env.FIREBASE_SERVICE_ACCOUNT_JSON
        ? parseServiceAccountProjectId(env.FIREBASE_SERVICE_ACCOUNT_JSON)
        : null;
      ok = await verifyFirebaseBearer(tok, pid);
    }
  }

  if (!ok) {
    ok = await verifyCookieSession(request, env);
  }

  if (!ok) {
    if (hasOpsCredentialSignal(request)) {
      const limited = await recordFailureCombined(env, ip);
      if (limited) {
        return json({ ok: false, error: "rate_limited" }, 429, {
          "cache-control": "no-store",
          "retry-after": "60",
        });
      }
    }
    return json({ ok: false, error: "unauthorized" }, 401, { "cache-control": "no-store" });
  }

  await clearFailuresCombined(env, ip);
  return null;
}

/** Call after wrong PIN / bad login body (before returning 401). */
export async function registerFailedOpsAttempt(env: Env, request: Request): Promise<Response | null> {
  const limited = await recordFailureCombined(env, clientIp(request));
  if (limited) {
    return json({ ok: false, error: "rate_limited" }, 429, {
      "cache-control": "no-store",
      "retry-after": "60",
    });
  }
  return null;
}

export async function clearOpsFailuresForRequest(env: Env, request: Request): Promise<void> {
  await clearFailuresCombined(env, clientIp(request));
}
