import dashboardHtml from "../static/index.html";
import type { Env } from "./env";
import { getFirestoreAccessToken, listUsers, patchUserDocument } from "./firestore";
import {
  clearOpsFailuresForRequest,
  compareOpsPin,
  getOpsPin,
  registerFailedOpsAttempt,
  requireOpsAccess,
} from "./opsAuth";

export type { Env } from "./env";

/** HttpOnly session name — must match `SESSION_COOKIE` in `opsAuth.ts` (rate-limit signal). */
const COOKIE = "ccs_sess";
const te = new TextEncoder();

function json(body: unknown, status = 200, headers: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", ...headers },
  });
}

function base64urlEncodeBytes(buf: ArrayBuffer): string {
  const b = btoa(String.fromCharCode(...new Uint8Array(buf)));
  return b.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function base64urlDecodeToString(s: string): string {
  let t = s.replace(/-/g, "+").replace(/_/g, "/");
  const pad = (4 - (t.length % 4)) % 4;
  t += "=".repeat(pad);
  const bin = atob(t);
  let out = "";
  for (let i = 0; i < bin.length; i++) out += bin[i];
  return out;
}

async function importHmacKey(secret: string): Promise<CryptoKey> {
  return crypto.subtle.importKey("raw", te.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, [
    "sign",
    "verify",
  ]);
}

async function signSession(sessionSecret: string): Promise<string> {
  const exp = Math.floor(Date.now() / 1000) + 86400 * 7;
  const nonce = crypto.randomUUID();
  const payload = `${exp}|${nonce}`;
  const key = await importHmacKey(sessionSecret);
  const payloadBytes = te.encode(payload);
  const sig = await crypto.subtle.sign("HMAC", key, payloadBytes);
  const payloadB64 = base64urlEncodeBytes(
    payloadBytes.buffer.slice(payloadBytes.byteOffset, payloadBytes.byteOffset + payloadBytes.byteLength)
  );
  const sigB64 = base64urlEncodeBytes(sig);
  return `${payloadB64}.${sigB64}`;
}

async function verifyCookieValue(sessionSecret: string, value: string): Promise<boolean> {
  const dot = value.lastIndexOf(".");
  if (dot <= 0) return false;
  const payloadB64 = value.slice(0, dot);
  const sigB64 = value.slice(dot + 1);
  let payload: string;
  try {
    payload = base64urlDecodeToString(payloadB64);
  } catch {
    return false;
  }
  const parts = payload.split("|");
  if (parts.length !== 2) return false;
  const exp = Number(parts[0]);
  if (!Number.isFinite(exp) || exp < Math.floor(Date.now() / 1000)) return false;
  const key = await importHmacKey(sessionSecret);
  const expected = await crypto.subtle.sign("HMAC", key, te.encode(payload));
  const expectedB64 = base64urlEncodeBytes(expected);
  return timingSafeEqualAscii(sigB64, expectedB64);
}

function timingSafeEqualAscii(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let x = 0;
  for (let i = 0; i < a.length; i++) x |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return x === 0;
}

function getCookie(request: Request, name: string): string | null {
  const raw = request.headers.get("Cookie");
  if (!raw) return null;
  for (const part of raw.split(";")) {
    const idx = part.indexOf("=");
    if (idx === -1) continue;
    const k = part.slice(0, idx).trim();
    if (k !== name) continue;
    return decodeURIComponent(part.slice(idx + 1).trim());
  }
  return null;
}

function sessionHeaders(token: string, maxAge: number): Record<string, string> {
  const secure = "HttpOnly; Secure; SameSite=Lax; Path=/";
  return {
    "Set-Cookie": `${COOKIE}=${encodeURIComponent(token)}; ${secure}; Max-Age=${maxAge}`,
  };
}

function clearSessionHeaders(): Record<string, string> {
  const secure = "HttpOnly; Secure; SameSite=Lax; Path=/";
  return { "Set-Cookie": `${COOKIE}=; ${secure}; Max-Age=0` };
}

async function verifyCookieSession(request: Request, env: Env): Promise<boolean> {
  const tok = getCookie(request, COOKIE);
  if (!tok) return false;
  return verifyCookieValue(env.SESSION_SECRET, tok);
}

async function handleLogin(request: Request, env: Env): Promise<Response> {
  const headerPin = request.headers.get("X-Ops-Pin")?.trim() ?? "";
  let candidate = headerPin;
  if (!candidate) {
    try {
      const body = (await request.json()) as { password?: string };
      candidate = typeof body.password === "string" ? body.password.trim() : "";
    } catch {
      candidate = "";
    }
  }

  const expected = getOpsPin(env);
  if (!expected) {
    return json({ ok: false, error: "server_misconfigured" }, 500, { "cache-control": "no-store" });
  }

  const match = await compareOpsPin(candidate, env);
  if (!match) {
    const rl = await registerFailedOpsAttempt(env, request);
    if (rl) return rl;
    return json({ ok: false, error: "unauthorized" }, 401, { "cache-control": "no-store" });
  }

  await clearOpsFailuresForRequest(env, request);
  const token = await signSession(env.SESSION_SECRET);
  return json({ ok: true }, 200, { ...sessionHeaders(token, 86400 * 7), "cache-control": "no-store" });
}

async function proxyJson(request: Request, env: Env, kind: "report" | "history"): Promise<Response> {
  const deny = await requireOpsAccess(request, env, verifyCookieSession);
  if (deny) return deny;

  if (!env.REPORT_KV) {
    return json({ ok: false, error: "kv_not_bound" }, 503, { "cache-control": "no-store" });
  }

  const key = kind === "report" ? "latest-report" : "history-export";
  const body = await env.REPORT_KV.get(key);
  if (!body) {
    return json({ ok: false, error: "report_not_in_kv_run_ci_or_upload" }, 503, { "cache-control": "no-store" });
  }
  return new Response(body, {
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "private, no-store",
    },
  });
}

