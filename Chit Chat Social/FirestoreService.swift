//
//  FirestoreService.swift
//  Chit Chat Social
//
//  Created by Brian Bruce on 2025-06-26.
//

import Foundation
import FirebaseAuth
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

/// Persists signed-in user details with Firebase-first fallback to local storage.
func saveUserToFirestore(user: User, provider: String) {
    let payload: [String: String] = [
        "uid": user.uid,
        "email": user.email ?? "",
        "provider": provider
    ]
#if canImport(FirebaseFirestore)
    let db = Firestore.firestore()
    db.collection("users").document(user.uid).setData(payload, merge: true) { error in
        if error != nil {
            UserDefaults.standard.set(payload, forKey: "lastSignedInUser")
        }
    }
#else
    UserDefaults.standard.set(payload, forKey: "lastSignedInUser")
#endif
}

#if canImport(FirebaseFirestore)
/// Merges Chit Chat profile fields into `users/{uid}` for the live admin dashboard (Firestore REST + Worker).
func pushCurrentChitChatProfileToFirestore(firebaseUser: User, profile: UserProfile, provider: String) {
    let db = Firestore.firestore()
    let data: [String: Any] = [
        "uid": firebaseUser.uid,
        "email": firebaseUser.email ?? "",
        "provider": provider,
        "username": profile.username,
        "handle": profile.handle,
        "displayName": profile.displayName,
        "enterpriseAlias": profile.enterpriseAlias,
        "verificationStatus": profile.verificationStatus.rawValue,
        "allowEnterpriseReveal": profile.allowEnterpriseReveal,
        "isBusinessAccount": profile.isBusinessAccount,
        "businessJobPostingApproved": profile.businessJobPostingApproved,
        "updatedAt": FieldValue.serverTimestamp()
    ]
    db.collection("users").document(firebaseUser.uid).setData(data, merge: true)
}
#endif
