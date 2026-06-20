//
//  AppReviewDemoAccount.swift
//  Chit Chat Social
//
//  Dedicated App Store Review login — not tied to any personal account.
//  Auto-provisioned in Firebase; delete-account keeps the server login intact.
//

import Foundation
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif
#if canImport(FirebaseCore)
import FirebaseCore
#endif

enum AppReviewDemoAccount {
    /// Public @handle for App Review notes and screen recordings.
    static let username = "appreview_demo"
    /// Sign-in email (paste into App Store Connect → App Review Information).
    static let email = "appreview.demo@chitchatsocial.review"
    /// Sign-in password (paste into App Store Connect → App Review Information).
    static let password = "ChitChatReview1!"
    static let displayName = "App Review Demo"

    static var normalizedUsername: String {
        ReservedHandles.normalizedKey(username)
    }

    /// Full delete UX runs, but Firebase + Firestore stay so reviewers can sign in again.
    static func shouldPreserveServerAccount(
        username: String,
        accountEmail: String,
        firebaseEmail: String?
    ) -> Bool {
        let key = ReservedHandles.normalizedKey(username)
        if key == normalizedUsername { return true }
        let demoEmail = email.lowercased()
        let candidates = [accountEmail, firebaseEmail ?? ""]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        return candidates.contains(demoEmail)
    }

    /// Creates or repairs the review demo in Firebase when nobody is signed in yet.
    static func ensureProvisionedIfNeeded() async {
#if canImport(FirebaseAuth) && canImport(FirebaseFirestore) && canImport(FirebaseCore)
        guard FirebaseApp.app() != nil else { return }
        guard Auth.auth().currentUser == nil else { return }

        if await signInAndRepair() {
            try? Auth.auth().signOut()
            return
        }
        if await createAndRepair() {
            try? Auth.auth().signOut()
        }
#endif
    }

#if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
    private static func signInAndRepair() async -> Bool {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            await repairFirestore(uid: result.user.uid)
            return true
        } catch {
            return false
        }
    }

    private static func createAndRepair() async -> Bool {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            await repairFirestore(uid: result.user.uid)
            return true
        } catch let error as NSError {
            guard error.domain == AuthErrorDomain,
                  error.code == AuthErrorCode.emailAlreadyInUse.rawValue else {
                return false
            }
            return await signInAndRepair()
        }
    }

    private static func repairFirestore(uid: String) async {
        let db = Firestore.firestore()
        let handle = "@\(username)"
        let profileId = UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890") ?? UUID()
        try? await db.collection(ChitChatFirestoreSchema.Collection.usernames)
            .document(normalizedUsername)
            .setData(["uid": uid], merge: true)
        let data: [String: Any] = [
            "uid": uid,
            "email": email,
            "provider": "password",
            "username": username,
            "handle": handle,
            "displayName": displayName,
            "enterpriseAlias": displayName,
            "verificationStatus": VerificationStatus.unverified.rawValue,
            "allowEnterpriseReveal": false,
            "isBusinessAccount": false,
            "isAdAccount": false,
            "accountEmail": email,
            "accountPhone": "5550100199",
            "profileId": profileId.uuidString,
            "firebaseUserId": uid,
            "appReviewDemo": true,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        try? await db.collection(ChitChatFirestoreSchema.Collection.users)
            .document(uid)
            .setData(data, merge: true)
    }
#endif
}
