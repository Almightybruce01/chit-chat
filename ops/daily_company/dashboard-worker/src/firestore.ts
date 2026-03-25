/**
 * Firestore REST + Google service-account OAuth (Workers / Web Crypto).
 * Used only for authenticated dashboard admin routes (session cookie required at router).
 */

const OAUTH_TOKEN_URL = "https://oauth2.googleapis.com/token";
const FIRESTORE_SCOPE = "https://www.googleapis.com/auth/datastore";

let accessTokenCache: { token: string; expMs: number } | null = null;

interface ServiceAccount {
  type?: string;
  project_id: string;
  private_key: string;
  client_email: string;
}

function pemToPkcs8Buffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");
  const raw = atob(b64);
  const buf = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) buf[i] = raw.charCodeAt(i);
  return buf.buffer;
}

function b64url(data: string): string {
  return btoa(data).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

async function signJwtRS256(header: object, payload: object, privateKeyPem: string): Promise<string> {
  const enc = new TextEncoder();
  const head = b64url(JSON.stringify(header));
  const pay = b64url(JSON.stringify(payload));
  const signingInput = `${head}.${pay}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToPkcs8Buffer(privateKeyPem),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, enc.encode(signingInput));
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
  return `${signingInput}.${sigB64}`;
}

export async function getFirestoreAccessToken(serviceAccountJson: string): Promise<{ token: string; projectId: string } | null> {
  let sa: ServiceAccount;
  try {
    sa = JSON.parse(serviceAccountJson) as ServiceAccount;
  } catch {
    return null;
  }
  if (!sa.private_key || !sa.client_email || !sa.project_id) return null;

  const now = Math.floor(Date.now() / 1000);
  if (accessTokenCache && accessTokenCache.expMs > Date.now() + 60_000) {
    return { token: accessTokenCache.token, projectId: sa.project_id };
  }

  const assertion = await signJwtRS256(
    { alg: "RS256", typ: "JWT" },
    {
      iss: sa.client_email,
      sub: sa.client_email,
      aud: OAUTH_TOKEN_URL,
      iat: now,
      exp: now + 3600,
      scope: FIRESTORE_SCOPE,
    },
    sa.private_key
  );

  const body = new URLSearchParams({
    grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
    assertion,
  });

  const tr = await fetch(OAUTH_TOKEN_URL, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: body.toString(),
  });
  if (!tr.ok) return null;
  const tok = (await tr.json()) as { access_token?: string; expires_in?: number };
  if (!tok.access_token) return null;
  const ttl = (tok.expires_in ?? 3600) * 1000;
  accessTokenCache = { token: tok.access_token, expMs: Date.now() + ttl - 120_000 };
  return { token: tok.access_token, projectId: sa.project_id };
}

function unwrapField(v: Record<string, unknown> | undefined): unknown {
  if (!v || typeof v !== "object") return null;
  if ("stringValue" in v) return (v as { stringValue: string }).stringValue;
  if ("integerValue" in v) return Number((v as { integerValue: string }).integerValue);
  if ("doubleValue" in v) return (v as { doubleValue: number }).doubleValue;
  if ("booleanValue" in v) return (v as { booleanValue: boolean }).booleanValue;
  if ("timestampValue" in v) return (v as { timestampValue: string }).timestampValue;
  if ("nullValue" in v) return null;
  return null;
}

export function documentToUserRow(name: string, fields: Record<string, unknown> | undefined): Record<string, unknown> {
  const parts = name.split("/");
  const uid = parts[parts.length - 1] || "";
  const f = fields || {};
  return {
    uid,
    email: unwrapField(f.email as Record<string, unknown>) ?? "",
    username: unwrapField(f.username as Record<string, unknown>) ?? "",
    displayName: unwrapField(f.displayName as Record<string, unknown>) ?? "",
    handle: unwrapField(f.handle as Record<string, unknown>) ?? "",
    enterpriseAlias: unwrapField(f.enterpriseAlias as Record<string, unknown>) ?? "",
    verificationStatus: unwrapField(f.verificationStatus as Record<string, unknown>) ?? "",
    provider: unwrapField(f.provider as Record<string, unknown>) ?? "",
    allowEnterpriseReveal: unwrapField(f.allowEnterpriseReveal as Record<string, unknown>) ?? false,
    isBusinessAccount: unwrapField(f.isBusinessAccount as Record<string, unknown>) ?? false,
    businessJobPostingApproved: unwrapField(f.businessJobPostingApproved as Record<string, unknown>) ?? false,
  };
}

export async function listUsers(
  projectId: string,
  accessToken: string,
  pageSize = 200
): Promise<{ users: Record<string, unknown>[]; nextPageToken?: string }> {
  const users: Record<string, unknown>[] = [];
  let pageToken: string | undefined;
  const base = `https://firestore.googleapis.com/v1/projects/${encodeURIComponent(projectId)}/databases/(default)/documents/users`;

  for (let i = 0; i < 10; i++) {
    const u = new URL(base);
    u.searchParams.set("pageSize", String(pageSize));
    if (pageToken) u.searchParams.set("pageToken", pageToken);

    const r = await fetch(u.toString(), {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    if (!r.ok) return { users };
    const data = (await r.json()) as {
      documents?: { name: string; fields?: Record<string, unknown> }[];
      nextPageToken?: string;
    };
    for (const d of data.documents || []) {
      users.push(documentToUserRow(d.name, d.fields));
    }
    pageToken = data.nextPageToken;
    if (!pageToken) break;
  }
  return { users };
}

const ALLOWED_PATCH = new Set([
  "username",
  "displayName",
  "handle",
  "enterpriseAlias",
  "verificationStatus",
  "email",
  "allowEnterpriseReveal",
  "isBusinessAccount",
  "businessJobPostingApproved",
]);

const VERIFICATION_ENUM = new Set(["unverified", "pending", "paid", "verifiedInternal"]);

function toFirestoreField(value: unknown): Record<string, unknown> {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === "boolean") return { booleanValue: value };
  if (typeof value === "number" && Number.isFinite(value)) {
    if (Number.isInteger(value)) return { integerValue: String(value) };
    return { doubleValue: value };
  }
  return { stringValue: String(value) };
}

export async function patchUserDocument(
  projectId: string,
  accessToken: string,
  uid: string,
  updates: Record<string, unknown>
): Promise<{ ok: boolean; status: number; body?: string }> {
  const safe: Record<string, unknown> = {};
  const mask: string[] = [];
  for (const [k, v] of Object.entries(updates)) {
    if (!ALLOWED_PATCH.has(k)) continue;
    if (k === "verificationStatus" && typeof v === "string" && !VERIFICATION_ENUM.has(v)) continue;
    safe[k] = v;
    mask.push(k);
  }
  if (mask.length === 0) return { ok: false, status: 400, body: "no_valid_fields" };

  const fields: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(safe)) {
    fields[k] = toFirestoreField(v);
  }
  fields["updatedAt"] = { timestampValue: new Date().toISOString() };

  const path = `https://firestore.googleapis.com/v1/projects/${encodeURIComponent(projectId)}/databases/(default)/documents/users/${encodeURIComponent(uid)}`;
  const u = new URL(path);
  u.searchParams.append("updateMask.fieldPaths", "updatedAt");
  for (const m of mask) u.searchParams.append("updateMask.fieldPaths", m);

  const r = await fetch(u.toString(), {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({ fields }),
  });
  const text = await r.text();
  return { ok: r.ok, status: r.status, body: text.slice(0, 500) };
}