async function handleAdminUsers(request: Request, env: Env, url: URL): Promise<Response> {
  const deny = await requireOpsAccess(request, env, verifyCookieSession);
  if (deny) return deny;

  const raw = env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw || !raw.trim()) {
    return json({ ok: false, error: "firebase_admin_not_configured" }, 503, { "cache-control": "no-store" });
  }

  const auth = await getFirestoreAccessToken(raw);
  if (!auth) {
    return json({ ok: false, error: "firebase_token_failed" }, 502, { "cache-control": "no-store" });
  }

  if (request.method === "GET") {
    const q = (url.searchParams.get("q") || "").trim().toLowerCase();
    const maxOut = Math.min(500, Math.max(1, Number(url.searchParams.get("limit")) || 200));
    const { users } = await listUsers(auth.projectId, auth.token, 200);
    const filtered = q
      ? users.filter((u) => {
          const hay = [
            String(u.username || ""),
            String(u.displayName || ""),
            String(u.email || ""),
            String(u.handle || ""),
            String(u.uid || ""),
          ]
            .join(" ")
            .toLowerCase();
          return hay.includes(q);
        })
      : users;
    return json({ ok: true, users: filtered.slice(0, maxOut) }, 200, { "cache-control": "no-store" });
  }

  return json({ ok: false, error: "method_not_allowed" }, 405, { "cache-control": "no-store" });
}

async function handleAdminUserPatch(request: Request, env: Env, uid: string): Promise<Response> {
  const deny = await requireOpsAccess(request, env, verifyCookieSession);
  if (deny) return deny;

  if (!/^[a-zA-Z0-9_-]{1,128}$/.test(uid)) {
    return json({ ok: false, error: "invalid_uid" }, 400, { "cache-control": "no-store" });
  }

  const raw = env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw || !raw.trim()) {
    return json({ ok: false, error: "firebase_admin_not_configured" }, 503, { "cache-control": "no-store" });
  }

  const auth = await getFirestoreAccessToken(raw);
  if (!auth) {
    return json({ ok: false, error: "firebase_token_failed" }, 502, { "cache-control": "no-store" });
  }

  let body: Record<string, unknown> = {};
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return json({ ok: false, error: "bad_json" }, 400, { "cache-control": "no-store" });
  }

  const result = await patchUserDocument(auth.projectId, auth.token, uid, body);
  if (!result.ok) {
    return json({ ok: false, error: "firestore_patch_failed", detail: result.body }, result.status, {
      "cache-control": "no-store",
    });
  }
  return json({ ok: true }, 200, { "cache-control": "no-store" });
}

