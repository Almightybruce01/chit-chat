//
//  AppStateFirestoreSync.swift
//  Pushes current profile to Firestore when Firebase Auth is active (live dashboard user pool).
//

import Foundation

#if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
import FirebaseAuth

extension AppState {
    /// Call after login / profile changes when the signed-in Firebase user should mirror into `users/{uid}`.
    func pushChitChatUserDirectoryIfFirebaseSignedIn() {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        pushCurrentChitChatProfileToFirestore(
            firebaseUser: firebaseUser,
            profile: currentUser,
            provider: session?.provider ?? "unknown"
        )
    }
}
#endif
