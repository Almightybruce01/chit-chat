//
//  FirestoreService.swift
//  Chit Chat
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
