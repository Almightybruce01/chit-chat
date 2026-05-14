/**
 * Canonical Firestore collection ids — keep in sync with:
 * - firebase/firestore.rules
 * - firebase/FIRESTORE_DATA_MODEL.md
 * - Chit Chat Social/ChitChatFirestoreSchema.swift
 */
export const CHITCHAT_FS = {
  users: "users",
  usernames: "usernames",
  adminUsers: "admin_users",
  opsAuthRate: "_opsAuthRate",
} as const;
