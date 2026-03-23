//
//  Chit_ChatTests.swift
//  Chit ChatTests
//
//  Created by Brian Bruce on 2025-06-24.
//

import Foundation
import Testing
@testable import Chit_Chat

struct Chit_ChatTests {

    @MainActor
    @Test func localLoginCreatesSession() async throws {
        let appState = AppState(backend: LocalBackendService())
        let username = "test_\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8))"
        let password = "Password123"

        let signUpError = appState.signUp(username: username, password: password)
        #expect(signUpError == nil)
        #expect(appState.session?.isAuthenticated == true)
        #expect(appState.session?.username.lowercased() == username.lowercased())
    }

    @MainActor
    @Test func repostIsIdempotentPerUser() async throws {
        let appState = AppState(backend: LocalBackendService())
        let uniqueUser = "repost_\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8))"
        _ = appState.signUp(username: uniqueUser, password: "Password123")
        let postID = try #require(appState.posts.first?.id)
        let initialSource = try #require(appState.posts.first(where: { $0.id == postID }))
        let initialRepostCount = initialSource.repostCount
        let initialRepostUsers = appState.usersForReposts(postID: postID).count

        appState.repostPost(postID)
        appState.repostPost(postID)

        let source = try #require(appState.posts.first(where: { $0.id == postID }))
        #expect(source.repostCount == initialRepostCount + 1)
        #expect(appState.usersForReposts(postID: postID).count == initialRepostUsers + 1)
    }

    @MainActor
    @Test func saveTogglesSaveCountAndCollection() async throws {
        let appState = AppState(backend: LocalBackendService())
        let postID = try #require(appState.posts.first?.id)

        appState.toggleSavedPost(postID)
        var updated = try #require(appState.posts.first(where: { $0.id == postID }))
        #expect(appState.savedPostIDs.contains(postID))
        #expect(updated.saveCount >= 1)

        appState.toggleSavedPost(postID)
        updated = try #require(appState.posts.first(where: { $0.id == postID }))
        #expect(!appState.savedPostIDs.contains(postID))
        #expect(updated.saveCount >= 0)
    }

    @MainActor
    @Test func profilePhotoIsScopedByAccount() async throws {
        let appState = AppState(backend: LocalBackendService())

        _ = appState.signUp(username: "alice_user", password: "Password123")
        appState.setProfilePhoto(data: Data([0x1, 0x2, 0x3]))

        _ = appState.signUp(username: "bob_user", password: "Password123")
        appState.setProfilePhoto(data: Data([0xA, 0xB, 0xC]))

        _ = appState.switchToAccount(username: "alice_user")
        #expect(appState.profilePhoto(for: "@alice_user") == Data([0x1, 0x2, 0x3]))
        #expect(appState.profilePhoto(for: "@bob_user") == Data([0xA, 0xB, 0xC]))
    }

    @Test func backendSyncAwaitsWrite() async throws {
        let backend = LocalBackendService()
        let profile = UserProfile(
            id: UUID(),
            username: "sync_user",
            handle: "@sync_user",
            enterpriseAlias: "Sync User",
            displayName: "Sync User",
            followers: 10,
            verificationStatus: .unverified,
            allowEnterpriseReveal: false,
            linkedPlatforms: []
        )

        try await backend.syncUserProfile(profile)
        let stored = UserDefaults.standard.string(forKey: "lastSyncedUsername")
        #expect(stored == "sync_user")
    }

}
