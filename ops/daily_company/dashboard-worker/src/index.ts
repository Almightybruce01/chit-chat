import dashboardHtml from "../static/index.html";

const COOKIE = "ccs_sess";
const DEFAULT_REPORT =
  "https://raw.githubusercontent.com/Almightybruce01/chit-chat/main/ops/daily_company/out/latest-report.json";
const DEFAULT_HISTORY =
  "https://raw.githubusercontent.com/Almightybruce01/chit-chat/main/ops/daily_company/out/history-export.json";

const te = new TextEncoder();

export interface Env {
  DASHBOARD_PASSWORD: string;
  SESSION_SECRET: string;
  REPORT_JSON_URL?: string;
  HISTORY_JSON_URL?: string;
  REPORT_KV?: KVNamespace;
}

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

async function verifyCookie(sessionSecret: string, value: string): Promise<boolean> {
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

async function timingSafeEqualUtf8(a: string, b: string): Promise<boolean> {
  const ea = te.encode(a);
  const eb = te.encode(b);
  if (ea.length !== eb.length) return false;
  let x = 0;
  for (let i = 0; i < ea.length; i++) x |= ea[i] ^ eb[i];
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

async function requireSession(request: Request, env: Env): Promise<Response | null> {
  const tok = getCookie(request, COOKIE);
  if (!tok) return json({ ok: false, error: "unauthorized" }, 401);
  const ok = await verifyCookie(env.SESSION_SECRET, tok);
  if (!ok) return json({ ok: false, error: "unauthorized" }, 401);
  return null;
}

async function proxyJson(request: Request, env: Env, kind: "report" | "history"): Promise<Response> {
  const deny = await requireSession(request, env);
  if (deny) return deny;

  if (env.REPORT_KV) {
    const key = kind === "report" ? "latest-report" : "history-export";
    const body = await env.REPORT_KV.get(key);
    if (body)
      return new Response(body, {
        headers: { "content-type": "application/json; charset=utf-8", "cache-control": "private, no-store" },
      });
  }

  const url =
    kind === "report"
      ? env.REPORT_JSON_URL || DEFAULT_REPORT
      : env.HISTORY_JSON_URL || DEFAULT_HISTORY;
  const r = await fetch(url, { headers: { Accept: "application/json" } });
  if (!r.ok) return json({ ok: false, error: "upstream", status: r.status }, 502);
  const text = await r.text();
  return new Response(text, {
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "private, no-store" },
  });
}

export default {
  async fetch(request: Request, env: Env, _ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname.replace(/\/+$/, "") || "/";

    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": url.origin,
          "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type",
          "Access-Control-Max-Age": "86400",
        },
      });
    }

    if (path === "/logout" && (request.method === "POST" || request.method === "GET")) {
      return new Response(null, { status: 204, headers: clearSessionHeaders() });
    }

    if (path === "/login" && request.method === "POST") {
      let body: { password?: string } = {};
      try {
        body = (await request.json()) as { password?: string };
      } catch {
        return json({ ok: false, error: "bad_json" }, 400);
      }
      const got = typeof body.password === "string" ? body.password : "";
      const expected = env.DASHBOARD_PASSWORD || "";
      if (!expected) return json({ ok: false, error: "server_misconfigured" }, 500);
      const match = await timingSafeEqualUtf8(got, expected);
      if (!match) return json({ ok: false, error: "denied" }, 401);
      const token = await signSession(env.SESSION_SECRET);
      return json({ ok: true }, 200, sessionHeaders(token, 86400 * 7));
    }

    if (path === "/api/session" && request.method === "GET") {
      const tok = getCookie(request, COOKIE);
      if (!tok) return json({ ok: false }, 401);
      const ok = await verifyCookie(env.SESSION_SECRET, tok);
      return ok ? json({ ok: true }) : json({ ok: false }, 401);
    }

    if (path === "/api/latest-report" && request.method === "GET") {
      return proxyJson(request, env, "report");
    }

    if (path === "/api/history-export" && request.method === "GET") {
      return proxyJson(request, env, "history");
    }

    if (path === "/" && request.method === "GET") {
      return new Response(dashboardHtml as string, {
        headers: {
          "content-type": "text/html; charset=utf-8",
          "cache-control": "no-store",
        },
      });
    }

    return new Response("Not found", { status: 404 });
  },
};