function opsDashboardMeta(): Response {
  return json(
    {
      ok: true,
      surface: "ops",
      auth:
        "Send X-Ops-Pin on each request, or Authorization: Bearer <Firebase ID token> for project aud, or HttpOnly session after POST /api/ops/login. Set OPS_DASHBOARD_PIN (or DASHBOARD_PASSWORD) in production; never embed in static HTML or return defaults in JSON.",
    },
    200,
    { "cache-control": "no-store" }
  );
}

const htmlSecurityHeaders: Record<string, string> = {
  "content-type": "text/html; charset=utf-8",
  "cache-control": "no-store",
  "x-content-type-options": "nosniff",
  "x-frame-options": "DENY",
  "referrer-policy": "no-referrer",
  "x-robots-tag": "noindex, nofollow, noarchive",
  "permissions-policy": "camera=(), microphone=(), geolocation=()",
  "content-security-policy":
    "default-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'self'; img-src 'self' data:; style-src 'unsafe-inline'; script-src 'unsafe-inline'; connect-src 'self'; font-src 'self' data:; upgrade-insecure-requests",
};

const corsOpsHeaders = "Content-Type, X-Ops-Pin, Authorization, Cookie";

export default {
  async fetch(request: Request, env: Env, _ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname.replace(/\/+$/, "") || "/";

    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": url.origin,
          "Access-Control-Allow-Methods": "GET, POST, PATCH, OPTIONS",
          "Access-Control-Allow-Headers": corsOpsHeaders,
          "Access-Control-Max-Age": "86400",
        },
      });
    }

    if (path === "/logout" && (request.method === "POST" || request.method === "GET")) {
      return new Response(null, { status: 204, headers: { ...clearSessionHeaders(), "cache-control": "no-store" } });
    }

    if ((path === "/login" || path === "/api/ops/login") && request.method === "POST") {
      return handleLogin(request, env);
    }

    if (path === "/api/ops/dashboard" && request.method === "GET") {
      const deny = await requireOpsAccess(request, env, verifyCookieSession);
      if (deny) return deny;
      return opsDashboardMeta();
    }

    if (path === "/api/ops/session" && request.method === "GET") {
      const deny = await requireOpsAccess(request, env, verifyCookieSession);
      if (deny) return deny;
      return json({ ok: true }, 200, { "cache-control": "no-store" });
    }

    if (path === "/api/ops/latest-report" && request.method === "GET") {
      return proxyJson(request, env, "report");
    }

    if (path === "/api/ops/history-export" && request.method === "GET") {
      return proxyJson(request, env, "history");
    }

    if (path === "/api/ops/admin/users" && request.method === "GET") {
      return handleAdminUsers(request, env, url);
    }

    const patchOps = path.match(/^\/api\/ops\/admin\/users\/([^/]+)$/);
    if (patchOps && request.method === "PATCH") {
      return handleAdminUserPatch(request, env, patchOps[1]);
    }

    // Legacy paths → same handlers (prefer /api/ops/* for new clients)
    if (path === "/api/session" && request.method === "GET") {
      const deny = await requireOpsAccess(request, env, verifyCookieSession);
      if (deny) return deny;
      return json({ ok: true }, 200, { "cache-control": "no-store" });
    }
    if (path === "/api/latest-report" && request.method === "GET") return proxyJson(request, env, "report");
    if (path === "/api/history-export" && request.method === "GET") return proxyJson(request, env, "history");
    if (path === "/api/admin/users" && request.method === "GET") return handleAdminUsers(request, env, url);
    const patchLegacy = path.match(/^\/api\/admin\/users\/([^/]+)$/);
    if (patchLegacy && request.method === "PATCH") return handleAdminUserPatch(request, env, patchLegacy[1]);

    if (path === "/" && request.method === "GET") {
      return new Response(dashboardHtml as string, {
        headers: htmlSecurityHeaders,
      });
    }

    return new Response("Not found", { status: 404, headers: { "cache-control": "no-store" } });
  },
};
