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
    db.collection(ChitChatFirestoreSchema.Collection.users).document(user.uid).setData(payload, merge: true) { error in
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
        "isAdAccount": profile.isAdAccount,
        "businessJobPostingApproved": profile.businessJobPostingApproved,
        "businessEIN": profile.businessEIN,
        "businessLegalName": profile.businessLegalName,
        "businessDBA": profile.businessDBA,
        "businessAddressLine1": profile.businessAddressLine1,
        "businessCity": profile.businessCity,
        "businessState": profile.businessState,
        "businessZIP": profile.businessZIP,
        "businessPhone": profile.businessPhone,
        "businessWebsite": profile.businessWebsite,
        "accountEmail": profile.accountEmail,
        "accountPhone": profile.accountPhone,
        "profileId": profile.id.uuidString,
        "firebaseUserId": firebaseUser.uid,
        "updatedAt": FieldValue.serverTimestamp()
    ]
    db.collection(ChitChatFirestoreSchema.Collection.users).document(firebaseUser.uid).setData(data, merge: true)
}

/// Builds a `UserProfile` from merged `users/{uid}` fields (best-effort).
func userProfileFromChitChatFirestoreData(_ data: [String: Any], uid: String, existing: UserProfile? = nil) -> UserProfile {
    let profileId = (data["profileId"] as? String).flatMap(UUID.init(uuidString:))
        ?? existing?.id
        ?? UUID()
    let usernameTrimmed = (data["username"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let username = usernameTrimmed.isEmpty ? "user" : usernameTrimmed
    let handleRaw = (data["handle"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "@\(username)"
    let handle = handleRaw.hasPrefix("@") ? handleRaw : "@\(handleRaw)"
    let displayNameTrimmed = (data["displayName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let displayName = displayNameTrimmed.isEmpty ? username : displayNameTrimmed
    let enterpriseTrimmed = (data["enterpriseAlias"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let enterpriseAlias = enterpriseTrimmed.isEmpty ? displayName : enterpriseTrimmed
    let followers = data["followers"] as? Int ?? 0
    let verificationRaw = (data["verificationStatus"] as? String) ?? VerificationStatus.unverified.rawValue
    let verification = VerificationStatus(rawValue: verificationRaw) ?? .unverified
    let allowEnterprise = data["allowEnterpriseReveal"] as? Bool ?? false
    var profile = UserProfile(
        id: profileId,
        username: username,
        handle: handle,
        accountEmail: (data["accountEmail"] as? String) ?? (data["email"] as? String) ?? existing?.accountEmail ?? "",
        accountPhone: (data["accountPhone"] as? String) ?? existing?.accountPhone ?? "",
        enterpriseAlias: enterpriseAlias,
        displayName: displayName,
        followers: followers,
        verificationStatus: verification,
        allowEnterpriseReveal: allowEnterprise,
        linkedPlatforms: []
    )
    profile.firebaseUserId = uid
    profile.isBusinessAccount = data["isBusinessAccount"] as? Bool ?? false
    profile.isAdAccount = data["isAdAccount"] as? Bool ?? false
    profile.businessJobPostingApproved = data["businessJobPostingApproved"] as? Bool ?? false
    profile.businessEIN = data["businessEIN"] as? String ?? ""
    profile.businessLegalName = data["businessLegalName"] as? String ?? ""
    profile.businessDBA = data["businessDBA"] as? String ?? ""
    profile.businessAddressLine1 = data["businessAddressLine1"] as? String ?? ""
    profile.businessCity = data["businessCity"] as? String ?? ""
    profile.businessState = data["businessState"] as? String ?? ""
    profile.businessZIP = data["businessZIP"] as? String ?? ""
    profile.businessPhone = data["businessPhone"] as? String ?? ""
    profile.businessWebsite = data["businessWebsite"] as? String ?? ""
    return profile
}
#endif
