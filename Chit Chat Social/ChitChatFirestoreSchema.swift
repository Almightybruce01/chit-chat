import Foundation

/// Canonical Firestore **collection ids** for Chit Chat Social.
/// Keep in sync with `firebase/firestore.rules`, `firebase/FIRESTORE_DATA_MODEL.md`,
/// and `ops/daily_company/dashboard-worker/src/chitchatFirestoreCollections.ts`.
enum ChitChatFirestoreSchema {
    enum Collection {
        /// Full app profile + dashboard fields; document id = Firebase Auth `uid`.
        static let users = "users"
        /// Reserved public @handle → `{ "uid": "<Auth uid>" }`; document id = username lowercased.
        static let usernames = "usernames"
        /// Presence = internal ops dashboard access; document id = Auth `uid` (any fields optional).
        static let adminUsers = "admin_users"
        /// Worker-only failed-auth counters; clients denied by rules.
        static let opsAuthRate = "_opsAuthRate"
    }
}
