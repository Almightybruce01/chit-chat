# Chit Chat Social — Firestore data model

Collections appear in the console when the **first document** is written. Empty projects show no tree until someone signs up or a worker writes data.

## Topology

```
users/{uid}                    ← one doc per Firebase Auth user (profile + dashboard fields)
usernames/{lowercaseUsername}   ← { uid: string } handle reservation
admin_users/{uid}              ← doc exists ⇒ self-serve “internal admin” flag (read own doc only)
_opsAuthRate/{sanitizedIp}     ← Worker-only rate limits (no client access)
```

## `users/{uid}`

| Field | Type | Notes |
|-------|------|--------|
| `uid` | string | Same as document id |
| `email` | string | From Auth |
| `provider` | string | e.g. `password`, `google.com` |
| `username`, `handle`, `displayName`, `enterpriseAlias` | string | App profile |
| `accountEmail`, `accountPhone` | string | Contact |
| `verificationStatus` | string | `unverified` / `pending` / `paid` / `verifiedInternal` |
| `allowEnterpriseReveal`, `isBusinessAccount`, `isAdAccount`, `businessJobPostingApproved` | bool | |
| `businessEIN` … `businessWebsite` | string | Business block |
| `profileId` | string | UUID string |
| `firebaseUserId` | string | Redundant uid for exports |
| `updatedAt` | timestamp | Server |

## `usernames/{lowercaseUsername}`

| Field | Type |
|-------|------|
| `uid` | string (must equal signed-in user) |

## `admin_users/{uid}`

Any fields optional; **existence** of the document is enough for the app to grant internal dashboard entry (after self-read).

## Rules source

See `firestore.rules` in this folder.
