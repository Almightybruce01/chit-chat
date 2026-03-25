export interface Env {
  /** Preferred ops PIN secret (Hit-A-Lick pattern). Falls back to DASHBOARD_PASSWORD. */
  OPS_DASHBOARD_PIN?: string;
  DASHBOARD_PASSWORD?: string;
  SESSION_SECRET: string;
  REPORT_KV?: KVNamespace;
  FIREBASE_SERVICE_ACCOUNT_JSON?: string;
}
