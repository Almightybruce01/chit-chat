import Foundation
import SwiftUI
import AVFoundation
import UIKit
import CryptoKit
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

enum PasswordResetRequestResponse: Sendable {
    /// `Auth.sendPasswordReset` — user completes reset via the emailed link (no code entry in-app).
    case firebaseEmailLinkSent
    /// On-device credential flow plus backend email containing a six-digit code.
    case localSixDigitCodeSent
    case failure(String)
}

@MainActor
final class AppState: ObservableObject {
    private let backend: BackendServicing
    private let credentialsStorageKey = "chitchat.local.credentials"
    private let passwordResetPendingPrefix = "chitchat.pwdreset.pending."
    private let passwordResetUserRatePrefix = "chitchat.pwdreset.ratelimit.user."
    private let passwordResetGlobalRateKey = "chitchat.pwdreset.ratelimit.global"
    private let passwordResetLockPrefix = "chitchat.pwdreset.lockout."
    private let loggedInAccountsKey = "chitchat.logged.accounts"
    private let recentSearchesStorageKey = "chitchat.recent.searches"
    private let savedPostsStoragePrefix = "chitchat.saved.posts."
    private let sessionStorageKey = "chitchat.session.v1"

    /// Used when Firebase signs out so `AppState+FirebaseAuth` clears the same key as `restoreSession`.
    static let sessionUserDefaultsKey = "chitchat.session.v1"
    private let engagementStoragePrefix = "chitchat.engagement."
    private let profilePhotoStoragePrefix = "chitchat.profile.photo."
    private let profileGifStoragePrefix = "chitchat.profile.gif."
    private let profileLoopVideoStoragePrefix = "chitchat.profile.loop.video."
    private let profileStoryImageStoragePrefix = "chitchat.profile.story.image."
    private let profileStoryVideoStoragePrefix = "chitchat.profile.story.video."
    private let profileStoryGifStoragePrefix = "chitchat.profile.story.gif."
    private let profileQuoteStoragePrefix = "chitchat.profile.quote."
    private let profileQuoteVisibilityStoragePrefix = "chitchat.profile.quote.visibility."
    private let superFeatureSelectionStoragePrefix = "chitchat.super.features."
    private let executionQueueProgressStoragePrefix = "chitchat.execution.queue.progress."
    private let executionQueueSnapshotStoragePrefix = "chitchat.execution.queue.snapshots."
    private let executionQueueLockStoragePrefix = "chitchat.execution.queue.lock."
    private let executionQueueLastSnapshotDayStoragePrefix = "chitchat.execution.queue.last.snapshot.day."
    private let executionQueueRestorePointStoragePrefix = "chitchat.execution.queue.restorepoint."
    private let storySeenStoragePrefix = "chitchat.story.seen."
    private let profileModeStateStoragePrefix = "chitchat.profile.mode.state."
    private let localCityStorageKey = "chitchat.local.city.v1"
    private let interestStateStoragePrefix = "chitchat.interests."
    private let reelCollectionStoragePrefix = "chitchat.reel.collections."
    private let exploreSignalStoragePrefix = "chitchat.explore.signals."
    private let verificationRequestStorageKey = "chitchat.verification.requests.v1"
    private let combinedPostRequestStorageKey = "chitchat.combined.post.requests.v1"
    private let scheduledPostsStoragePrefix = "chitchat.scheduled.posts."
    private let analyticsSnapshotsStoragePrefix = "chitchat.analytics.snapshots."
    private var audioPlayer: AVAudioPlayer?

    @Published var mode: PlatformMode = .social
    /// When set, MainTabView switches to this tab index and clears. Used for Reels exit escape hatch.
    @Published var requestedTabIndex: Int?
    @Published var session: AppSession?
    /// Set when Firebase Auth has a user; drives main UI gate with `ContentView`.
    @Published var firebaseSignedInUID: String?
    /// False while Firebase profile hydration / post-login reload is in flight — keeps Profile from racing unstable state.
    @Published private(set) var isSessionBootstrapComplete = true
    /// From Firestore `admin_users/{uid}` (self-read); set after sign-in.
    @Published var isInternalAdminCache = false

    @Published var currentUser = AppState.makeGuestUserProfile()

    @Published var posts: [PostItem] = [
        PostItem(
            id: UUID(),
            authorHandle: "@chitchatsocial",
            caption: "Welcome to the ultimate social media app.\n\n#ad",
            type: .post,
            createdAt: Date(),
            city: "",
            isCollab: false,
            isSponsoredAd: true,
            sponsorBrandHandle: "@chitchatsocial",
            sponsorExternalURL: "https://chitchat.app"
        ),
        PostItem(
            id: UUID(),
            authorHandle: "@djmike",
            caption: "Going live tonight. Song queue is open.",
            type: .reel,
            createdAt: Date().addingTimeInterval(-1800),
            city: "",
            isCollab: true
        )
    ]

    @Published var stories: [StoryItem] = [
        StoryItem(id: UUID(), authorHandle: "@cocacola", title: "Brand challenge", createdAt: Date()),
        StoryItem(id: UUID(), authorHandle: "@nike", title: "Training day", createdAt: Date().addingTimeInterval(-3600))
    ]

    @Published var chats: [ChatThread] = [
        ChatThread(
            id: UUID(),
            title: "Creators Group",
            messages: [
                MessageItem(id: UUID(), senderHandle: "@brian", text: "Let us schedule a collab post.", sentAt: Date().addingTimeInterval(-1200)),
                MessageItem(id: UUID(), senderHandle: "@djmike", text: "I can host the DJ live room.", sentAt: Date().addingTimeInterval(-900))
            ]
        )
    ]
    @Published var dmRequests: [DMRequest] = [
        DMRequest(id: UUID(), fromHandle: "@friscoformda6", previewText: "Tap to connect and collab.", createdAt: Date().addingTimeInterval(-3600)),
        DMRequest(id: UUID(), fromHandle: "@outlierdotbet", previewText: "Want a paid promo slot this week.", createdAt: Date().addingTimeInterval(-8200))
    ]
    @Published var pinnedThreadIDs: Set<UUID> = []
    @Published var seenThreadIDs: Set<UUID> = []
    @Published var typingByThreadID: [UUID: String] = [:]
    @Published var mediaFirstThreadIDs: Set<UUID> = []
    @Published var hasSocialProfile = true
    @Published var hasCorporateProfile = true
    @Published var socialProfileVisible = true
    @Published var corporateProfileVisible = true
    @Published var socialInterests: Set<String> = ["creators", "fashion", "music", "reels", "local"]
    @Published var corporateInterests: Set<String> = ["networking", "hiring", "resume", "analytics", "jobs"]
    @Published var reelCollections: [String: Set<UUID>] = [:]
    @Published var exploreBoostByPostID: [String: Int] = [:]
    @Published var inboxNotes: [InboxNote] = [
        InboxNote(id: UUID(), authorHandle: "@creatorone", text: "Drop time moved to 8pm", createdAt: Date().addingTimeInterval(-1500)),
        InboxNote(id: UUID(), authorHandle: "@coachmia", text: "Film session tomorrow?", createdAt: Date().addingTimeInterval(-2500))
    ]
    @Published var broadcastChannels: [BroadcastChannel] = [
        BroadcastChannel(id: UUID(), title: "Chit Chat Social Updates", ownerHandle: "@chitchatsocial", memberCount: 12024, latestMessage: "Live shopping upgrades shipped."),
        BroadcastChannel(id: UUID(), title: "Creator Strategy Room", ownerHandle: "@creatorone", memberCount: 3412, latestMessage: "Best posting windows this week.")
    ]

    @Published var callRooms: [CallRoom] = [
        CallRoom(id: UUID(), roomName: "1-on-1 Quick Room", mode: .oneOnOne, participants: ["@brian", "@friend"], isScreenSharingEnabled: false),
        CallRoom(id: UUID(), roomName: "Live DJ Arena", mode: .groupDJ, participants: ["@brian", "@djmike", "@reelqueen"], isScreenSharingEnabled: true),
        CallRoom(id: UUID(), roomName: "Exec Briefing", mode: .executive, participants: ["@brian", "@manager"], isScreenSharingEnabled: true)
    ]
    @Published var corporateMeetingRooms: [CorporateMeetingRoom] = [
        CorporateMeetingRoom(
            id: UUID(),
            title: "Main Briefing Room",
            participantHandles: ["@brian", "@manager", "@opslead"],
            activeAgenda: "Weekly planning and blockers."
        ),
        CorporateMeetingRoom(
            id: UUID(),
            title: "Hiring Panel Room",
            participantHandles: ["@brian", "@hiringdesk"],
            activeAgenda: "Candidate shortlist review."
        )
    ]
    @Published var corporateRolesByHandle: [String: CorporateCallRole] = [
        "@brian": .host,
        "@manager": .presenter
    ]
    @Published var socialMusicSyncEnabled = true
    @Published var socialFaceEmojiMask = "😎"
    /// Active live broadcasts keyed by normalized host @handle.
    @Published private(set) var liveSessionsByHost: [String: LiveBroadcastSession] = [:]
    /// Full-screen countdown before `startLiveSession` (5 … 1). Nil when idle.
    @Published private(set) var liveGoLiveCountdown: Int?
    /// Presented live room (viewer or host). Nil when closed.
    @Published var liveSheetHost: String?
    /// Host handle normalized — current account is watching this live (audience).
    @Published private(set) var liveAudienceHost: String?
    @Published var liveCoHosts: [String] = ["@creatorone"]
    @Published var audienceRoleByHandle: [String: SocialLiveAudienceRole] = [:]
    private var liveCountdownTask: Task<Void, Never>?

    /// True when this account has an active live broadcast.
    var isLiveNow: Bool {
        liveSessionsByHost[normalizedSocialHandle(currentUser.handle)] != nil
    }

    @Published var songQueue: [SongQueueItem] = [
        SongQueueItem(id: UUID(), title: "Midnight Drive", artist: "Nova Lane", requestedBy: "@reelqueen"),
        SongQueueItem(id: UUID(), title: "Fast Lane", artist: "ARQ", requestedBy: "@brian")
    ]

    @Published var moderationEvents: [String] = []
    /// Policy strikes for sexual/nudity violations (persisted per username).
    @Published var moderationStrikeCount: Int = 0
    /// Automatic suspension end date after policy strikes.
    @Published var accountPolicyBanUntil: Date?
    /// Posts where the user chose to view violent / sensitive content.
    @Published var revealedViolencePostIDs: Set<UUID> = []
    /// User tapped “Not now” on the violence overlay — compact placeholder until they choose to view.
    @Published var skippedViolencePostIDs: Set<UUID> = []
    /// Transient in-app banner after policy actions (dismisses automatically).
    @Published var moderationBannerMessage: String?
    /// Used for moderation email stubs (production: from verified account email).
    @Published var accountRecoveryEmail: String = ""
    @Published var verificationInbox: [String] = []
    @Published var verificationRequests: [VerificationRequest] = []
    @Published var combinedPostRequests: [CombinedPostRequest] = []
    @Published var wantsProductUpdateEmails = true
    @Published var emailVerificationSent = false
    @Published var internalUsers: [UserProfile] = []
    @Published var communities: [CommunityGroup] = [
        CommunityGroup(
            id: UUID(),
            name: "Creator Growth Lab",
            summary: "Growth strategies, collabs, and creator coaching.",
            creator: "@chitchat",
            managers: ["@opslead"],
            isPublic: true,
            requiresPassword: false
        ),
        CommunityGroup(
            id: UUID(),
            name: "Dallas Business Circle",
            summary: "Local contracts, hires, and vendor opportunities.",
            creator: "@dallasbiz",
            managers: ["@bizmanager", "@eventsdesk"],
            isPublic: false,
            requiresPassword: true
        )
    ]
    @Published var shopProducts: [ShopProduct] = [
        ShopProduct(
            id: UUID(),
            sellerHandle: "@streetvault",
            title: "Urban Runner Sneakers",
            description: "Limited colorway, fast ship option.",
            priceUSD: 129,
            imageSystemName: "shoe.2.fill",
            isDropshipEnabled: true
        ),
        ShopProduct(
            id: UUID(),
            sellerHandle: "@creatorhub",
            title: "Podcast Starter Kit",
            description: "Mic, arm, pop filter bundle.",
            priceUSD: 219,
            imageSystemName: "mic.fill",
            isDropshipEnabled: false
        )
    ]
    @Published var liveShopSessions: [LiveShopSession] = []
    @Published var publicPulse: [PublicPulsePost] = [
        PublicPulsePost(
            id: UUID(),
            authorHandle: "@chitchat",
            text: "Welcome to Pulse. Drop public updates and photos instantly.",
            imageSystemName: "bolt.horizontal.circle.fill",
            createdAt: Date()
        )
    ]
    @Published var musicLibrary: [MusicTrack] = [
        MusicTrack(id: UUID(), title: "Midnight Drive", artist: "Nova Lane", source: .appleMusic, bundledFileName: "music_midnight_drive"),
        MusicTrack(id: UUID(), title: "Fast Lane", artist: "ARQ", source: .spotify, bundledFileName: "music_fast_lane"),
        MusicTrack(id: UUID(), title: "City Lights", artist: "Kairo", source: .youtube, bundledFileName: "music_city_lights")
    ]
    @Published var nowPlayingTrack: MusicTrack?
    @Published var isMusicPlaying = false
    @Published var musicStatusMessage = "Select a track to listen."
    @Published var hideLikeCountsByDefault = false
    @Published var hideCommentCountsByDefault = false
    @Published var profilePhotoData: Data?
    @Published var profileGIFData: Data?
    @Published var profileLoopVideoData: Data?
    @Published var profileStoryImageData: Data?
    @Published var profileStoryVideoData: Data?
    @Published var profileStoryGIFData: Data?
    @Published private var profilePhotoByUsername: [String: Data] = [:]
    @Published private var profileGIFByUsername: [String: Data] = [:]
    @Published private var profileLoopVideoByUsername: [String: Data] = [:]
    @Published private var profileStoryImageByUsername: [String: Data] = [:]
    @Published private var profileStoryVideoByUsername: [String: Data] = [:]
    @Published private var profileStoryGIFByUsername: [String: Data] = [:]
    @Published var localCity = ""
    @Published var followingHandles: Set<String> = ["@chitchat", "@djmike", "@creatorone"]
    @Published var followerHandles: Set<String> = ["@fan_aria", "@fan_ray", "@coachmia"]
    @Published var enterpriseFollowingHandles: Set<String> = ["@techlane", "@citynova", "@travelrue"]
    @Published var enterpriseFollowerHandles: Set<String> = ["@hiringdesk", "@brandops", "@venturescout"]
    @Published var matchedContactHandles: Set<String> = []
    @Published var contactsSyncStatus = "Contacts not synced yet."
    @Published var loggedInAccountUsernames: [String] = []
    @Published var recentSearches: [String] = []
    @Published var mutedThreadIDs: Set<UUID> = []
    @Published var blockedHandles: Set<String> = []
    /// User-submitted reports (stored locally for trust & safety workflow).
    @Published private(set) var userContentReports: [UserContentReport] = []
    private let userContentReportsStorageKey = "chitchat.user.content.reports.v1"
    @Published var hiddenTaggedPostIDs: Set<UUID> = []
    @Published var savedPostIDs: Set<UUID> = []
    @Published var seenStoryHandles: Set<String> = []
    @Published var commentsByPost: [UUID: [PostComment]] = [:]
    @Published var likesByPost: [UUID: [PostEngagementUser]] = [:]
    @Published var repostsByPost: [UUID: [PostEngagementUser]] = [:]
    @Published var reactionByPost: [UUID: String] = [:]
    @Published private(set) var canUndoPostDeletion = false
    @Published private(set) var canUndoMessageDeletion = false
    @Published private(set) var lastDeletedMessagePreview = ""
    @Published private(set) var undoQueueCount = 0
    @Published private(set) var latestUndoLabel = ""
    @Published var pinnedPostIDs: Set<UUID> = []
    @Published var closeFriendsHandles: Set<String> = []
    @Published var activityFeed: [ActivityItem] = []
    @Published var notificationsEnabled = true
    @Published var emailAlertsEnabled = true
    @Published var mutedActivityTypes: Set<ActivityType> = []
    @Published var quietHoursEnabled = false
    @Published var quietHoursStart = 22
    @Published var quietHoursEnd = 7
    @Published var defaultPostAudience: PostAudience = .public
    @Published var defaultStoryAudience: StoryAudience = .public
    @Published var rankingLikeWeight: Double = 4.0
    @Published var rankingCommentWeight: Double = 5.0
    @Published var rankingRepostWeight: Double = 6.0
    @Published var rankingSaveWeight: Double = 3.0
    @Published var rankingFreshnessPower: Double = 0.58
    @Published var creatorMonetizationEnabled = false
    @Published var creatorBoostBudgetUSD: Double = 0
    @Published var creatorAffiliateLink = ""
    @Published var scheduledPosts: [ScheduledPostPlan] = []
    @Published var analyticsSnapshots: [AnalyticsSnapshot] = []
    private var socialGraph: [String: Set<String>] = [
        "@chitchat": ["@creatorone", "@coachmia", "@djmike", "@streetvault", "@guest"],
        "@creatorone": ["@chitchat", "@djmike", "@coachmia", "@guest"],
        "@coachmia": ["@chitchat", "@creatorone", "@dallasbiz", "@guest"],
        "@djmike": ["@chitchat", "@creatorone", "@streetvault", "@guest"]
    ]

    var canAccessInternalDashboard: Bool {
        isInternalAdminCache
    }

    /// Remote kill switch + disclosure for in-app **branded / partner** promos (Instagram-style), not third‑party ad networks.
    @Published var nativeSponsoredFeedEnabled = false
    @Published var sponsorDisclosureRemoteLabel = "Sponsored"

    /// In-feed sponsored posts and paid reshares (subject to `nativeSponsoredFeedEnabled` from ops).
    var canRunPaidAds: Bool {
        nativeSponsoredFeedEnabled && (currentUser.isAdAccount || currentUser.isBusinessAccount)
    }

    /// `true` when email is missing or still an Apple/Google placeholder — prompt user to update in Profile.
    /// Phone is optional for core app use (Guideline 5.1.1).
    var needsContactInfoUpdate: Bool {
        let em = currentUser.accountEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let badEmail = em.isEmpty || Self.isPlaceholderAccountEmail(em)
        return badEmail
    }

    private static let pendingEmailHost = "pending.chitchat"
    private static let placeholderAccountPhoneDigits = "0000000000"

    private static func placeholderAccountEmail(forUsername username: String) -> String {
        "\(username.lowercased())@\(pendingEmailHost)"
    }

    private static func isPlaceholderAccountEmail(_ raw: String) -> Bool {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().hasSuffix("@\(pendingEmailHost)")
    }

    private static func isOAuthProvider(_ provider: String) -> Bool {
        provider == "apple.com" || provider == "google.com"
    }

    /// Validates signup / profile email (not for Firebase delivery).
    func validateAccountEmail(_ raw: String) -> String? {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return "Email is required." }
        guard t.contains("@") else { return "Enter a valid email address." }
        let parts = t.split(separator: "@")
        guard parts.count == 2, !parts[0].isEmpty, parts[1].contains(".") else { return "Enter a valid email address." }
        return nil
    }

    /// Validates phone — digits only stored; at least 10 digits; rejects the OAuth placeholder.
    func validateAccountPhone(_ raw: String) -> String? {
        let digits = raw.filter(\.isNumber)
        guard digits.count >= 10 else { return "Phone number must include at least 10 digits." }
        guard digits != Self.placeholderAccountPhoneDigits else { return "Enter a real phone number (not placeholder digits)." }
        return nil
    }

    /// Update contact info from Profile (real email + optional phone replace Apple/placeholder values).
    @discardableResult
    func updateAccountContactInfo(email: String, phone: String) -> String? {
        if let err = validateAccountEmail(email) { return err }
        let digits = phone.filter(\.isNumber)
        if !digits.isEmpty {
            if digits.count < 10 { return "Phone number must include at least 10 digits." }
            if digits == Self.placeholderAccountPhoneDigits { return "Enter a real phone number (not placeholder digits)." }
            currentUser.accountPhone = digits
        } else {
            currentUser.accountPhone = Self.placeholderAccountPhoneDigits
        }
        currentUser.accountEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        syncCurrentUserInDirectory()
        Task {
            try? await backend.syncUserProfile(currentUser)
        }
        return nil
    }

    private struct PendingPasswordReset: Codable {
        var usernameKey: String
        var emailLowercased: String
        var salt: String
        var codeHashHex: String
        var expiresAt: Date
        var failedAttempts: Int
    }

    private struct RateWindow: Codable {
        var count: Int
        var windowStart: Date
    }

    private static func sha256Hex(_ utf8: String) -> String {
        let digest = SHA256.hash(data: Data(utf8.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func passwordResetCodeHash(code: String, salt: String, usernameKey: String) -> String {
        sha256Hex("\(code)|\(salt)|\(usernameKey)")
    }

    private func passwordResetLockUntil(usernameKey: String) -> Date? {
        guard let t = UserDefaults.standard.object(forKey: passwordResetLockPrefix + usernameKey) as? TimeInterval else { return nil }
        let d = Date(timeIntervalSince1970: t)
        return d > Date() ? d : nil
    }

    private func setPasswordResetLock(usernameKey: String, minutes: Int) {
        let until = Date().addingTimeInterval(Double(minutes * 60))
        UserDefaults.standard.set(until.timeIntervalSince1970, forKey: passwordResetLockPrefix + usernameKey)
    }

    private func clearPasswordResetLock(usernameKey: String) {
        UserDefaults.standard.removeObject(forKey: passwordResetLockPrefix + usernameKey)
    }

    private func consumeRateWindow(
        storageKey: String,
        limit: Int,
        windowSeconds: TimeInterval
    ) -> String? {
        let now = Date()
        var window = RateWindow(count: 0, windowStart: now)
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let w = try? JSONDecoder().decode(RateWindow.self, from: data) {
            window = w
        }
        if now.timeIntervalSince(window.windowStart) > windowSeconds {
            window = RateWindow(count: 0, windowStart: now)
        }
        if window.count >= limit {
            return "Too many attempts. Wait before trying again."
        }
        window.count += 1
        if let data = try? JSONEncoder().encode(window) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        return nil
    }

    private func pendingPasswordResetStorageKey(usernameKey: String) -> String {
        passwordResetPendingPrefix + usernameKey
    }

    private func clearPendingPasswordReset(usernameKey: String) {
        UserDefaults.standard.removeObject(forKey: pendingPasswordResetStorageKey(usernameKey: usernameKey))
    }

    /// Step 1: Firebase users get a reset link; otherwise validates account, rate limits, and emails a 6-digit code via `BackendServicing.sendPasswordResetCode`.
    func requestPasswordResetCode(username: String, email: String) async -> PasswordResetRequestResponse {
        if let err = consumeRateWindow(
            storageKey: passwordResetGlobalRateKey,
            limit: 20,
            windowSeconds: 3600
        ) { return .failure(err) }

#if canImport(FirebaseAuth)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedEmail.isEmpty, validateAccountEmail(trimmedEmail) == nil {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: trimmedEmail)
                return .firebaseEmailLinkSent
            } catch {
                return .failure(error.localizedDescription)
            }
        }
#endif

        guard let cleaned = normalizedUsername(from: username) else { return .failure("Invalid username.") }
        let key = cleaned.lowercased()

        if let lock = passwordResetLockUntil(usernameKey: key) {
            let f = RelativeDateTimeFormatter()
            f.unitsStyle = .short
            return .failure("Too many failed codes. Try again \(f.localizedString(for: lock, relativeTo: Date())).")
        }

        guard localCredentials[key] != nil else { return .failure("No password saved for that username on this device.") }
        guard let profile = internalUsers.first(where: { $0.username.lowercased() == key }) else { return .failure("Account not found on this device.") }
        let typed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let saved = profile.accountEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !saved.isEmpty else {
            return .failure("No email on file. Sign in and add your email under Profile, or create a new account.")
        }
        guard !Self.isPlaceholderAccountEmail(saved) else {
            return .failure("Add a real email under Profile before using password reset.")
        }
        guard typed == saved else {
            return .failure("That email doesn’t match the address on file for this username.")
        }

        if let err = consumeRateWindow(
            storageKey: passwordResetUserRatePrefix + key,
            limit: 5,
            windowSeconds: 3600
        ) { return .failure(err) }

        let code = String(format: "%06d", Int.random(in: 0...999_999))
        let salt = UUID().uuidString
        let hash = Self.passwordResetCodeHash(code: code, salt: salt, usernameKey: key)
        let payload = PendingPasswordReset(
            usernameKey: key,
            emailLowercased: saved,
            salt: salt,
            codeHashHex: hash,
            expiresAt: Date().addingTimeInterval(900),
            failedAttempts: 0
        )
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: pendingPasswordResetStorageKey(usernameKey: key))
        }

        do {
            try await backend.sendPasswordResetCode(
                toEmail: saved,
                username: cleaned,
                code: code,
                validMinutes: 15
            )
        } catch {
            clearPendingPasswordReset(usernameKey: key)
            return .failure("Could not send reset email. Try again later.")
        }
        return .localSixDigitCodeSent
    }

    /// Step 2: verify emailed code, then set a new password.
    func completePasswordResetWithCode(username: String, email: String, code: String, newPassword: String) -> String? {
        guard newPassword.count >= 8 else { return "New password must be at least 8 characters." }
        guard let cleaned = normalizedUsername(from: username) else { return "Invalid username." }
        let key = cleaned.lowercased()

        if let lock = passwordResetLockUntil(usernameKey: key) {
            let f = RelativeDateTimeFormatter()
            f.unitsStyle = .short
            return "Too many failed attempts. Try again \(f.localizedString(for: lock, relativeTo: Date()))."
        }

        guard let data = UserDefaults.standard.data(forKey: pendingPasswordResetStorageKey(usernameKey: key)),
              var pending = try? JSONDecoder().decode(PendingPasswordReset.self, from: data)
        else {
            return "No active reset for this username. Request a new code."
        }

        let typedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard typedEmail == pending.emailLowercased else {
            return "Email does not match this reset."
        }

        if Date() > pending.expiresAt {
            clearPendingPasswordReset(usernameKey: key)
            return "That code expired. Request a new one."
        }

        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedCode.count == 6, trimmedCode.allSatisfy(\.isNumber) else {
            return "Enter the 6-digit code from your email."
        }

        let candidate = Self.passwordResetCodeHash(code: trimmedCode, salt: pending.salt, usernameKey: key)
        guard candidate == pending.codeHashHex else {
            pending.failedAttempts += 1
            if pending.failedAttempts >= 5 {
                clearPendingPasswordReset(usernameKey: key)
                setPasswordResetLock(usernameKey: key, minutes: 30)
            } else if let reencode = try? JSONEncoder().encode(pending) {
                UserDefaults.standard.set(reencode, forKey: pendingPasswordResetStorageKey(usernameKey: key))
            }
            return "Invalid code."
        }

        localCredentials[key] = newPassword
        saveCredentials()
        clearPendingPasswordReset(usernameKey: key)
        clearPasswordResetLock(usernameKey: key)
        return nil
    }

    @Published var resume = ResumeProfile(
        headline: "Creator, producer, and community builder",
        skills: ["Content Strategy", "Live Production", "Brand Partnerships"],
        yearsExperience: 4
    )
    @Published var contracts: [ContractDeal] = [
        ContractDeal(id: UUID(), title: "Event DJ Host", budgetUSD: 1200, location: "Local", isLocalHire: true),
        ContractDeal(id: UUID(), title: "Brand Reel Campaign", budgetUSD: 4000, location: "Remote", isLocalHire: false)
    ]
    @Published var marketListings: [MarketListing] = [
        MarketListing(id: UUID(), title: "Studio Mic Bundle", priceUSD: 220, seller: "@creatorhub", category: "Audio"),
        MarketListing(id: UUID(), title: "Sneaker Drop - Size 10", priceUSD: 180, seller: "@streetvault", category: "Fashion")
    ]
    @Published var enabledSuperFeatureIDs: Set<String> = []
    @Published var completedExecutionQueueIDs: Set<String> = []
    @Published var executionCompletionSnapshots: [ExecutionCompletionSnapshot] = []
    @Published var executionQueueLockCompleted = false
    @Published var executionQueueRestorePoint: ExecutionQueueRestorePoint?
    private var localCredentials: [String: String] = [:]
    private var lastDeletedPostSnapshot: DeletedPostSnapshot?
    private var lastDeletedMessageSnapshot: DeletedMessageSnapshot?
    private var undoQueue: [UndoQueueEntry] = []

    private let moderationStrikeStorageKey = "chitchat.moderation.strikes"
    private let moderationBanUntilStorageKey = "chitchat.moderation.banUntil"
    private let revealedViolenceStorageKey = "chitchat.moderation.revealedViolence"
    private let skippedViolenceStorageKey = "chitchat.moderation.skippedViolence"
    private let recoveryEmailStorageKey = "chitchat.moderation.recoveryEmail"

    private struct DeletedPostSnapshot {
        let index: Int
        let post: PostItem
        let comments: [PostComment]
        let likes: [PostEngagementUser]
        let reposts: [PostEngagementUser]
        let reaction: String?
    }

    private struct DeletedMessageSnapshot {
        let threadID: UUID
        let index: Int
        let message: MessageItem
    }

    private struct UndoQueueEntry {
        enum Kind {
            case post(DeletedPostSnapshot)
            case message(DeletedMessageSnapshot)
        }
        let label: String
        let kind: Kind
    }

    init(backend: BackendServicing = LocalBackendService()) {
        self.backend = backend
        self.internalUsers = [
            UserProfile(
                id: UUID(),
                username: "creatorone",
                handle: "@creatorone",
                enterpriseAlias: "Creator One",
                displayName: "Creator One",
                followers: 12034,
                verificationStatus: .paid,
                allowEnterpriseReveal: true,
                linkedPlatforms: [.instagram, .youtube]
            ),
            UserProfile(
                id: UUID(),
                username: "coachmia",
                handle: "@coachmia",
                enterpriseAlias: "Mia C.",
                displayName: "Coach Mia",
                followers: 4680,
                verificationStatus: .unverified,
                allowEnterpriseReveal: false,
                linkedPlatforms: [.x, .linkedin]
            )
        ]
        verificationRequests = [
            VerificationRequest(
                id: UUID(),
                username: "creatorone",
                handle: "@creatorone",
                note: "IG verified creator requesting official badge sync.",
                hasInstagramVerification: true,
                requestedAt: Date().addingTimeInterval(-7200),
                status: .pending,
                reviewerNote: "",
                category: .creator
            )
        ]
        seedEliteDemoNetwork()
        loadCredentials()
        loadVerificationRequests()
        loadLoggedInAccounts()
        purgeLegacySeededAccountArtifacts()
        loadProfilePhotoMap()
        loadRecentSearches()
        loadProfileModeState()
        loadInterestState()
        loadReelCollections()
        loadExploreSignals()
        loadCombinedPostRequests()
        loadSavedPosts()
        loadProfileQuoteState()
        loadSeenStoryHandles()
        restoreSession()
        restoreEngagementState()
        loadScheduledPosts()
        loadAnalyticsSnapshots()
        loadSuperFeatureSelection()
        loadExecutionQueueProgress()
        loadExecutionQueueSnapshots()
        loadExecutionQueueSettings()
        loadExecutionQueueRestorePoint()
        loadModerationPolicyState()
        Task { @MainActor in
            if self.completedExecutionQueueIDs.count < 1000 {
                self.markAllExecutionItemsComplete()
            }
            self.captureExecutionCompletionSnapshotIfNeededDaily()
            self.ensurePostMediaCoverage()
        }
        if enabledSuperFeatureIDs.isEmpty {
            enableAllSuperFeatures()
        }
        loadLocalCityFromDefaults()
#if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        installFirebaseAuthBridge()
#endif
    }

    /// Offline / unit-test sign-up using device-local credentials only (not Firebase).
    func signUpLocalForTesting(
        username: String,
        password: String,
        accountEmail: String,
        accountPhone: String,
        personalDisplayName: String? = nil,
        business: BusinessRegistration? = nil
    ) -> String? {
        guard let cleaned = normalizedUsername(from: username) else {
            return "Username must be 3+ characters and only letters, numbers, . or _"
        }
        guard !ReservedHandles.isReserved(cleaned) else {
            return "This username is reserved."
        }
        guard password.count >= 8 else {
            return "Password must be at least 8 characters."
        }
        let trimmedEmail = accountEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if let err = validateAccountEmail(trimmedEmail) { return err }
        if business == nil {
            let p = accountPhone.filter(\.isNumber)
            if !p.isEmpty, p.count < 10 { return "Phone number must include at least 10 digits if provided." }
            if !p.isEmpty, p == Self.placeholderAccountPhoneDigits { return "Enter a real phone number (not placeholder digits)." }
        }
        let key = cleaned.lowercased()
        if localCredentials[key] != nil {
            return "Username already exists."
        }
        if internalUsers.contains(where: { $0.username.lowercased() == key }) {
            return "Username already exists."
        }
        if let registration = business {
            if let err = validateBusinessRegistration(registration) { return err }
        }
        localCredentials[key] = password
        saveCredentials()
        currentUser.username = cleaned
        currentUser.handle = "@\(cleaned)"
        currentUser.accountEmail = trimmedEmail
        currentUser.verificationStatus = .unverified
        clearBusinessRegistrationOnCurrentUser()
        if let registration = business {
            applyBusinessRegistration(registration)
            currentUser.accountPhone = registration.phone.filter(\.isNumber)
            guard currentUser.accountPhone.count >= 10 else {
                return "Enter a valid business phone (10+ digits)."
            }
            guard currentUser.accountPhone != Self.placeholderAccountPhoneDigits else {
                return "Enter a real business phone number."
            }
        } else {
            let rawName = personalDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if rawName.isEmpty {
                currentUser.displayName = cleaned
                currentUser.enterpriseAlias = cleaned
            } else {
                currentUser.displayName = rawName
                currentUser.enterpriseAlias = rawName
            }
            let phoneDigits = accountPhone.filter(\.isNumber)
            currentUser.accountPhone = phoneDigits.isEmpty ? Self.placeholderAccountPhoneDigits : phoneDigits
        }
        registerLoggedInAccount(cleaned)
        syncCurrentUserInDirectory()
        runPostLoginAccountDataReload()
        beginSession(provider: "local_test")
        firebaseSignedInUID = "local_\(key)"
        return nil
    }

    func logInLocalForTesting(username: String, password: String) -> String? {
        guard let cleaned = normalizedUsername(from: username) else {
            return "Invalid username."
        }
        let key = cleaned.lowercased()
        guard localCredentials[key] == password else {
            return "Incorrect username or password."
        }
        if let existing = internalUsers.first(where: { $0.username.lowercased() == key }) {
            currentUser = existing
        } else {
            currentUser.username = cleaned
            currentUser.handle = "@\(cleaned)"
        }
        registerLoggedInAccount(cleaned)
        syncCurrentUserInDirectory()
        runPostLoginAccountDataReload()
        beginSession(provider: "local_test")
        firebaseSignedInUID = "local_\(key)"
        return nil
    }

    func runPostLoginAccountDataReload() {
        refreshCurrentProfileMedia()
        loadSavedPosts()
        loadProfileQuoteState()
        loadProfileModeState()
        loadInterestState()
        loadReelCollections()
        loadExploreSignals()
        loadSeenStoryHandles()
        restoreEngagementState()
        loadScheduledPosts()
        loadAnalyticsSnapshots()
        loadExecutionQueueProgress()
        loadExecutionQueueSnapshots()
        loadExecutionQueueSettings()
        loadExecutionQueueRestorePoint()
        captureExecutionCompletionSnapshotIfNeededDaily()
    }

    private static func makeGuestUserProfile() -> UserProfile {
        let guestID = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
        return UserProfile(
            id: guestID,
            username: "guest",
            handle: "@guest",
            accountEmail: "",
            accountPhone: "",
            enterpriseAlias: "Guest",
            displayName: "Guest",
            followers: 0,
            verificationStatus: .unverified,
            allowEnterpriseReveal: false,
            linkedPlatforms: []
        )
    }

    private func seedEliteDemoNetwork() {
        struct DemoUser {
            let username: String
            let displayName: String
            let alias: String
            let platforms: [SocialPlatform]
        }

        let demoUsers: [DemoUser] = [
            .init(username: "creatorone", displayName: "Creator One", alias: "Creator One", platforms: [.instagram, .youtube]),
            .init(username: "coachmia", displayName: "Coach Mia", alias: "Mia C.", platforms: [.x, .linkedin]),
            .init(username: "djmike", displayName: "DJ Mike", alias: "Mike Mix", platforms: [.youtube, .threads]),
            .init(username: "reelqueen", displayName: "Reel Queen", alias: "Ari Q.", platforms: [.instagram, .youtube]),
            .init(username: "citynova", displayName: "City Nova", alias: "Nova Labs", platforms: [.x, .instagram]),
            .init(username: "streetvault", displayName: "Street Vault", alias: "Vault Supply", platforms: [.instagram, .youtube]),
            .init(username: "foodpulse", displayName: "Food Pulse", alias: "Pulse Kitchen", platforms: [.instagram, .facebook]),
            .init(username: "fitedge", displayName: "Fit Edge", alias: "Fit Edge Co.", platforms: [.instagram, .youtube]),
            .init(username: "techlane", displayName: "Tech Lane", alias: "Lane Systems", platforms: [.x, .linkedin]),
            .init(username: "travelrue", displayName: "Travel Rue", alias: "Rue Collective", platforms: [.instagram, .youtube])
        ]

        let generatedUsers: [UserProfile] = demoUsers.enumerated().map { index, item in
            UserProfile(
                id: UUID(),
                username: item.username,
                handle: "@\(item.username)",
                enterpriseAlias: item.alias,
                displayName: item.displayName,
                followers: 2200 + (index * 740),
                verificationStatus: index % 4 == 0 ? .paid : .unverified,
                allowEnterpriseReveal: index % 2 == 0,
                linkedPlatforms: item.platforms
            )
        }

        let existingByUsername = Dictionary(
            uniqueKeysWithValues: internalUsers.map { ($0.username.lowercased(), $0) }
        )
        let mergedGenerated = generatedUsers.map { user in
            existingByUsername[user.username.lowercased()] ?? user
        }
        internalUsers = [currentUser] + mergedGenerated

        let mutualHandles = Set(mergedGenerated.map(\.handle))
        followingHandles = mutualHandles
        followerHandles = mutualHandles
        enterpriseFollowingHandles = Set(Array(mutualHandles).sorted().prefix(6))
        enterpriseFollowerHandles = Set(Array(mutualHandles).sorted().suffix(6))
        closeFriendsHandles = Set(Array(mutualHandles).sorted().prefix(4))
        socialGraph[currentUser.handle] = mutualHandles

        let types: [ContentType] = [.post, .reel, .shortVideo, .story]
        let imageCache: [String: Data?] = Dictionary(
            uniqueKeysWithValues: mergedGenerated.map { user in
                (user.handle, demoPostImageData(handle: user.handle))
            }
        )
        var seededPosts: [PostItem] = []
        var seededComments: [UUID: [PostComment]] = [:]
        for (userIndex, user) in mergedGenerated.enumerated() {
            for postIndex in 1...5 {
                let type = types[(postIndex + userIndex) % types.count]
                let createdAt = Date().addingTimeInterval(TimeInterval(-((userIndex * 10 + postIndex) * 4200)))
                let audience: PostAudience = postIndex % 6 == 0 ? .followers : .public
                let storyAudience: StoryAudience = postIndex % 5 == 0 ? .closeFriends : .public
                let imageData = imageCache[user.handle] ?? nil
                let surfaceStyle: PostSurfaceStyle = type == .post && postIndex % 3 == 0 ? .chat : .chit
                let postID = UUID()
                let seededCommentCount = Int.random(in: 0...5)
                let generatedComments = makeSeedComments(
                    postID: postID,
                    count: seededCommentCount,
                    authorHandle: user.handle
                )
                seededPosts.append(
                    PostItem(
                        id: postID,
                        authorHandle: user.handle,
                        caption: demoCaption(
                            for: type,
                            authorHandle: user.handle,
                            index: postIndex + userIndex
                        ),
                        type: type,
                        createdAt: createdAt,
                        city: "",
                        imageData: imageData,
                        likeCount: Int.random(in: 4...380),
                        commentCount: generatedComments.count,
                        areLikesHidden: false,
                        areCommentsHidden: false,
                        isArchived: false,
                        repostCount: Int.random(in: 0...35),
                        saveCount: Int.random(in: 0...52),
                        storyAudience: storyAudience,
                        audience: audience,
                        isCollab: postIndex % 3 == 0,
                        surfaceStyle: surfaceStyle
                    )
                )
                if !generatedComments.isEmpty {
                    seededComments[postID] = generatedComments
                }
            }
        }

        posts = seededPosts.sorted { $0.createdAt > $1.createdAt }
        commentsByPost = seededComments
    }

    private func makeSeedComments(postID: UUID, count: Int, authorHandle: String) -> [PostComment] {
        guard count > 0 else { return [] }
        let commentPool = [
            "This is clean.",
            "Fire drop.",
            "Need this in my feed daily.",
            "Love this vibe.",
            "Elite content.",
            "This goes hard.",
            "Big energy."
        ]
        return (0..<count).map { index in
            let minutesAgo = Double((index + 1) * Int.random(in: 8...45))
            let commenter = Array(followerHandles).sorted()[index % max(1, followerHandles.count)]
            return PostComment(
                id: UUID(),
                postID: postID,
                authorHandle: commenter == currentUser.handle ? authorHandle : commenter,
                text: commentPool[index % commentPool.count],
                createdAt: Date().addingTimeInterval(-(minutesAgo * 60))
            )
        }
    }

    private func demoCaption(for type: ContentType, authorHandle: String, index: Int) -> String {
        let animalCaptions = [
            "Golden retriever morning zoomies in soft sunlight.",
            "Arctic fox close-up with cinematic color grade.",
            "Slow-motion hawk glide over the canyon rim.",
            "Panda snack break with ambient forest audio.",
            "Rainy-day cat portraits shot on mobile."
        ]
        let characterCaptions = [
            "Cyber ranger character reveal with neon key-light.",
            "Fantasy knight turnaround test and cloak simulation.",
            "Retro pixel hero concept animated into a short loop.",
            "Comic-style villain entrance scene with dramatic shadows.",
            "Sci-fi pilot character moodboard to final frame."
        ]
        let socialCaptions = [
            "Shot this in one take. Thoughts?",
            "Quick behind-the-scenes from today's set.",
            "Testing a new storytelling style this week.",
            "Color grading experiment from the weekend.",
            "This one took way too many drafts but worth it."
        ]

        let animal = animalCaptions[index % animalCaptions.count]
        let character = characterCaptions[index % characterCaptions.count]
        let social = socialCaptions[index % socialCaptions.count]

        switch type {
        case .reel, .shortVideo:
            return "\(animal) / \(character)\n\(social) #animal #character #reels"
        case .story:
            return "\(animal) #story"
        default:
            return "\(social)\nFeatured: \(animal.lowercased())"
        }
    }

    func generatedMediaImageData(seed: String, isReel: Bool = false) -> Data? {
        demoPostImageData(handle: seed, size: isReel ? CGSize(width: 720, height: 1280) : CGSize(width: 1080, height: 1080))
    }

    private func ensurePostMediaCoverage() {
        for index in posts.indices {
            if posts[index].imageData == nil {
                let seed = "\(posts[index].authorHandle)-\(posts[index].id.uuidString.prefix(6))"
                let isReelType = posts[index].type == .reel || posts[index].type == .shortVideo || posts[index].type == .story
                posts[index].imageData = generatedMediaImageData(seed: seed, isReel: isReelType)
            }
        }
    }

    private func demoPostImageData(handle: String, size: CGSize = CGSize(width: 320, height: 320)) -> Data? {
        autoreleasepool {
            // Generate textured pseudo-photo media instead of plain placeholders.
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { context in
                let cg = context.cgContext
                let bounds = CGRect(origin: .zero, size: size)

                let hueSeed = CGFloat(abs(handle.hashValue % 255)) / 255.0
                let baseA = UIColor(hue: hueSeed, saturation: 0.52, brightness: 0.93, alpha: 1.0).cgColor
                let baseB = UIColor(hue: fmod(hueSeed + 0.22, 1.0), saturation: 0.66, brightness: 0.78, alpha: 1.0).cgColor
                let colors = [baseA, baseB] as CFArray
                let locations: [CGFloat] = [0, 1]

                if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
                    cg.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
                } else {
                    cg.setFillColor(UIColor.systemBlue.cgColor)
                    cg.fill(bounds)
                }

                for wave in 0..<14 {
                    let waveHue = fmod(hueSeed + (CGFloat(wave) * 0.04), 1.0)
                    cg.setFillColor(UIColor(hue: waveHue, saturation: 0.42, brightness: 0.98, alpha: 0.16).cgColor)
                    let width = size.width * CGFloat.random(in: 0.18...0.62)
                    let height = size.height * CGFloat.random(in: 0.12...0.34)
                    let originX = CGFloat.random(in: -40...(size.width - 30))
                    let originY = CGFloat.random(in: -40...(size.height - 20))
                    cg.fillEllipse(in: CGRect(x: originX, y: originY, width: width, height: height))
                }

                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .center
                let headline: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: max(18, size.width * 0.05), weight: .heavy),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.92),
                    .paragraphStyle: paragraph
                ]
                NSString(string: handle).draw(
                    in: CGRect(x: 14, y: size.height - 78, width: size.width - 28, height: 34),
                    withAttributes: headline
                )
            }

            return image.jpegData(compressionQuality: size.width > 700 ? 0.72 : 0.62)
        }
    }

    func publishPost(
        caption: String,
        type: ContentType,
        imageData: Data?,
        videoData: Data? = nil,
        storyAudience: StoryAudience,
        audience: PostAudience,
        isCollab: Bool,
        areLikesHidden: Bool,
        areCommentsHidden: Bool,
        blockNudity: Bool,
        surfaceStyle: PostSurfaceStyle = .chit,
        taggedHandles: [String] = [],
        combinedOwnerHandle: String? = nil,
        isSponsoredAd: Bool = false,
        sponsorBrandHandle: String = "",
        sponsorExternalURL: String = "",
        sponsoredSourcePostID: UUID? = nil
    ) -> ModerationResult {
        clearExpiredPolicyBanIfNeeded()
        if isPolicySuspendedNow {
            return ModerationResult(
                label: .accountSuspended,
                reason: policySuspensionUserMessage
            )
        }
        let sponsorBrandNorm = normalizedSponsorHandle(sponsorBrandHandle)
        if isSponsoredAd, !sponsorBrandNorm.isEmpty, !canRunPaidAds {
            return ModerationResult(
                label: .sponsoredNotEligible,
                reason:
                    "Sponsored posts need an ad-enabled account (Profile → Ad account or verified business) and branded promos enabled by your program. Set Launch Settings → Partner program flags URL to sync the switch."
            )
        }
        if type == .reel || type == .shortVideo {
            guard let videoData, !videoData.isEmpty else {
                return ModerationResult(
                    label: .missingRequiredMedia,
                    reason: "Reels and short videos need a video file. Pick one in the media step."
                )
            }
        }
        let moderationResult = ModerationService.evaluate(caption: caption, blockNudity: blockNudity)
        var newPost: PostItem?

        switch moderationResult.label {
        case .blockedNudity:
            handleBlockedNudityViolation(source: "post", textSnippet: caption)
            moderationEvents.insert(moderationResult.reason, at: 0)
            Task {
                try? await backend.logModerationEvent(moderationResult.reason)
            }
            return moderationResult
        case .manualReview:
            moderationEvents.insert(moderationResult.reason, at: 0)
            addActivity(
                type: .moderation,
                detail: "Post held for review: \(moderationResult.reason)"
            )
            Task {
                try? await backend.logModerationEvent(moderationResult.reason)
            }
            return moderationResult
        case .safe, .violenceNeedsConsent:
            let mediaResult = ModerationService.evaluateMedia(imageData: imageData, videoData: (type == .reel || type == .shortVideo || type == .story) ? videoData : nil)
            if mediaResult.label == .blockedNudity {
                handleBlockedNudityViolation(source: "post (media)", textSnippet: caption)
                moderationEvents.insert(mediaResult.reason, at: 0)
                Task { try? await backend.logModerationEvent(mediaResult.reason) }
                return mediaResult
            }
            let violenceWarning = moderationResult.label == .violenceNeedsConsent
            let isReelType = type == .reel || type == .shortVideo || type == .story
            let shouldGenerateFallbackMedia = imageData == nil && (isReelType || surfaceStyle == .chit)
            let finalImageData = shouldGenerateFallbackMedia
                ? generatedMediaImageData(
                    seed: "\(currentUser.handle)-\(UUID().uuidString.prefix(8))",
                    isReel: isReelType
                )
                : imageData
            let finalVideoData: Data? = (type == .reel || type == .shortVideo || type == .story) ? videoData : nil
            let brand = sponsorBrandNorm
            let disclosure = isSponsoredAd && !brand.isEmpty
            let sponsoredCaption = disclosure && !caption.localizedCaseInsensitiveContains("#ad")
                ? "\(caption)\n\n#ad"
                : caption
            let created = PostItem(
                id: UUID(),
                authorHandle: currentUser.handle,
                caption: sponsoredCaption,
                type: type,
                createdAt: Date(),
                city: localCity,
                imageData: finalImageData,
                videoData: finalVideoData,
                likeCount: 0,
                commentCount: 0,
                areLikesHidden: areLikesHidden,
                areCommentsHidden: areCommentsHidden,
                isArchived: false,
                repostCount: 0,
                saveCount: 0,
                storyAudience: storyAudience,
                audience: audience,
                isCollab: isCollab,
                surfaceStyle: surfaceStyle,
                taggedHandles: taggedHandles,
                combinedOwnerHandle: combinedOwnerHandle,
                violenceWarningRequired: violenceWarning,
                isSponsoredAd: isSponsoredAd && !brand.isEmpty,
                sponsorBrandHandle: brand,
                sponsorExternalURL: sponsorExternalURL.trimmingCharacters(in: .whitespacesAndNewlines),
                sponsoredSourcePostID: sponsoredSourcePostID
            )
            posts.insert(created, at: 0)
            newPost = created
            moderationEvents.insert(moderationResult.reason, at: 0)
            if violenceWarning {
                notifyPosterViolenceWarningPosted()
            }
        case .missingRequiredMedia, .accountSuspended, .sponsoredNotEligible:
            return moderationResult
        }

        Task {
            if let newPost {
                try? await backend.syncPost(newPost)
            }
            try? await backend.logModerationEvent(moderationResult.reason)
        }
        return moderationResult
    }

    func normalizedSponsorHandle(_ raw: String) -> String {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return "" }
        return t.hasPrefix("@") ? t : "@\(t)"
    }

    /// Placeholder web profile until in-app deep links exist for every brand handle.
    func openSponsorBrandProfile(handle: String) {
        let h = handle.replacingOccurrences(of: "@", with: "")
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        guard !h.isEmpty, let url = URL(string: "https://chitchat.app/u/\(h)") else { return }
        UIApplication.shared.open(url)
    }

    func openSponsorExternalURL(_ raw: String) {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: t),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else { return }
        UIApplication.shared.open(url)
    }

    /// Heuristic “AI” ad lines for sponsors (on-device templates; replace with server LLM when wired).
    func suggestedAdCopy(for productNote: String, sponsorBrandHandle: String = "") -> String {
        let stem = productNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let brand = normalizedSponsorHandle(sponsorBrandHandle).trimmingCharacters(in: .whitespacesAndNewlines)
        let base: String
        if stem.isEmpty && brand.isEmpty {
            base = "New drop for creators on Chit Chat Social."
        } else if stem.isEmpty {
            base = "See what \(brand) is sharing — tap the brand link to learn more."
        } else {
            base = stem
        }
        let hooks = [
            "Tap through to shop — limited run.",
            "Official partner post. See link in thread.",
            "Swipe up energy: save this before it’s gone."
        ]
        let hook = hooks[abs(base.hashValue) % hooks.count]
        var body = "\(base)\n\n\(hook)"
        if !brand.isEmpty {
            body += "\n\n\(brand)"
        }
        return "\(body)\n\n#ad #sponsored"
    }

    // MARK: - Trust & safety (AI monitoring)

    var isPolicySuspendedNow: Bool {
        if let until = accountPolicyBanUntil, until > Date() { return true }
        return false
    }

    var policySuspensionUserMessage: String {
        "Your account is suspended for policy violations. \(policySuspensionRemainingDescription ?? "Try again later.")"
    }

    var policySuspensionRemainingDescription: String? {
        guard let until = accountPolicyBanUntil, until > Date() else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Suspension ends \(formatter.localizedString(for: until, relativeTo: Date()))."
    }

    func clearExpiredPolicyBanIfNeeded() {
        guard let until = accountPolicyBanUntil, until <= Date() else { return }
        accountPolicyBanUntil = nil
        saveModerationPolicyState()
    }

    func hasRevealedViolencePost(_ id: UUID) -> Bool {
        revealedViolencePostIDs.contains(id)
    }

    func skipViolenceWarningActive(for id: UUID) -> Bool {
        skippedViolencePostIDs.contains(id) && !revealedViolencePostIDs.contains(id)
    }

    func revealViolencePost(_ id: UUID) {
        revealedViolencePostIDs.insert(id)
        skippedViolencePostIDs.remove(id)
        saveModerationPolicyState()
    }

    func skipViolenceWarningForPost(_ id: UUID) {
        skippedViolencePostIDs.insert(id)
        saveModerationPolicyState()
    }

    private func handleBlockedNudityViolation(source: String, textSnippet: String) {
        moderationStrikeCount += 1
        // Escalation: 1 week → 2 weeks → 30d → 90d → 180d for repeat attempts.
        let suspensionDaysTiers = [7, 14, 30, 90, 180]
        let tierIndex = min(max(0, moderationStrikeCount - 1), suspensionDaysTiers.count - 1)
        let days = suspensionDaysTiers[tierIndex]
        let duration = TimeInterval(days * 86_400)
        let base = max(Date(), accountPolicyBanUntil ?? .distantPast)
        accountPolicyBanUntil = base.addingTimeInterval(duration)
        saveModerationPolicyState()

        let detail = "Strike \(moderationStrikeCount): sexual/nudity content removed (\(source)). Account suspended \(days) day(s)."
        addActivity(type: .moderation, detail: detail)

        let banner = "Policy: content removed. Strike \(moderationStrikeCount) — suspended \(days) day(s)."
        showModerationBanner(banner)

        // Policy actions: always send in-app notification and email (critical safety).
        ModerationNotificationHelper.schedulePolicyAlert(
            title: "Chit Chat Social — content removed, account suspended",
            body: "AI monitoring: prohibited content was deleted. Strike \(moderationStrikeCount) — suspended \(days) day(s). Check Activity."
        )

        let email = effectiveRecoveryEmail()
        let subject = "Chit Chat Social — policy action: content deleted, account suspended"
        let body = """
        AI monitoring removed your submission for sexual or nudity-related content. Your account has been suspended.

        Source: \(source)
        Strike: \(moderationStrikeCount)
        Suspension: \(days) day(s) from enforcement time.
        Account: \(currentUser.handle)

        Snippet (may be truncated): \(String(textSnippet.prefix(280)))

        Repeated violations increase suspension: 1 week → 2 weeks → 30 → 90 → 180 days.
        """
        Task {
            try? await backend.sendModerationEmail(toEmail: email, subject: subject, body: body)
        }
        Task {
            try? await backend.logModerationEvent(
                "STRIKE \(moderationStrikeCount): policy removal (\(source)) — suspended \(days)d"
            )
        }
    }

    /// In-app + email + push when the user's own post is flagged for violent / disturbing news (viewers get a gate).
    private func notifyPosterViolenceWarningPosted() {
        addActivity(
            type: .moderation,
            detail: "Your post will show an opaque violence warning. Viewers must choose to view or skip."
        )
        ModerationNotificationHelper.scheduleViolencePostedNotice()
        let email = effectiveRecoveryEmail()
        let subject = "Chit Chat Social — violent or disturbing news flag"
        let body = """
        AI monitoring applied a viewer warning to your latest post on Chit Chat Social.

        Account: \(currentUser.handle)
        Others will see a full-screen opaque warning and must choose to view or skip.

        This is not a strike by itself; repeated abuse of safety systems can still lead to suspension.
        """
        Task {
            try? await backend.sendModerationEmail(toEmail: email, subject: subject, body: body)
        }
    }

    func showModerationBanner(_ message: String) {
        moderationBannerMessage = message
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            if moderationBannerMessage == message {
                moderationBannerMessage = nil
            }
        }
    }

    func dismissModerationBanner() {
        moderationBannerMessage = nil
    }

    func setAccountRecoveryEmail(_ value: String) {
        accountRecoveryEmail = value.trimmingCharacters(in: .whitespacesAndNewlines)
        saveModerationPolicyState()
    }

    private func effectiveRecoveryEmail() -> String {
        let trimmed = accountRecoveryEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, trimmed.contains("@") { return trimmed }
        return "\(currentUser.username.lowercased())@chitchat.placeholder"
    }

    private func loadModerationPolicyState() {
        let defaults = UserDefaults.standard
        moderationStrikeCount = max(0, defaults.integer(forKey: moderationStrikeStorageKey))
        if let ts = defaults.object(forKey: moderationBanUntilStorageKey) as? TimeInterval {
            accountPolicyBanUntil = Date(timeIntervalSince1970: ts)
        }
        accountRecoveryEmail = defaults.string(forKey: recoveryEmailStorageKey) ?? ""
        if let data = defaults.data(forKey: revealedViolenceStorageKey),
           let strings = try? JSONDecoder().decode([String].self, from: data) {
            revealedViolencePostIDs = Set(strings.compactMap(UUID.init))
        }
        if let data = defaults.data(forKey: skippedViolenceStorageKey),
           let strings = try? JSONDecoder().decode([String].self, from: data) {
            skippedViolencePostIDs = Set(strings.compactMap(UUID.init))
        }
    }

    private func saveModerationPolicyState() {
        let defaults = UserDefaults.standard
        defaults.set(moderationStrikeCount, forKey: moderationStrikeStorageKey)
        if let ban = accountPolicyBanUntil {
            defaults.set(ban.timeIntervalSince1970, forKey: moderationBanUntilStorageKey)
        } else {
            defaults.removeObject(forKey: moderationBanUntilStorageKey)
        }
        defaults.set(accountRecoveryEmail, forKey: recoveryEmailStorageKey)
        let revealed = revealedViolencePostIDs.map(\.uuidString)
        if let data = try? JSONEncoder().encode(revealed) {
            defaults.set(data, forKey: revealedViolenceStorageKey)
        }
        let skipped = skippedViolencePostIDs.map(\.uuidString)
        if let data = try? JSONEncoder().encode(skipped) {
            defaults.set(data, forKey: skippedViolenceStorageKey)
        }
    }

    func parseTaggedHandles(from raw: String) -> [String] {
        let tokens = raw
            .replacingOccurrences(of: ",", with: " ")
            .split(separator: " ")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let normalized = tokens.map { token in
            token.hasPrefix("@") ? token : "@\(token)"
        }
        return Array(Set(normalized.map { $0.lowercased() })).sorted()
    }

    func requestCombinedPost(
        targetHandle: String,
        caption: String,
        imageData: Data?,
        surfaceStyle: PostSurfaceStyle,
        taggedHandles: [String]
    ) -> Bool {
        let trimmed = targetHandle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let normalized = trimmed.hasPrefix("@") ? trimmed.lowercased() : "@\(trimmed.lowercased())"
        guard normalized != currentUser.handle.lowercased() else { return false }
        let request = CombinedPostRequest(
            id: UUID(),
            fromHandle: currentUser.handle,
            toHandle: normalized,
            caption: caption,
            imageData: imageData,
            surfaceStyle: surfaceStyle,
            createdAt: Date()
        )
        combinedPostRequests.insert(request, at: 0)
        saveCombinedPostRequests()
        addActivity(type: .message, detail: "Combined-post request sent to \(normalized).")
        let targetTags = Array(Set(taggedHandles + [normalized]))
        _ = publishPost(
            caption: "[Pending combined post] \(caption)",
            type: .post,
            imageData: imageData,
            storyAudience: .public,
            audience: .public,
            isCollab: true,
            areLikesHidden: hideLikeCountsByDefault,
            areCommentsHidden: hideCommentCountsByDefault,
            blockNudity: true,
            surfaceStyle: surfaceStyle,
            taggedHandles: targetTags,
            combinedOwnerHandle: currentUser.handle
        )
        return true
    }

    func myIncomingCombinedPostRequests() -> [CombinedPostRequest] {
        combinedPostRequests.filter { $0.toHandle.caseInsensitiveCompare(currentUser.handle) == .orderedSame }
    }

    func approveCombinedPostRequest(_ requestID: UUID) {
        guard let index = combinedPostRequests.firstIndex(where: { $0.id == requestID }) else { return }
        let request = combinedPostRequests.remove(at: index)
        saveCombinedPostRequests()
        _ = publishPost(
            caption: "[Combined approved] \(request.caption)",
            type: .post,
            imageData: request.imageData,
            storyAudience: .public,
            audience: .public,
            isCollab: true,
            areLikesHidden: hideLikeCountsByDefault,
            areCommentsHidden: hideCommentCountsByDefault,
            blockNudity: true,
            surfaceStyle: request.surfaceStyle,
            taggedHandles: [request.fromHandle, request.toHandle],
            combinedOwnerHandle: request.fromHandle
        )
        addActivity(type: .message, detail: "Approved combined post from \(request.fromHandle).")
    }

    func declineCombinedPostRequest(_ requestID: UUID) {
        combinedPostRequests.removeAll { $0.id == requestID }
        saveCombinedPostRequests()
    }

    func addMessage(to threadID: UUID, text: String) {
        clearExpiredPolicyBanIfNeeded()
        if isPolicySuspendedNow {
            addActivity(type: .moderation, detail: "Message not sent — account suspended for policy violations.")
            return
        }
        let mod = ModerationService.evaluate(caption: text, blockNudity: true)
        guard mod.label == .safe else {
            if mod.label == .blockedNudity {
                handleBlockedNudityViolation(source: "chat", textSnippet: text)
            } else {
                addActivity(type: .moderation, detail: "Message not sent — \(mod.reason)")
            }
            return
        }
        guard let index = chats.firstIndex(where: { $0.id == threadID }) else { return }
        let newMessage = MessageItem(
            id: UUID(),
            senderHandle: currentUser.handle,
            text: text,
            sentAt: Date(),
            kind: detectMessageKind(text),
            delivery: .sent
        )
        chats[index].messages.append(newMessage)
        seenThreadIDs.insert(threadID)
        typingByThreadID[threadID] = nil
        markThreadDelivered(threadID)
        addActivity(type: .message, detail: "New message in \(chats[index].title)")
    }

    func deleteMessage(threadID: UUID, messageID: UUID) {
        guard let threadIndex = chats.firstIndex(where: { $0.id == threadID }) else { return }
        guard let messageIndex = chats[threadIndex].messages.firstIndex(where: { $0.id == messageID }) else { return }
        let message = chats[threadIndex].messages.remove(at: messageIndex)
        let snapshot = DeletedMessageSnapshot(threadID: threadID, index: messageIndex, message: message)
        lastDeletedMessageSnapshot = snapshot
        registerUndoEntry(label: "Delete message", kind: .message(snapshot))
    }

    @discardableResult
    func undoLastDeletedMessage() -> Bool {
        guard let index = undoQueue.lastIndex(where: {
            if case .message = $0.kind { return true }
            return false
        }) else { return false }
        let entry = undoQueue.remove(at: index)
        let result = applyUndoEntry(entry)
        syncUndoIndicators()
        return result
    }

    func updateMessage(threadID: UUID, messageID: UUID, newText: String) {
        clearExpiredPolicyBanIfNeeded()
        if isPolicySuspendedNow {
            addActivity(type: .moderation, detail: "Message edit not saved — account suspended.")
            return
        }
        guard let threadIndex = chats.firstIndex(where: { $0.id == threadID }) else { return }
        guard let messageIndex = chats[threadIndex].messages.firstIndex(where: { $0.id == messageID }) else { return }
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let mod = ModerationService.evaluate(caption: trimmed, blockNudity: true)
        guard mod.label == .safe else {
            if mod.label == .blockedNudity {
                handleBlockedNudityViolation(source: "chat_edit", textSnippet: trimmed)
            } else {
                addActivity(type: .moderation, detail: "Message edit not saved — \(mod.reason)")
            }
            return
        }
        var message = chats[threadIndex].messages[messageIndex]
        message = MessageItem(
            id: message.id,
            senderHandle: message.senderHandle,
            text: trimmed,
            sentAt: message.sentAt,
            kind: detectMessageKind(trimmed),
            delivery: message.delivery
        )
        chats[threadIndex].messages[messageIndex] = message
    }

    func deleteMessages(threadID: UUID, messageIDs: [UUID]) {
        let ids = Set(messageIDs)
        guard !ids.isEmpty else { return }
        guard let threadIndex = chats.firstIndex(where: { $0.id == threadID }) else { return }
        let indexed = chats[threadIndex].messages.enumerated().filter { ids.contains($0.element.id) }
        for pair in indexed.sorted(by: { $0.offset > $1.offset }) {
            let message = chats[threadIndex].messages.remove(at: pair.offset)
            let snapshot = DeletedMessageSnapshot(threadID: threadID, index: pair.offset, message: message)
            registerUndoEntry(label: "Delete messages", kind: .message(snapshot))
        }
    }

    func deleteAllMyMessages(threadID: UUID) {
        guard let threadIndex = chats.firstIndex(where: { $0.id == threadID }) else { return }
        let mine = chats[threadIndex].messages.enumerated().filter {
            $0.element.senderHandle.caseInsensitiveCompare(currentUser.handle) == .orderedSame
        }
        for pair in mine.sorted(by: { $0.offset > $1.offset }) {
            let message = chats[threadIndex].messages.remove(at: pair.offset)
            let snapshot = DeletedMessageSnapshot(threadID: threadID, index: pair.offset, message: message)
            registerUndoEntry(label: "Delete my messages", kind: .message(snapshot))
        }
    }

    func addIncomingMessage(to threadID: UUID, from handle: String, text: String) {
        guard let index = chats.firstIndex(where: { $0.id == threadID }) else { return }
        let newMessage = MessageItem(
            id: UUID(),
            senderHandle: handle,
            text: text,
            sentAt: Date(),
            kind: detectMessageKind(text),
            delivery: .delivered
        )
        chats[index].messages.append(newMessage)
        seenThreadIDs.remove(threadID)
        addActivity(type: .message, detail: "New message from \(handle).")
    }

    func setTyping(threadID: UUID, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        typingByThreadID[threadID] = trimmed.isEmpty ? nil : "\(currentUser.handle) typing..."
    }

    func typingStatus(threadID: UUID) -> String? {
        typingByThreadID[threadID]
    }

    func markThreadSeen(_ threadID: UUID) {
        seenThreadIDs.insert(threadID)
        for i in chats.indices {
            guard chats[i].id == threadID else { continue }
            for j in chats[i].messages.indices {
                if chats[i].messages[j].senderHandle.caseInsensitiveCompare(currentUser.handle) == .orderedSame {
                    chats[i].messages[j].delivery = .seen
                }
            }
        }
    }

    func isThreadSeen(_ threadID: UUID) -> Bool {
        seenThreadIDs.contains(threadID)
    }

    private func detectMessageKind(_ text: String) -> MessageContentKind {
        let lower = text.lowercased()
        if lower.contains("[voice") { return .voice }
        if lower.contains("[media]") { return .media }
        if lower.contains("[scheduled]") { return .system }
        return .text
    }

    private func markThreadDelivered(_ threadID: UUID) {
        for i in chats.indices {
            guard chats[i].id == threadID else { continue }
            for j in chats[i].messages.indices {
                if chats[i].messages[j].senderHandle.caseInsensitiveCompare(currentUser.handle) == .orderedSame,
                   chats[i].messages[j].delivery == .sent {
                    chats[i].messages[j].delivery = .delivered
                }
            }
        }
    }

    func latestDeliveryState(for threadID: UUID) -> MessageDeliveryState {
        guard let thread = chats.first(where: { $0.id == threadID }) else { return .sent }
        guard let myLatest = thread.messages.last(where: { $0.senderHandle.caseInsensitiveCompare(currentUser.handle) == .orderedSame }) else {
            return .delivered
        }
        return myLatest.delivery
    }

    func toggleThreadMediaFirst(_ threadID: UUID) {
        if mediaFirstThreadIDs.contains(threadID) {
            mediaFirstThreadIDs.remove(threadID)
        } else {
            mediaFirstThreadIDs.insert(threadID)
        }
    }

    func isThreadMediaFirst(_ threadID: UUID) -> Bool {
        mediaFirstThreadIDs.contains(threadID)
    }

    func replyToStory(handle: String, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let existing = chats.first(where: { $0.title.caseInsensitiveCompare(handle) == .orderedSame }) {
            addMessage(to: existing.id, text: "Story reply: \(trimmed)")
            return
        }
        let thread = ChatThread(
            id: UUID(),
            title: handle,
            messages: [
                MessageItem(
                    id: UUID(),
                    senderHandle: currentUser.handle,
                    text: "Story reply: \(trimmed)",
                    sentAt: Date(),
                    kind: .text,
                    delivery: .sent
                )
            ]
        )
        chats.insert(thread, at: 0)
        seenThreadIDs.insert(thread.id)
    }

    func togglePinThread(_ threadID: UUID) {
        if pinnedThreadIDs.contains(threadID) {
            pinnedThreadIDs.remove(threadID)
        } else {
            pinnedThreadIDs.insert(threadID)
        }
    }

    func toggleMuteThread(_ threadID: UUID) {
        if mutedThreadIDs.contains(threadID) {
            mutedThreadIDs.remove(threadID)
        } else {
            mutedThreadIDs.insert(threadID)
            typingByThreadID[threadID] = nil
        }
    }

    func isThreadMuted(_ threadID: UUID) -> Bool {
        mutedThreadIDs.contains(threadID)
    }

    func acceptDMRequest(_ requestID: UUID) {
        guard let index = dmRequests.firstIndex(where: { $0.id == requestID }) else { return }
        let request = dmRequests.remove(at: index)
        let newThread = ChatThread(
            id: UUID(),
            title: request.fromHandle,
            messages: [
                MessageItem(
                    id: UUID(),
                    senderHandle: request.fromHandle,
                    text: request.previewText,
                    sentAt: Date(),
                    kind: .text,
                    delivery: .delivered
                )
            ]
        )
        chats.insert(newThread, at: 0)
        seenThreadIDs.remove(newThread.id)
    }

    func declineDMRequest(_ requestID: UUID) {
        dmRequests.removeAll { $0.id == requestID }
    }

    func filteredThreads(query: String) -> [ChatThread] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = trimmed.isEmpty ? chats : chats.filter { thread in
            thread.title.localizedCaseInsensitiveContains(trimmed)
            || thread.messages.contains(where: { $0.text.localizedCaseInsensitiveContains(trimmed) })
        }
        return source.sorted { lhs, rhs in
            let lPinned = pinnedThreadIDs.contains(lhs.id)
            let rPinned = pinnedThreadIDs.contains(rhs.id)
            if lPinned != rPinned { return lPinned && !rPinned }
            let lMuted = mutedThreadIDs.contains(lhs.id)
            let rMuted = mutedThreadIDs.contains(rhs.id)
            if lMuted != rMuted { return !lMuted && rMuted }
            let lDate = lhs.messages.last?.sentAt ?? .distantPast
            let rDate = rhs.messages.last?.sentAt ?? .distantPast
            return lDate > rDate
        }
    }

    func assignCorporateRole(handle: String, role: CorporateCallRole) {
        let normalized = handle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        let key = normalized.hasPrefix("@") ? normalized.lowercased() : "@\(normalized.lowercased())"
        corporateRolesByHandle[key] = role
    }

    func corporateRole(for handle: String) -> CorporateCallRole {
        let normalized = handle.hasPrefix("@") ? handle.lowercased() : "@\(handle.lowercased())"
        return corporateRolesByHandle[normalized] ?? .listener
    }

    func addCorporateMeetingRoom(title: String, participants: [String]) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let room = CorporateMeetingRoom(
            id: UUID(),
            title: trimmed,
            participantHandles: participants.isEmpty ? [currentUser.handle] : participants,
            activeAgenda: "Agenda not set yet."
        )
        corporateMeetingRooms.insert(room, at: 0)
    }

    func splitCorporateMeetingRooms() {
        guard !corporateMeetingRooms.isEmpty else { return }
        let source = corporateMeetingRooms[0]
        let a = CorporateMeetingRoom(
            id: UUID(),
            title: "\(source.title) - Room A",
            participantHandles: Array(source.participantHandles.prefix(max(1, source.participantHandles.count / 2))),
            activeAgenda: "Breakout A discussion"
        )
        let b = CorporateMeetingRoom(
            id: UUID(),
            title: "\(source.title) - Room B",
            participantHandles: Array(source.participantHandles.suffix(max(1, source.participantHandles.count / 2))),
            activeAgenda: "Breakout B discussion"
        )
        corporateMeetingRooms.insert(contentsOf: [a, b], at: 0)
    }

    func scheduleStartLiveSession(headline: String) {
        guard !isLiveNow else { return }
        cancelLiveCountdown()
        liveCountdownTask = Task { @MainActor in
            for remaining in stride(from: 5, through: 1, by: -1) {
                if Task.isCancelled { return }
                liveGoLiveCountdown = remaining
                HapticTokens.light()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            guard !Task.isCancelled else { return }
            liveGoLiveCountdown = nil
            startLiveSession(headline: headline)
        }
    }

    func cancelLiveCountdown() {
        liveCountdownTask?.cancel()
        liveCountdownTask = nil
        liveGoLiveCountdown = nil
    }

    func normalizedSocialHandle(_ handle: String) -> String {
        let t = handle.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return "@guest" }
        return t.hasPrefix("@") ? t.lowercased() : "@\(t.lowercased())"
    }

    func isHandleLive(_ handle: String) -> Bool {
        liveSessionsByHost[normalizedSocialHandle(handle)] != nil
    }

    func liveSession(for handle: String) -> LiveBroadcastSession? {
        liveSessionsByHost[normalizedSocialHandle(handle)]
    }

    func liveCommentsThread(for host: String) -> [LiveCommentItem] {
        liveSession(for: host)?.comments ?? []
    }

    func liveViewerCount(for host: String) -> Int {
        liveSession(for: host)?.viewerHandles.count ?? 0
    }

    func otherLiveHostHandles(excludingCurrentUser: Bool = true, limit: Int = 8) -> [String] {
        let keys = liveSessionsByHost.keys.sorted()
        let mine = normalizedSocialHandle(currentUser.handle)
        let filtered = excludingCurrentUser ? keys.filter { $0 != mine } : keys
        return Array(filtered.prefix(limit))
    }

    func presentLiveRoom(for handle: String) {
        guard isHandleLive(handle) else { return }
        liveSheetHost = normalizedSocialHandle(handle)
    }

    func dismissLiveRoom() {
        liveSheetHost = nil
    }

    func joinLiveSession(host: String) {
        let key = normalizedSocialHandle(host)
        guard var session = liveSessionsByHost[key] else { return }
        let selfKey = normalizedSocialHandle(currentUser.handle)
        guard key != selfKey else { return }
        session.viewerHandles.insert(selfKey)
        liveSessionsByHost[key] = session
        liveAudienceHost = key
        liveSheetHost = key
        HapticTokens.success()
    }

    func leaveLiveSessionAsViewer() {
        guard let host = liveAudienceHost else {
            liveSheetHost = nil
            return
        }
        let key = normalizedSocialHandle(host)
        if var session = liveSessionsByHost[key] {
            session.viewerHandles.remove(normalizedSocialHandle(currentUser.handle))
            liveSessionsByHost[key] = session
        }
        liveAudienceHost = nil
        liveSheetHost = nil
        HapticTokens.light()
    }

    func startLiveSession(headline: String) {
        let key = normalizedSocialHandle(currentUser.handle)
        let seedComments = [
            LiveCommentItem(id: UUID(), authorHandle: "@fan_live", text: "We are in!", createdAt: Date()),
            LiveCommentItem(id: UUID(), authorHandle: "@creatorone", text: "Drop the product link 🔥", createdAt: Date().addingTimeInterval(-20))
        ]
        liveSessionsByHost[key] = LiveBroadcastSession(headline: headline, viewerHandles: [], comments: seedComments)
        addActivity(type: .message, detail: "Started live: \(headline)")
        HapticTokens.success()
    }

    func endLiveSession() {
        cancelLiveCountdown()
        let key = normalizedSocialHandle(currentUser.handle)
        liveSessionsByHost.removeValue(forKey: key)
        if liveAudienceHost == key { liveAudienceHost = nil }
        if liveSheetHost == key { liveSheetHost = nil }
    }

    func postLiveComment(_ text: String, from handle: String? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let selfKey = normalizedSocialHandle(currentUser.handle)
        let key: String? = {
            if let audience = liveAudienceHost, liveSessionsByHost[normalizedSocialHandle(audience)] != nil {
                return normalizedSocialHandle(audience)
            }
            if isLiveNow { return selfKey }
            return nil
        }()
        guard let threadKey = key, var session = liveSessionsByHost[threadKey] else { return }
        let author = handle.map { normalizedSocialHandle($0) } ?? selfKey
        session.comments.insert(
            LiveCommentItem(
                id: UUID(),
                authorHandle: author,
                text: trimmed,
                createdAt: Date()
            ),
            at: 0
        )
        liveSessionsByHost[threadKey] = session
    }

    func applySocialFaceEmojiMask(_ emoji: String) {
        socialFaceEmojiMask = emoji
    }

    func toggleLiveCoHost(_ handle: String) {
        let normalized = handle.hasPrefix("@") ? handle.lowercased() : "@\(handle.lowercased())"
        guard normalized != currentUser.handle.lowercased() else { return }
        if let idx = liveCoHosts.firstIndex(where: { $0.caseInsensitiveCompare(normalized) == .orderedSame }) {
            liveCoHosts.remove(at: idx)
        } else {
            liveCoHosts.append(normalized)
        }
    }

    func setAudienceRole(handle: String, role: SocialLiveAudienceRole) {
        let normalized = handle.hasPrefix("@") ? handle.lowercased() : "@\(handle.lowercased())"
        audienceRoleByHandle[normalized] = role
    }

    func audienceRole(for handle: String) -> SocialLiveAudienceRole {
        let normalized = handle.hasPrefix("@") ? handle.lowercased() : "@\(handle.lowercased())"
        return audienceRoleByHandle[normalized] ?? .viewer
    }

    func requestVerification(note: String, hasInstagramVerification: Bool, category: VerificationCategory = .creator) {
        let base = hasInstagramVerification
            ? "Early verification request (IG verified): "
            : "Verification request: "
        verificationInbox.insert(base + note, at: 0)
        verificationRequests.insert(
            VerificationRequest(
                id: UUID(),
                username: currentUser.username,
                handle: currentUser.handle,
                note: note,
                hasInstagramVerification: hasInstagramVerification,
                requestedAt: Date(),
                status: .pending,
                reviewerNote: "",
                category: category
            ),
            at: 0
        )
        saveVerificationRequests()
        currentUser.verificationStatus = .pending
        syncCurrentUserInDirectory()
        addActivity(type: .verification, detail: "Verification request submitted.")
        Task {
            try? await backend.syncUserProfile(currentUser)
        }
    }

    /// Grants paid verification after a verified StoreKit non-consumable purchase.
    func grantPaidVerificationFromPurchase() {
        guard currentUser.verificationStatus != .verifiedInternal else { return }
        currentUser.verificationStatus = .paid
        syncCurrentUserInDirectory()
    }

    /// Keeps profile badge in sync with App Store entitlements (purchase, restore, refund).
    func syncPaidVerificationEntitlement(active: Bool) {
        if active {
            grantPaidVerificationFromPurchase()
        } else if currentUser.verificationStatus == .paid {
            currentUser.verificationStatus = .unverified
            syncCurrentUserInDirectory()
        }
    }

    /// Reserved — use StoreKit via `StoreKitManager.purchasePaidVerification()`.
    func requestPaidVerification() {}

    func grantInternalVerification(userID: UUID) {
        guard let index = internalUsers.firstIndex(where: { $0.id == userID }) else { return }
        internalUsers[index].verificationStatus = .verifiedInternal
        if currentUser.id == userID {
            currentUser.verificationStatus = .verifiedInternal
        }
    }

    func approveVerificationRequest(_ requestID: UUID, reviewerNote: String = "") {
        guard let index = verificationRequests.firstIndex(where: { $0.id == requestID }) else { return }
        verificationRequests[index].status = .approved
        verificationRequests[index].reviewerNote = reviewerNote
        let username = verificationRequests[index].username.lowercased()
        let category = verificationRequests[index].category
        if let userIdx = internalUsers.firstIndex(where: { $0.username.lowercased() == username }) {
            internalUsers[userIdx].verificationStatus = .verifiedInternal
            if category == .business {
                internalUsers[userIdx].isBusinessAccount = true
                internalUsers[userIdx].businessJobPostingApproved = false // Each job post requires separate approval
            }
            if currentUser.username.lowercased() == username {
                currentUser.verificationStatus = .verifiedInternal
                if category == .business {
                    currentUser.isBusinessAccount = true
                    currentUser.businessJobPostingApproved = false
                }
            }
        }
        syncCurrentUserInDirectory()
        saveVerificationRequests()
    }

    func declineVerificationRequest(_ requestID: UUID, reviewerNote: String = "") {
        guard let index = verificationRequests.firstIndex(where: { $0.id == requestID }) else { return }
        verificationRequests[index].status = .declined
        verificationRequests[index].reviewerNote = reviewerNote
        let username = verificationRequests[index].username.lowercased()
        if let userIdx = internalUsers.firstIndex(where: { $0.username.lowercased() == username }),
           internalUsers[userIdx].verificationStatus == .pending {
            internalUsers[userIdx].verificationStatus = .unverified
        }
        if currentUser.username.lowercased() == username, currentUser.verificationStatus == .pending {
            currentUser.verificationStatus = .unverified
        }
        syncCurrentUserInDirectory()
        saveVerificationRequests()
    }

    func filteredInternalUsers(query: String) -> [UserProfile] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return internalUsers }
        return internalUsers.filter { user in
            user.username.localizedCaseInsensitiveContains(trimmed)
            || user.displayName.localizedCaseInsensitiveContains(trimmed)
            || user.handle.localizedCaseInsensitiveContains(trimmed)
        }
    }

    /// Auto-approve pending verification requests that include the Instagram verification signal (dashboard toggle).
    func autoApproveIGSignalVerificationRequests() {
        let pendingIDs = verificationRequests
            .filter { $0.status == .pending && $0.hasInstagramVerification }
            .map(\.id)
        for id in pendingIDs {
            approveVerificationRequest(id, reviewerNote: "Auto-approved (Instagram verification signal).")
        }
    }

    /// Removes a user from the local directory (does not call the remote backend).
    func adminDeleteInternalUser(id: UUID) {
        guard id != currentUser.id else { return }
        guard let user = internalUsers.first(where: { $0.id == id }) else { return }
        let key = user.username.lowercased()
        verificationRequests.removeAll { $0.username.lowercased() == key }
        saveVerificationRequests()
        internalUsers.removeAll { $0.id == id }
        localCredentials.removeValue(forKey: key)
        saveCredentials()
        loggedInAccountUsernames.removeAll { $0.lowercased() == key }
        saveLoggedInAccounts()
        ReservedHandles.removeAdminHeldUsername(user.username)
        ReservedHandles.setHandoffEmail(forUsername: user.username, email: "")
    }

    func approveAllPendingVerificationRequests() {
        let ids = verificationRequests.filter { $0.status == .pending }.map(\.id)
        for id in ids {
            approveVerificationRequest(id, reviewerNote: "Bulk approved by admin.")
        }
    }

    func adminSetVerificationForUser(userID: UUID, status: VerificationStatus) {
        guard let idx = internalUsers.firstIndex(where: { $0.id == userID }) else { return }
        internalUsers[idx].verificationStatus = status
        if currentUser.id == userID {
            currentUser.verificationStatus = status
        }
        syncCurrentUserInDirectory()
    }

    /// Creates a local login + directory profile (e.g. VIP placeholder). Share password securely; add handoff email in Admin user screen.
    func adminCreatePlaceholderLocalAccount(
        username: String,
        displayName: String,
        password: String,
        grantOfficialVerifiedBadge: Bool
    ) -> String? {
        guard let cleaned = normalizedUsername(from: username) else {
            return "Username must be 3+ characters (letters, numbers, . or _)."
        }
        if ReservedHandles.isSystemReserved(cleaned) {
            return "That username is system-protected."
        }
        let key = cleaned.lowercased()
        if internalUsers.contains(where: { $0.username.lowercased() == key }) {
            return "That username already exists in the directory."
        }
        if localCredentials[key] != nil {
            return "Login already exists for this username."
        }
        guard password.count >= 8 else {
            return "Password must be at least 8 characters."
        }
        if !ReservedHandles.isAdminHeld(cleaned), let err = ReservedHandles.addAdminHeldUsername(cleaned) {
            return err
        }
        localCredentials[key] = password
        saveCredentials()
        let profile = UserProfile(
            id: UUID(),
            username: cleaned,
            handle: "@\(cleaned)",
            accountEmail: "",
            accountPhone: Self.placeholderAccountPhoneDigits,
            enterpriseAlias: displayName.isEmpty ? cleaned : displayName,
            displayName: displayName.isEmpty ? cleaned : displayName,
            followers: 0,
            verificationStatus: grantOfficialVerifiedBadge ? .verifiedInternal : .unverified,
            allowEnterpriseReveal: false,
            linkedPlatforms: []
        )
        internalUsers.append(profile)
        return nil
    }

    /// Admin rename: updates username, @handle, optional credential key migration, and logged-in account list.
    @discardableResult
    func adminRenameUser(userID: UUID, rawUsername: String) -> String? {
        guard let cleaned = normalizedUsername(from: rawUsername) else {
            return "Username must be 3+ characters (letters, numbers, . or _)."
        }
        if ReservedHandles.isSystemReserved(cleaned) {
            return "That username is a protected system reserve."
        }
        let newKey = cleaned.lowercased()
        guard let idx = internalUsers.firstIndex(where: { $0.id == userID }) else {
            return "User not found."
        }
        if internalUsers.contains(where: { $0.id != userID && $0.username.lowercased() == newKey }) {
            return "That username is already taken."
        }
        if ReservedHandles.isAdminHeld(cleaned) {
            ReservedHandles.removeAdminHeldUsername(cleaned)
        }
        let oldUsername = internalUsers[idx].username
        if ReservedHandles.isAdminHeld(oldUsername) {
            ReservedHandles.removeAdminHeldUsername(oldUsername)
        }
        let oldKey = oldUsername.lowercased()
        internalUsers[idx].username = cleaned
        internalUsers[idx].handle = "@\(cleaned)"
        if let handoff = ReservedHandles.handoffEmail(forUsername: oldUsername) {
            ReservedHandles.setHandoffEmail(forUsername: oldUsername, email: "")
            ReservedHandles.setHandoffEmail(forUsername: cleaned, email: handoff)
        }

        if let pw = localCredentials.removeValue(forKey: oldKey) {
            localCredentials[newKey] = pw
            saveCredentials()
        }
        if let li = loggedInAccountUsernames.firstIndex(where: { $0.lowercased() == oldKey }) {
            loggedInAccountUsernames[li] = internalUsers[idx].username
            saveLoggedInAccounts()
        }
        for ri in verificationRequests.indices where verificationRequests[ri].username.lowercased() == oldKey {
            verificationRequests[ri].username = internalUsers[idx].username
            verificationRequests[ri].handle = internalUsers[idx].handle
        }
        saveVerificationRequests()
        if currentUser.id == userID {
            currentUser.username = internalUsers[idx].username
            currentUser.handle = internalUsers[idx].handle
        }
        syncCurrentUserInDirectory()
        return nil
    }

    func setMode(_ newMode: PlatformMode) {
        if newMode == .social && !hasSocialProfile { return }
        if newMode == .enterprise && !hasCorporateProfile { return }
        mode = newMode
    }

    func configurePrimaryProfile(
        primaryMode: PlatformMode,
        socialVisible: Bool,
        corporateVisible: Bool,
        createSecondary: Bool
    ) {
        switch primaryMode {
        case .social:
            hasSocialProfile = true
            hasCorporateProfile = createSecondary
        case .enterprise:
            hasCorporateProfile = true
            hasSocialProfile = createSecondary
        }
        socialProfileVisible = socialVisible
        corporateProfileVisible = corporateVisible
        mode = primaryMode
        saveProfileModeState()
#if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        pushChitChatUserDirectoryIfFirebaseSignedIn()
#endif
    }

    func addSecondaryProfile(_ mode: PlatformMode) {
        if mode == .social {
            hasSocialProfile = true
        } else {
            hasCorporateProfile = true
        }
        saveProfileModeState()
    }

    func toggleProfileVisibility(_ mode: PlatformMode) {
        if mode == .social {
            socialProfileVisible.toggle()
        } else {
            corporateProfileVisible.toggle()
        }
        saveProfileModeState()
    }

    func isProfileVisible(_ mode: PlatformMode) -> Bool {
        mode == .social ? socialProfileVisible : corporateProfileVisible
    }

    func profileAvailabilityLabel(_ mode: PlatformMode) -> String {
        let created = mode == .social ? hasSocialProfile : hasCorporateProfile
        guard created else { return "Not created" }
        return isProfileVisible(mode) ? "Visible" : "Hidden"
    }

    var activeInterests: Set<String> {
        mode == .social ? socialInterests : corporateInterests
    }

    func setInterest(_ interest: String, enabled: Bool) {
        let normalized = interest.lowercased()
        if mode == .social {
            if enabled { socialInterests.insert(normalized) } else { socialInterests.remove(normalized) }
        } else {
            if enabled { corporateInterests.insert(normalized) } else { corporateInterests.remove(normalized) }
        }
        saveInterestState()
    }

    func isReelSaved(_ reelID: UUID, collection: String) -> Bool {
        reelCollections[collection.lowercased(), default: []].contains(reelID)
    }

    func toggleReelCollection(_ reelID: UUID, collection: String) {
        let key = collection.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { return }
        var set = reelCollections[key, default: []]
        if set.contains(reelID) {
            set.remove(reelID)
        } else {
            set.insert(reelID)
        }
        reelCollections[key] = set
        saveReelCollections()
    }

    func removeReelCollection(_ collection: String) {
        reelCollections.removeValue(forKey: collection.lowercased())
        saveReelCollections()
    }

    func renameReelCollection(from oldName: String, to newName: String) {
        let source = oldName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let target = newName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !source.isEmpty, !target.isEmpty, source != target else { return }
        let sourceSet = reelCollections[source, default: []]
        reelCollections[target, default: []].formUnion(sourceSet)
        reelCollections.removeValue(forKey: source)
        saveReelCollections()
    }

    func reelCollectionCount(_ collection: String) -> Int {
        reelCollections[collection.lowercased(), default: []].count
    }

    var reelCollectionNames: [String] {
        let defaults = ["favorites", "watch later", "remix ideas"]
        let existing = reelCollections.keys.sorted()
        return Array(Set(defaults + existing)).sorted()
    }

    func recordExploreInteraction(postID: UUID) {
        let key = postID.uuidString
        exploreBoostByPostID[key, default: 0] += 1
        if exploreBoostByPostID.count > 4000 {
            let trimmed = exploreBoostByPostID.sorted { $0.value > $1.value }.prefix(2500)
            exploreBoostByPostID = Dictionary(uniqueKeysWithValues: trimmed.map { ($0.key, $0.value) })
        }
        saveExploreSignals()
    }

    func exploreBoostScore(for postID: UUID) -> Double {
        Double(exploreBoostByPostID[postID.uuidString, default: 0]) * 8.0
    }

    func setBusinessAccount(_ isEnabled: Bool) {
        currentUser.isBusinessAccount = isEnabled
        syncCurrentUserInDirectory()
    }

    func setAdAccountEnabled(_ isEnabled: Bool) {
        currentUser.isAdAccount = isEnabled
        syncCurrentUserInDirectory()
    }

    /// Fetches partner / branded-content flags if `UserDefaults` key `chitchat.publicAdsFlagsURL` is a full URL to `.../api/public/ads-flags`.
    func refreshPublicAdsFlagsFromRemoteIfConfigured() {
        Task { await refreshPublicAdsFlagsFromRemote() }
    }

    private func refreshPublicAdsFlagsFromRemote() async {
        guard
            let raw = UserDefaults.standard.string(forKey: "chitchat.publicAdsFlagsURL")?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            !raw.isEmpty,
            let url = URL(string: raw)
        else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else { return }
            let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let flags = obj?["flags"] as? [String: Any] else { return }
            if let en = flags["nativeSponsoredFeedEnabled"] as? Bool {
                nativeSponsoredFeedEnabled = en
            }
            if let lbl = flags["sponsorDisclosureLabel"] as? String {
                let t = lbl.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty {
                    sponsorDisclosureRemoteLabel = String(t.prefix(80))
                }
            }
        } catch {
            // Keep last-known values on failure.
        }
    }

    func setEnterpriseReveal(_ isEnabled: Bool) {
        currentUser.allowEnterpriseReveal = isEnabled
        syncCurrentUserInDirectory()
    }

    @discardableResult
    func setProfileQuote(_ text: String) -> Bool {
        clearExpiredPolicyBanIfNeeded()
        if isPolicySuspendedNow {
            addActivity(type: .moderation, detail: "Profile quote not saved — account suspended for policy violations.")
            return false
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            currentUser.profileQuote = ""
            syncCurrentUserInDirectory()
            saveProfileQuoteState()
            return true
        }
        let mod = ModerationService.evaluate(caption: trimmed, blockNudity: true)
        guard mod.label == .safe else {
            if mod.label == .blockedNudity {
                handleBlockedNudityViolation(source: "profile_quote", textSnippet: trimmed)
            } else {
                addActivity(type: .moderation, detail: "Quote not saved — \(mod.reason)")
            }
            return false
        }
        currentUser.profileQuote = trimmed
        syncCurrentUserInDirectory()
        saveProfileQuoteState()
        return true
    }

    func setProfileQuoteVisibility(_ isVisible: Bool) {
        currentUser.isProfileQuoteVisible = isVisible
        syncCurrentUserInDirectory()
        saveProfileQuoteState()
    }

    func updateCurrentIdentity(enterpriseAlias: String, displayName: String) {
        let alias = enterpriseAlias.trimmingCharacters(in: .whitespacesAndNewlines)
        let display = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !alias.isEmpty {
            currentUser.enterpriseAlias = alias
        }
        if !display.isEmpty {
            currentUser.displayName = display
        }
        syncCurrentUserInDirectory()
    }

    func setProfileLink(_ urlString: String) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        currentUser.profileLinkURL = trimmed
        syncCurrentUserInDirectory()
    }

    var shouldShowProfileQuoteBubble: Bool {
        currentUser.isProfileQuoteVisible && !currentUser.profileQuote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func togglePlatformLink(_ platform: SocialPlatform) {
        if currentUser.linkedPlatforms.contains(platform) {
            currentUser.linkedPlatforms.removeAll(where: { $0 == platform })
        } else {
            currentUser.linkedPlatforms.append(platform)
        }
        syncCurrentUserInDirectory()
    }

    /// Returns (success, message). Only verified business accounts can post jobs; each job needs approval before it goes live.
    func addContract(title: String, budgetUSD: Int, location: String, isLocalHire: Bool) -> (Bool, String) {
        guard currentUser.isBusinessAccount else {
            return (false, "Verify your business account first to post jobs.")
        }
        let authorHandle = currentUser.handle
        let needsApproval = true
        let deal = ContractDeal(
            id: UUID(),
            title: title,
            budgetUSD: budgetUSD,
            location: location,
            isLocalHire: isLocalHire,
            authorHandle: authorHandle,
            isPendingApproval: needsApproval
        )
        contracts.insert(deal, at: 0)
        if needsApproval {
            addActivity(type: .verification, detail: "Job post submitted for approval. Business accounts require verification to publish jobs.")
        }
        return (true, "Job post submitted for approval. You'll be notified when it's reviewed.")
    }

    func approveJobPost(contractID: UUID) {
        guard let idx = contracts.firstIndex(where: { $0.id == contractID && $0.isPendingApproval }) else { return }
        let handle = contracts[idx].authorHandle
        contracts[idx].isPendingApproval = false
        addActivity(type: .verification, detail: "Job post approved for \(handle).")
    }

    func deleteContract(_ contractID: UUID) {
        contracts.removeAll { $0.id == contractID }
    }

    func addListing(title: String, priceUSD: Int, category: String) {
        let listing = MarketListing(
            id: UUID(),
            title: title,
            priceUSD: priceUSD,
            seller: currentUser.handle,
            category: category
        )
        marketListings.insert(listing, at: 0)
    }

    /// Returns error message if username is invalid or reserved; nil if OK.
    func usernameValidationError(_ rawValue: String) -> String? {
        guard let _ = normalizedUsername(from: rawValue) else {
            return "Enter a valid username (3+ chars, letters/numbers/._)."
        }
        if ReservedHandles.isReserved(rawValue) {
            return "This username is reserved."
        }
        return nil
    }

    /// Normalizes a raw @handle for OAuth / sign-up flows.
    func cleanedUsername(from rawValue: String) -> String? {
        normalizedUsername(from: rawValue)
    }

    /// Picks a unique, non-reserved username from a base string (e.g. Apple email local-part).
    func suggestUniqueUsername(base: String) -> String {
        var sanitized = base
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0 == "." || $0 == "_" }
        if sanitized.count < 3 {
            sanitized = "creator\(UUID().uuidString.prefix(6).lowercased())"
        }
        sanitized = String(sanitized.prefix(20))
        var candidate = sanitized
        var suffix = 0
        while ReservedHandles.isReserved(candidate)
            || internalUsers.contains(where: { $0.username.caseInsensitiveCompare(candidate) == .orderedSame }) {
            suffix += 1
            candidate = "\(sanitized)\(suffix)"
        }
        return candidate
    }

    @discardableResult
    func setUsername(_ rawValue: String) -> Bool {
        guard let cleaned = normalizedUsername(from: rawValue) else { return false }
        guard !ReservedHandles.isReserved(cleaned) else { return false }
        let collision = internalUsers.contains {
            $0.id != currentUser.id && $0.username.compare(cleaned, options: .caseInsensitive) == .orderedSame
        }
        guard !collision else { return false }
        currentUser.username = cleaned
        currentUser.handle = "@\(cleaned)"
        syncCurrentUserInDirectory()
        return true
    }

    func createCommunity(name: String, summary: String, isPublic: Bool, requiresPassword: Bool) {
        let group = CommunityGroup(
            id: UUID(),
            name: name,
            summary: summary,
            creator: currentUser.handle,
            managers: [currentUser.handle],
            isPublic: isPublic,
            requiresPassword: requiresPassword
        )
        communities.insert(group, at: 0)
    }

    func addShopProduct(title: String, description: String, priceUSD: Int, isDropshipEnabled: Bool) {
        let product = ShopProduct(
            id: UUID(),
            sellerHandle: currentUser.handle,
            title: title,
            description: description,
            priceUSD: priceUSD,
            imageSystemName: "bag.fill",
            isDropshipEnabled: isDropshipEnabled
        )
        shopProducts.insert(product, at: 0)
        liveShopSessions.insert(
            LiveShopSession(
                id: UUID(),
                hostHandle: currentUser.handle,
                productID: product.id,
                headline: "Live selling \(product.title)",
                viewerCount: Int.random(in: 12...140)
            ),
            at: 0
        )
    }

    func addPulsePost(text: String, imageSystemName: String?) {
        clearExpiredPolicyBanIfNeeded()
        if isPolicySuspendedNow {
            addActivity(type: .moderation, detail: "Pulse not posted — account suspended for policy violations.")
            return
        }
        let mod = ModerationService.evaluate(caption: text, blockNudity: true)
        switch mod.label {
        case .blockedNudity:
            handleBlockedNudityViolation(source: "pulse", textSnippet: text)
            return
        case .manualReview, .accountSuspended, .missingRequiredMedia, .sponsoredNotEligible:
            addActivity(type: .moderation, detail: "Pulse not posted — \(mod.reason)")
            return
        case .safe, .violenceNeedsConsent:
            break
        }
        let violence = mod.label == .violenceNeedsConsent
        let pulse = PublicPulsePost(
            id: UUID(),
            authorHandle: currentUser.handle,
            text: text,
            imageSystemName: imageSystemName,
            createdAt: Date(),
            violenceWarningRequired: violence
        )
        publicPulse.insert(pulse, at: 0)
        if violence {
            notifyPosterViolenceWarningPosted()
        }
    }

    func searchMusic(query: String, source: MusicSource?) -> [MusicTrack] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return musicLibrary.filter { track in
            let sourceMatches = source == nil || track.source == source
            guard sourceMatches else { return false }
            guard !trimmed.isEmpty else { return true }
            return track.title.localizedCaseInsensitiveContains(trimmed)
            || track.artist.localizedCaseInsensitiveContains(trimmed)
        }
    }

    func playTrack(_ track: MusicTrack) {
        guard let url = Bundle.main.url(forResource: track.bundledFileName, withExtension: "wav") else {
            musicStatusMessage = "Missing bundled track: \(track.bundledFileName).wav"
            nowPlayingTrack = nil
            isMusicPlaying = false
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.numberOfLoops = -1
            player.play()
            audioPlayer = player
            nowPlayingTrack = track
            isMusicPlaying = true
            musicStatusMessage = "Now playing \(track.title)"
        } catch {
            musicStatusMessage = "Playback error: \(error.localizedDescription)"
            nowPlayingTrack = nil
            isMusicPlaying = false
        }
    }

    func togglePlayback() {
        guard nowPlayingTrack != nil else { return }
        guard let audioPlayer else { return }
        if audioPlayer.isPlaying {
            audioPlayer.pause()
            isMusicPlaying = false
            musicStatusMessage = "Paused"
        } else {
            audioPlayer.play()
            isMusicPlaying = true
            musicStatusMessage = "Resumed"
        }
    }

    func setProfilePhoto(data: Data?) {
        let usernameKey = currentUser.username.lowercased()
        profilePhotoData = data
        profilePhotoByUsername[usernameKey] = data
        let storageKey = "\(profilePhotoStoragePrefix)\(usernameKey)"
        if let data {
            UserDefaults.standard.set(data, forKey: storageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: storageKey)
        }
    }

    func setProfileGIF(data: Data?) {
        let usernameKey = currentUser.username.lowercased()
        profileGIFData = data
        profileGIFByUsername[usernameKey] = data
        let storageKey = "\(profileGifStoragePrefix)\(usernameKey)"
        if let data {
            UserDefaults.standard.set(data, forKey: storageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: storageKey)
        }
    }

    func setProfileLoopVideo(data: Data?) {
        let usernameKey = currentUser.username.lowercased()
        profileLoopVideoData = data
        profileLoopVideoByUsername[usernameKey] = data
        let storageKey = "\(profileLoopVideoStoragePrefix)\(usernameKey)"
        if let data {
            UserDefaults.standard.set(data, forKey: storageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: storageKey)
        }
    }

    func setProfileStoryImage(data: Data?) {
        let usernameKey = currentUser.username.lowercased()
        profileStoryImageData = data
        profileStoryImageByUsername[usernameKey] = data
        let storageKey = "\(profileStoryImageStoragePrefix)\(usernameKey)"
        if let data {
            UserDefaults.standard.set(data, forKey: storageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: storageKey)
        }
    }

    func setProfileStoryVideo(data: Data?) {
        let usernameKey = currentUser.username.lowercased()
        profileStoryVideoData = data
        profileStoryVideoByUsername[usernameKey] = data
        let storageKey = "\(profileStoryVideoStoragePrefix)\(usernameKey)"
        if let data {
            UserDefaults.standard.set(data, forKey: storageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: storageKey)
        }
    }

    func setProfileStoryGIF(data: Data?) {
        let usernameKey = currentUser.username.lowercased()
        profileStoryGIFData = data
        profileStoryGIFByUsername[usernameKey] = data
        let storageKey = "\(profileStoryGifStoragePrefix)\(usernameKey)"
        if let data {
            UserDefaults.standard.set(data, forKey: storageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: storageKey)
        }
    }

    func profileGIF(for handle: String) -> Data? {
        mediaData(for: handle, map: profileGIFByUsername)
    }

    func profileLoopVideo(for handle: String) -> Data? {
        mediaData(for: handle, map: profileLoopVideoByUsername)
    }

    func profileStoryImage(for handle: String) -> Data? {
        mediaData(for: handle, map: profileStoryImageByUsername)
    }

    func profileStoryVideo(for handle: String) -> Data? {
        mediaData(for: handle, map: profileStoryVideoByUsername)
    }

    func profileStoryGIF(for handle: String) -> Data? {
        mediaData(for: handle, map: profileStoryGIFByUsername)
    }

    func hasActiveStory(for handle: String) -> Bool {
        if profileStoryImage(for: handle) != nil || profileStoryVideo(for: handle) != nil || profileStoryGIF(for: handle) != nil {
            return true
        }
        let since = Date().addingTimeInterval(-24 * 3600)
        return posts.contains {
            $0.authorHandle.caseInsensitiveCompare(handle) == .orderedSame
                && $0.type == .story
                && $0.createdAt >= since
        }
    }

    func activeStoryHandles(limit: Int = 18) -> [String] {
        var ordered: [String] = []
        func appendHandle(_ handle: String) {
            guard !handle.isEmpty else { return }
            if !ordered.contains(where: { $0.caseInsensitiveCompare(handle) == .orderedSame }) {
                ordered.append(handle)
            }
        }

        appendHandle(currentUser.handle)
        activeFollowingHandles.sorted().forEach(appendHandle(_:))
        internalUsers.map(\.handle).forEach(appendHandle(_:))
        posts.filter { $0.type == .story }.map(\.authorHandle).forEach(appendHandle(_:))

        let active = ordered.filter { hasActiveStory(for: $0) }
        let unseen = active.filter { !hasSeenStory(handle: $0) }
        let seen = active.filter { hasSeenStory(handle: $0) }
        return Array((unseen + seen).prefix(max(1, limit)))
    }

    func activeStoryPosts(for handle: String, limit: Int = 8) -> [PostItem] {
        let since = Date().addingTimeInterval(-24 * 3600)
        let items = posts.filter {
            $0.authorHandle.caseInsensitiveCompare(handle) == .orderedSame
                && $0.type == .story
                && $0.createdAt >= since
        }
        return Array(items.sorted { $0.createdAt > $1.createdAt }.prefix(max(1, limit)))
    }

    @discardableResult
    func createVideoBubbleFromLatestStory(sectionTitle: String) -> Bool {
        let mine = posts
            .filter { $0.authorHandle.caseInsensitiveCompare(currentUser.handle) == .orderedSame && $0.type == .story }
            .sorted { $0.createdAt > $1.createdAt }
        guard let latest = mine.first else { return false }
        _ = publishPost(
            caption: "Video bubble • \(sectionTitle): \(latest.caption)",
            type: .reel,
            imageData: latest.imageData,
            videoData: latest.videoData,
            storyAudience: .public,
            audience: .public,
            isCollab: latest.isCollab,
            areLikesHidden: false,
            areCommentsHidden: false,
            blockNudity: true,
            surfaceStyle: .chit,
            taggedHandles: latest.taggedHandles,
            combinedOwnerHandle: latest.combinedOwnerHandle
        )
        return true
    }

    func markStorySeen(handle: String) {
        let normalized = handle.lowercased()
        guard !normalized.isEmpty else { return }
        seenStoryHandles.insert(normalized)
        saveSeenStoryHandles()
    }

    func hasSeenStory(handle: String) -> Bool {
        seenStoryHandles.contains(handle.lowercased())
    }

    private func mediaData(for handle: String, map: [String: Data]) -> Data? {
        if let known = internalUsers.first(where: { $0.handle.caseInsensitiveCompare(handle) == .orderedSame }) {
            return map[known.username.lowercased()]
        }
        let normalized = handle.replacingOccurrences(of: "@", with: "").lowercased()
        guard !normalized.isEmpty else { return nil }
        return map[normalized]
    }

    private func refreshCurrentProfileMedia() {
        let key = currentUser.username.lowercased()
        profilePhotoData = profilePhotoByUsername[key] ?? nil
        profileGIFData = profileGIFByUsername[key] ?? nil
        profileLoopVideoData = profileLoopVideoByUsername[key] ?? nil
        profileStoryImageData = profileStoryImageByUsername[key] ?? nil
        profileStoryVideoData = profileStoryVideoByUsername[key] ?? nil
        profileStoryGIFData = profileStoryGIFByUsername[key] ?? nil
        currentUser.profileQuote = UserDefaults.standard.string(forKey: profileQuoteStorageKey) ?? currentUser.profileQuote
        if UserDefaults.standard.object(forKey: profileQuoteVisibilityStorageKey) != nil {
            currentUser.isProfileQuoteVisible = UserDefaults.standard.bool(forKey: profileQuoteVisibilityStorageKey)
        }
    }

    var superFeatureCatalog: [SuperFeatureBlueprint] {
        SuperFeatureCatalog.generateFeatures()
    }

    var enabledSuperFeatureCount: Int {
        enabledSuperFeatureIDs.count
    }

    func isFeatureEnabled(_ featureID: String) -> Bool {
        enabledSuperFeatureIDs.contains(featureID)
    }

    func toggleSuperFeature(_ featureID: String) {
        if enabledSuperFeatureIDs.contains(featureID) {
            enabledSuperFeatureIDs.remove(featureID)
        } else {
            enabledSuperFeatureIDs.insert(featureID)
        }
        saveSuperFeatureSelection()
    }

    func enableAllSuperFeatures() {
        enabledSuperFeatureIDs = Set(superFeatureCatalog.map(\.id))
        saveSuperFeatureSelection()
    }

    func enableTopSuperFeatures(_ count: Int) {
        let ranked = superFeatureCatalog
            .sorted(by: { $0.score > $1.score })
            .prefix(max(1, count))
            .map(\.id)
        enabledSuperFeatureIDs.formUnion(ranked)
        saveSuperFeatureSelection()
    }

    func masterExecutionQueue(limit: Int = 1000) -> [ExecutionQueueItem] {
        let catalog = superFeatureCatalog
            .sorted { lhs, rhs in
                if lhs.score == rhs.score { return lhs.id < rhs.id }
                return lhs.score > rhs.score
            }
            .prefix(max(1, limit))
        return catalog.enumerated().map { index, feature in
            ExecutionQueueItem(
                id: feature.id,
                order: index + 1,
                title: feature.title,
                summary: feature.summary,
                status: completedExecutionQueueIDs.contains(feature.id) ? .completed : .pending
            )
        }
    }

    func toggleExecutionQueueItem(_ id: String) {
        if completedExecutionQueueIDs.contains(id) {
            if executionQueueLockCompleted { return }
            completedExecutionQueueIDs.remove(id)
        } else {
            completedExecutionQueueIDs.insert(id)
        }
        saveExecutionQueueProgress()
    }

    func markTopExecutionItemsComplete(_ count: Int) {
        let pending = masterExecutionQueue(limit: 1000)
            .filter { $0.status == .pending }
            .prefix(max(1, count))
            .map(\.id)
        completedExecutionQueueIDs.formUnion(pending)
        saveExecutionQueueProgress()
    }

    func markAllExecutionItemsComplete() {
        let allIDs = masterExecutionQueue(limit: 1000).map(\.id)
        completedExecutionQueueIDs = Set(allIDs)
        saveExecutionQueueProgress()
    }

    func captureExecutionCompletionSnapshot() {
        let total = 1000
        let completed = masterExecutionQueue(limit: total).filter { $0.status == .completed }.count
        let percent = (Double(completed) / Double(total)) * 100.0
        executionCompletionSnapshots.insert(
            ExecutionCompletionSnapshot(
                id: UUID(),
                createdAt: Date(),
                completedCount: completed,
                totalCount: total,
                completionPercent: percent
            ),
            at: 0
        )
        if executionCompletionSnapshots.count > 120 {
            executionCompletionSnapshots = Array(executionCompletionSnapshots.prefix(120))
        }
        saveExecutionQueueSnapshots()
    }

    func executionCompletionCSV() -> String {
        let header = "created_at,completed,total,percent"
        let rows = executionCompletionSnapshots.map { snap in
            let stamp = ISO8601DateFormatter().string(from: snap.createdAt)
            return "\(stamp),\(snap.completedCount),\(snap.totalCount),\(String(format: "%.2f", snap.completionPercent))"
        }
        return ([header] + rows).joined(separator: "\n")
    }

    func executionDeltaSummary() -> ExecutionDeltaSummary {
        guard let latest = executionCompletionSnapshots.first else {
            return ExecutionDeltaSummary(latestCompleted: 0, previousCompleted: 0, deltaCompleted: 0, latestPercent: 0)
        }
        let previous = executionCompletionSnapshots.dropFirst().first
        let previousCount = previous?.completedCount ?? 0
        return ExecutionDeltaSummary(
            latestCompleted: latest.completedCount,
            previousCompleted: previousCount,
            deltaCompleted: latest.completedCount - previousCount,
            latestPercent: latest.completionPercent
        )
    }

    func setExecutionQueueLock(_ enabled: Bool) {
        executionQueueLockCompleted = enabled
        saveExecutionQueueSettings()
    }

    func captureExecutionCompletionSnapshotIfNeededDaily() {
        let todayKey = currentDayKey()
        if lastExecutionSnapshotDayKey() == todayKey { return }
        captureExecutionCompletionSnapshot()
        saveLastExecutionSnapshotDayKey(todayKey)
    }

    func executionSnapshotStreakDays() -> Int {
        let orderedDays = executionCompletionSnapshots
            .map { dayKey(from: $0.createdAt) }
        guard !orderedDays.isEmpty else { return 0 }
        var uniqueDays: [String] = []
        var seen = Set<String>()
        for key in orderedDays {
            if !seen.contains(key) {
                seen.insert(key)
                uniqueDays.append(key)
            }
        }
        guard !uniqueDays.isEmpty else { return 0 }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        guard let firstDay = formatter.date(from: uniqueDays[0]) else { return 0 }
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let firstStart = calendar.startOfDay(for: firstDay)
        let startsFromTodayOrYesterday = calendar.isDate(firstStart, inSameDayAs: todayStart)
            || calendar.isDate(firstStart, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: todayStart) ?? todayStart)
        guard startsFromTodayOrYesterday else { return 0 }
        var streak = 1
        var previousDay = firstStart
        for key in uniqueDays.dropFirst() {
            guard let day = formatter.date(from: key) else { continue }
            let dayStart = calendar.startOfDay(for: day)
            let diff = calendar.dateComponents([.day], from: dayStart, to: previousDay).day ?? 0
            if diff == 1 {
                streak += 1
                previousDay = dayStart
            } else if diff == 0 {
                continue
            } else {
                break
            }
        }
        return streak
    }

    func createExecutionQueueRestorePoint(label: String? = nil) {
        let normalizedLabel = label?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let snapshot = ExecutionQueueRestorePoint(
            createdAt: Date(),
            completedIDs: Array(completedExecutionQueueIDs),
            completedCount: completedExecutionQueueIDs.count,
            label: normalizedLabel.isEmpty ? "Manual Restore Point" : normalizedLabel
        )
        executionQueueRestorePoint = snapshot
        saveExecutionQueueRestorePoint()
    }

    @discardableResult
    func restoreExecutionQueueFromRestorePoint() -> Bool {
        guard let point = executionQueueRestorePoint else { return false }
        completedExecutionQueueIDs = Set(point.completedIDs)
        saveExecutionQueueProgress()
        captureExecutionCompletionSnapshot()
        return true
    }

    func clearExecutionQueueRestorePoint() {
        executionQueueRestorePoint = nil
        saveExecutionQueueRestorePoint()
    }

    @discardableResult
    func markExecutionRangeComplete(start: Int, end: Int) -> Int {
        let lower = max(1, min(start, end))
        let upper = max(1, max(start, end))
        let ids = masterExecutionQueue(limit: 1000)
            .filter { $0.order >= lower && $0.order <= upper && $0.status == .pending }
            .map(\.id)
        completedExecutionQueueIDs.formUnion(ids)
        saveExecutionQueueProgress()
        return ids.count
    }

    func pendingExecutionRanges(chunkSize: Int = 50, maxRanges: Int = 8) -> [(start: Int, end: Int)] {
        let pendingOrders = masterExecutionQueue(limit: 1000)
            .filter { $0.status == .pending }
            .map(\.order)
        guard !pendingOrders.isEmpty else { return [] }
        var ranges: [(Int, Int)] = []
        var index = 0
        let normalizedChunk = max(1, chunkSize)
        while index < pendingOrders.count && ranges.count < maxRanges {
            let start = pendingOrders[index]
            let endIndex = min(index + normalizedChunk - 1, pendingOrders.count - 1)
            let end = pendingOrders[endIndex]
            ranges.append((start, end))
            index = endIndex + 1
        }
        return ranges
    }

    func executionQueueCSV(limit: Int = 1000) -> String {
        let header = "order,id,title,summary,status"
        let rows = masterExecutionQueue(limit: limit).map { item in
            "\"\(item.order)\",\"\(item.id)\",\"\(item.title)\",\"\(item.summary)\",\"\(item.status.rawValue)\""
        }
        return ([header] + rows).joined(separator: "\n")
    }

    func follow(_ handle: String) {
        guard handle != currentUser.handle else { return }
        guard !blockedHandles.contains(handle.lowercased()) else { return }
        if mode == .enterprise {
            enterpriseFollowingHandles.insert(handle)
        } else {
            followingHandles.insert(handle)
            socialGraph[currentUser.handle, default: []].insert(handle)
        }
        addActivity(type: .follow, detail: "You followed \(handle).")
        // Optional soft follow-back behavior to mimic real social dynamics.
        if Bool.random(), Int.random(in: 0...100) < 35 {
            if mode == .enterprise {
                enterpriseFollowerHandles.insert(handle)
            } else {
                followerHandles.insert(handle)
            }
        }
    }

    func unfollow(_ handle: String) {
        if mode == .enterprise {
            enterpriseFollowingHandles.remove(handle)
        } else {
            followingHandles.remove(handle)
            socialGraph[currentUser.handle]?.remove(handle)
        }
    }

    func suggestedConnections(limit: Int = 10) -> [SuggestedConnection] {
        let myFollowing = socialGraph[currentUser.handle, default: []].union(activeFollowingHandles)
        let friendsOfFriendHandles: Set<String> = Set(myFollowing.flatMap { socialGraph[$0, default: []] })
            .subtracting([currentUser.handle])
            .subtracting(myFollowing)

        let candidates = internalUsers.filter {
            $0.handle != currentUser.handle
            && !myFollowing.contains($0.handle)
            && !isBlocked($0.handle)
        }

        let suggestions = candidates.map { user in
            let userFollowing = socialGraph[user.handle, default: []]
            let mutual = myFollowing.intersection(userFollowing).count
            let contact = matchedContactHandles.contains(user.handle)
            let fof = friendsOfFriendHandles.contains(user.handle)
            let networks = user.linkedPlatforms.filter { currentUser.linkedPlatforms.contains($0) }.count
            return SuggestedConnection(
                user: user,
                mutualCount: mutual,
                matchedFromContacts: contact,
                friendsOfFriends: fof,
                sharedNetworksCount: networks
            )
        }
        .sorted { lhs, rhs in
            if lhs.matchedFromContacts != rhs.matchedFromContacts {
                return lhs.matchedFromContacts && !rhs.matchedFromContacts
            }
            if lhs.friendsOfFriends != rhs.friendsOfFriends {
                return lhs.friendsOfFriends && !rhs.friendsOfFriends
            }
            if lhs.mutualCount != rhs.mutualCount {
                return lhs.mutualCount > rhs.mutualCount
            }
            if lhs.sharedNetworksCount != rhs.sharedNetworksCount {
                return lhs.sharedNetworksCount > rhs.sharedNetworksCount
            }
            return lhs.user.followers > rhs.user.followers
        }

        return Array(suggestions.prefix(limit))
    }

    func syncContacts(displayNames: [String], identifiers: [String], contactPhones: [String] = []) {
        let lowered = displayNames.map { $0.lowercased() }
        let phoneSet = Set(contactPhones.map { phoneNormalizedLast10($0) }.filter { $0.count == 10 })

        var handles = Set(
            internalUsers.filter { user in
                user.handle != currentUser.handle
                    && lowered.contains(where: { contact in
                        user.displayName.lowercased() == contact
                            || user.username.lowercased() == contact
                            || user.handle.lowercased().contains(contact)
                    })
            }.map(\.handle)
        )

        if !phoneSet.isEmpty {
            for user in internalUsers where user.handle != currentUser.handle {
                let uDigits = user.username.filter(\.isNumber)
                if uDigits.count >= 10, phoneSet.contains(String(uDigits.suffix(10))) {
                    handles.insert(user.handle)
                }
            }
        }

        matchedContactHandles = handles
        let count = handles.count
        contactsSyncStatus = count == 0
            ? "No matching contacts found in Chit Chat Social yet."
            : "Found \(count) contacts on Chit Chat Social."
    }

    private func phoneNormalizedLast10(_ raw: String) -> String {
        let d = raw.filter(\.isNumber)
        guard !d.isEmpty else { return "" }
        return String(d.suffix(10))
    }

    var activeFollowingHandles: Set<String> {
        mode == .enterprise ? enterpriseFollowingHandles : followingHandles
    }

    var activeFollowerHandles: Set<String> {
        let raw = mode == .enterprise ? enterpriseFollowerHandles : followerHandles
        return Set(raw.filter { !isBlocked($0) })
    }

    func isFollowing(_ handle: String) -> Bool {
        activeFollowingHandles.contains(handle)
    }

    func removeFollower(_ handle: String) {
        if mode == .enterprise {
            enterpriseFollowerHandles.remove(handle)
        } else {
            followerHandles.remove(handle)
        }
    }

    func blockHandle(_ handle: String) {
        let key = handle.lowercased()
        blockedHandles.insert(key)
        followingHandles.remove(handle)
        followerHandles.remove(handle)
        enterpriseFollowingHandles.remove(handle)
        enterpriseFollowerHandles.remove(handle)
        addActivity(
            type: .moderation,
            detail: "You blocked \(handle). Their posts are removed from your feed immediately. Our team reviews safety reports within 24 hours."
        )
        moderationEvents.insert("Block reported to safety queue: \(handle)", at: 0)
    }

    /// Report objectionable UGC (Guideline 1.2).
    func reportUserContent(postID: UUID, authorHandle: String, reason: String) {
        var existing: [UserContentReport] = []
        if let data = UserDefaults.standard.data(forKey: userContentReportsStorageKey),
           let decoded = try? JSONDecoder().decode([UserContentReport].self, from: data) {
            existing = decoded
        }
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        let r = UserContentReport(
            id: UUID(),
            postID: postID,
            reporterHandle: currentUser.handle,
            authorHandle: authorHandle,
            reason: trimmed.isEmpty ? "(no details)" : trimmed,
            createdAt: Date()
        )
        userContentReports = [r] + existing
        if let data = try? JSONEncoder().encode(userContentReports) {
            UserDefaults.standard.set(data, forKey: userContentReportsStorageKey)
        }
        addActivity(
            type: .moderation,
            detail: "Thanks — your report was sent. We review objectionable content within 24 hours."
        )
        moderationEvents.insert("User report: \(authorHandle) post \(postID.uuidString.prefix(8))…", at: 0)
    }

    func unblockHandle(_ handle: String) {
        blockedHandles.remove(handle.lowercased())
    }

    func isBlocked(_ handle: String) -> Bool {
        blockedHandles.contains(handle.lowercased())
    }

    func hideTaggedPost(_ postID: UUID) {
        hiddenTaggedPostIDs.insert(postID)
    }

    func unhideTaggedPost(_ postID: UUID) {
        hiddenTaggedPostIDs.remove(postID)
    }

    func unhideAllTaggedPosts() {
        hiddenTaggedPostIDs.removeAll()
    }

    var followingCount: Int { activeFollowingHandles.count }
    var followersCount: Int { activeFollowerHandles.count }
    var archivedPosts: [PostItem] { posts.filter(\.isArchived) }
    var isUsingLiveDataBackend: Bool { !(backend is LocalBackendService) }
    var backendStatusLabel: String {
        isUsingLiveDataBackend ? "Live backend connected" : "Local demo backend (offline-first)"
    }

    func feedPosts(isFollowingOnly: Bool, sortMode: FeedSortMode = .latest) -> [PostItem] {
        let visible = posts.filter { !($0.isArchived) && canViewPost($0) }
            .filter { !isBlocked($0.authorHandle) }
            .filter { post in
                if mode == .social && post.authorHandle.caseInsensitiveCompare(currentUser.handle) == .orderedSame {
                    return socialProfileVisible
                }
                if mode == .enterprise && post.authorHandle.caseInsensitiveCompare(currentUser.handle) == .orderedSame {
                    return corporateProfileVisible
                }
                return true
            }
        let scoped: [PostItem]
        if isFollowingOnly {
            scoped = visible.filter { activeFollowingHandles.contains($0.authorHandle) || $0.authorHandle == currentUser.handle }
        } else {
            let cityKey = localCity.trimmingCharacters(in: .whitespacesAndNewlines)
            if cityKey.isEmpty {
                scoped = visible
            } else {
                scoped = visible.filter { post in
                    post.city.caseInsensitiveCompare(cityKey) == .orderedSame
                        || (nativeSponsoredFeedEnabled && post.isSponsoredAd)
                }
            }
        }
        let tuned = scoped.sorted { interestMatchScore(for: $0) > interestMatchScore(for: $1) }
        return sortFeed(tuned, sortMode: sortMode)
    }

    func closeFriendsFeedPosts(sortMode: FeedSortMode = .latest) -> [PostItem] {
        let scoped = posts.filter { post in
            !post.isArchived
            && canViewPost(post)
            && !isBlocked(post.authorHandle)
            && (closeFriendsHandles.contains(post.authorHandle) || post.authorHandle == currentUser.handle)
        }
        return sortFeed(scoped, sortMode: sortMode)
    }

    private func interestMatchScore(for post: PostItem) -> Double {
        let tokens = activeInterests
        let haystack = "\(post.caption) \(post.city) \(post.authorHandle) \(post.type.rawValue) \(post.sponsorBrandHandle)".lowercased()
        let hits = tokens.filter { haystack.contains($0) }.count
        var score = Double(hits) * 5.0
        if nativeSponsoredFeedEnabled && post.isSponsoredAd { score += 3.0 }
        return score
    }

    private func sortFeed(_ items: [PostItem], sortMode: FeedSortMode) -> [PostItem] {
        switch sortMode {
        case .latest:
            return items.sorted { $0.createdAt > $1.createdAt }
        case .trending:
            return items.sorted { engagementScore(for: $0) > engagementScore(for: $1) }
        case .rising:
            return items.sorted { risingScore(for: $0) > risingScore(for: $1) }
        }
    }

    private func engagementScore(for post: PostItem) -> Double {
        (Double(post.likeCount) * rankingLikeWeight)
            + (Double(post.commentCount) * rankingCommentWeight)
            + (Double(post.repostCount) * rankingRepostWeight)
            + (Double(post.saveCount) * rankingSaveWeight)
    }

    private func risingScore(for post: PostItem) -> Double {
        let hours = max(1, Date().timeIntervalSince(post.createdAt) / 3600.0)
        return engagementScore(for: post) / pow(hours, rankingFreshnessPower)
    }

    func addLike(to postID: UUID) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        let current = engagementUser(for: currentUser.handle)
        let alreadyLiked = likesByPost[postID, default: []].contains {
            $0.handle.caseInsensitiveCompare(current.handle) == .orderedSame
        }
        guard !alreadyLiked else { return }
        likesByPost[postID, default: []].append(current)
        posts[index].likeCount = max(posts[index].likeCount + 1, likesByPost[postID]?.count ?? 0)
        addActivity(type: .like, detail: "You liked \(posts[index].authorHandle)'s post.")
        saveEngagementState()
    }

    /// Reels / heart control: unlike if already liked, otherwise like.
    func toggleLike(on postID: UUID) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        let current = engagementUser(for: currentUser.handle)
        var likes = likesByPost[postID, default: []]
        if let idx = likes.firstIndex(where: { $0.handle.caseInsensitiveCompare(current.handle) == .orderedSame }) {
            likes.remove(at: idx)
            likesByPost[postID] = likes
        } else {
            likes.append(current)
            likesByPost[postID] = likes
            addActivity(type: .like, detail: "You liked \(posts[index].authorHandle)'s post.")
        }
        posts[index].likeCount = max(0, likes.count)
        saveEngagementState()
    }

    func setPostReaction(postID: UUID, emoji: String) {
        reactionByPost[postID] = emoji
    }

    func reaction(for postID: UUID) -> String? {
        reactionByPost[postID]
    }

    func creatorMomentumScore() -> Int {
        let my = posts.filter { $0.authorHandle.caseInsensitiveCompare(currentUser.handle) == .orderedSame }
        guard !my.isEmpty else { return 0 }
        let weighted = my.reduce(0) { partial, post in
            partial + (post.likeCount * 2) + (post.commentCount * 3) + (post.repostCount * 4) + (post.saveCount * 2)
        }
        let freshness = max(1, my.filter { $0.createdAt > Date().addingTimeInterval(-7 * 24 * 3600) }.count * 12)
        return min(999, (weighted / max(1, my.count)) + freshness)
    }

    func addComment(to postID: UUID) {
        _ = addComment(to: postID, text: "New comment")
    }

    @discardableResult
    func addComment(to postID: UUID, text: String) -> Bool {
        clearExpiredPolicyBanIfNeeded()
        if isPolicySuspendedNow {
            addActivity(type: .moderation, detail: "Comment not posted — account suspended for policy violations.")
            return false
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let mod = ModerationService.evaluate(caption: trimmed, blockNudity: true)
        guard mod.label == .safe else {
            if mod.label == .blockedNudity {
                handleBlockedNudityViolation(source: "comment", textSnippet: trimmed)
            } else {
                addActivity(type: .moderation, detail: "Comment not posted — \(mod.reason)")
            }
            return false
        }
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return false }
        let created = PostComment(
            id: UUID(),
            postID: postID,
            authorHandle: currentUser.handle,
            text: trimmed,
            createdAt: Date()
        )
        commentsByPost[postID, default: []].append(created)
        posts[index].commentCount = commentsByPost[postID]?.count ?? 0
        addActivity(type: .comment, detail: "You commented on \(posts[index].authorHandle)'s post.")
        saveEngagementState()
        return true
    }

    func comments(for postID: UUID) -> [PostComment] {
        (commentsByPost[postID] ?? []).sorted { $0.createdAt > $1.createdAt }
    }

    func updateComment(postID: UUID, commentID: UUID, text: String) {
        guard let postIndex = posts.firstIndex(where: { $0.id == postID }) else { return }
        guard let commentIndex = commentsByPost[postID]?.firstIndex(where: { $0.id == commentID }) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let mod = ModerationService.evaluate(caption: trimmed, blockNudity: true)
        guard mod.label == .safe else {
            if mod.label == .blockedNudity {
                handleBlockedNudityViolation(source: "comment_edit", textSnippet: trimmed)
            } else {
                addActivity(type: .moderation, detail: "Comment edit rejected — \(mod.reason)")
            }
            return
        }
        commentsByPost[postID]?[commentIndex].text = trimmed
        posts[postIndex].commentCount = commentsByPost[postID]?.count ?? 0
        saveEngagementState()
    }

    func deleteComment(postID: UUID, commentID: UUID) {
        guard let postIndex = posts.firstIndex(where: { $0.id == postID }) else { return }
        commentsByPost[postID]?.removeAll { $0.id == commentID }
        posts[postIndex].commentCount = commentsByPost[postID]?.count ?? 0
        saveEngagementState()
    }

    func toggleSavedPost(_ postID: UUID) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else {
            saveSavedPosts()
            return
        }
        if savedPostIDs.contains(postID) {
            savedPostIDs.remove(postID)
            posts[index].saveCount = max(0, posts[index].saveCount - 1)
        } else {
            savedPostIDs.insert(postID)
            posts[index].saveCount += 1
            if let post = posts.first(where: { $0.id == postID }) {
                addActivity(type: .save, detail: "Saved post from \(post.authorHandle).")
            }
        }
        saveSavedPosts()
        saveEngagementState()
    }

    func repostPost(_ postID: UUID) {
        clearExpiredPolicyBanIfNeeded()
        if isPolicySuspendedNow {
            addActivity(type: .moderation, detail: "Repost blocked — account suspended.")
            return
        }
        guard let source = posts.first(where: { $0.id == postID }) else { return }
        guard let sourceIndex = posts.firstIndex(where: { $0.id == postID }) else { return }
        let current = engagementUser(for: currentUser.handle)
        let alreadyReposted = repostsByPost[postID, default: []].contains {
            $0.handle.caseInsensitiveCompare(current.handle) == .orderedSame
        }
        let firstTimeRepost = !alreadyReposted
        let caption = firstTimeRepost
            ? "Reposted from \(source.authorHandle): \(source.caption)"
            : "Re-shared from \(source.authorHandle): \(source.caption)"
        let mod = ModerationService.evaluate(caption: caption, blockNudity: true)
        switch mod.label {
        case .blockedNudity:
            handleBlockedNudityViolation(source: "repost", textSnippet: caption)
            return
        case .manualReview, .accountSuspended, .missingRequiredMedia, .sponsoredNotEligible:
            addActivity(type: .moderation, detail: "Repost not allowed — \(mod.reason)")
            return
        case .safe, .violenceNeedsConsent:
            break
        }
        if firstTimeRepost {
            repostsByPost[postID, default: []].append(current)
            posts[sourceIndex].repostCount = max(posts[sourceIndex].repostCount + 1, repostsByPost[postID]?.count ?? 0)
        }
        let violence = mod.label == .violenceNeedsConsent || source.violenceWarningRequired
        let reposted = PostItem(
            id: UUID(),
            authorHandle: currentUser.handle,
            caption: caption,
            type: source.type == .reel || source.type == .shortVideo ? source.type : .post,
            createdAt: Date(),
            city: localCity,
            imageData: source.imageData,
            videoData: source.videoData,
            likeCount: 0,
            commentCount: 0,
            areLikesHidden: false,
            areCommentsHidden: false,
            isArchived: false,
            repostCount: 0,
            saveCount: 0,
            storyAudience: .public,
            audience: .public,
            isCollab: false,
            surfaceStyle: source.surfaceStyle,
            taggedHandles: source.taggedHandles,
            combinedOwnerHandle: source.combinedOwnerHandle,
            violenceWarningRequired: violence
        )
        posts.insert(reposted, at: 0)
        addActivity(type: .repost, detail: firstTimeRepost ? "Reposted \(source.authorHandle)'s post." : "Re-shared \(source.authorHandle)'s post.")
        saveEngagementState()
    }

    /// Paid reshare: same media as the source post, disclosure in caption, tap-through to the paying brand.
    func sponsoredRepostPost(_ postID: UUID, sponsorBrandHandle rawBrand: String, sponsorExternalURL: String = "") {
        clearExpiredPolicyBanIfNeeded()
        if isPolicySuspendedNow {
            addActivity(type: .moderation, detail: "Sponsored repost blocked — account suspended.")
            return
        }
        guard canRunPaidAds else {
            addActivity(
                type: .moderation,
                detail: "Sponsored repost blocked — enable Ad account (or business) and ensure branded promos are on for your build."
            )
            return
        }
        let brand = normalizedSponsorHandle(rawBrand)
        guard !brand.isEmpty else {
            addActivity(type: .moderation, detail: "Add a brand handle for sponsored reposts.")
            return
        }
        guard let source = posts.first(where: { $0.id == postID }) else { return }
        guard let sourceIndex = posts.firstIndex(where: { $0.id == postID }) else { return }
        let current = engagementUser(for: currentUser.handle)
        let alreadyReposted = repostsByPost[postID, default: []].contains {
            $0.handle.caseInsensitiveCompare(current.handle) == .orderedSame
        }
        let firstTimeRepost = !alreadyReposted
        let caption = """
        Sponsored · \(brand)

        Repost of \(source.authorHandle): \(source.caption)

        #ad
        """
        let mod = ModerationService.evaluate(caption: caption, blockNudity: true)
        switch mod.label {
        case .blockedNudity:
            handleBlockedNudityViolation(source: "sponsored_repost", textSnippet: caption)
            return
        case .manualReview, .accountSuspended, .missingRequiredMedia, .sponsoredNotEligible:
            addActivity(type: .moderation, detail: "Sponsored repost not allowed — \(mod.reason)")
            return
        case .safe, .violenceNeedsConsent:
            break
        }
        if firstTimeRepost {
            repostsByPost[postID, default: []].append(current)
            posts[sourceIndex].repostCount = max(posts[sourceIndex].repostCount + 1, repostsByPost[postID]?.count ?? 0)
        }
        let violence = mod.label == .violenceNeedsConsent || source.violenceWarningRequired
        let trimmedURL = sponsorExternalURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let wrapped = PostItem(
            id: UUID(),
            authorHandle: currentUser.handle,
            caption: caption,
            type: source.type == .reel || source.type == .shortVideo ? source.type : .post,
            createdAt: Date(),
            city: localCity,
            imageData: source.imageData,
            videoData: source.videoData,
            likeCount: 0,
            commentCount: 0,
            areLikesHidden: false,
            areCommentsHidden: false,
            isArchived: false,
            repostCount: 0,
            saveCount: 0,
            storyAudience: .public,
            audience: .public,
            isCollab: false,
            surfaceStyle: source.surfaceStyle,
            taggedHandles: source.taggedHandles,
            combinedOwnerHandle: source.combinedOwnerHandle,
            violenceWarningRequired: violence,
            isSponsoredAd: true,
            sponsorBrandHandle: brand,
            sponsorExternalURL: trimmedURL,
            sponsoredSourcePostID: postID
        )
        posts.insert(wrapped, at: 0)
        addActivity(
            type: .repost,
            detail: firstTimeRepost
                ? "Sponsored repost for \(brand) · original \(source.authorHandle)."
                : "Sponsored re-share for \(brand)."
        )
        saveEngagementState()
        Task {
            try? await backend.syncPost(wrapped)
        }
    }

    func quotePost(_ postID: UUID, commentary: String, surfaceStyle: PostSurfaceStyle = .chat) {
        clearExpiredPolicyBanIfNeeded()
        if isPolicySuspendedNow {
            addActivity(type: .moderation, detail: "Quote blocked — account suspended.")
            return
        }
        guard let source = posts.first(where: { $0.id == postID }) else { return }
        let trimmed = commentary.trimmingCharacters(in: .whitespacesAndNewlines)
        let quoteLead = trimmed.isEmpty ? "Quote repost" : trimmed
        let caption = "\(quoteLead)\n\n\"\(source.caption)\" — \(source.authorHandle)"
        let mod = ModerationService.evaluate(caption: caption, blockNudity: true)
        switch mod.label {
        case .blockedNudity:
            handleBlockedNudityViolation(source: "quote", textSnippet: caption)
            return
        case .manualReview, .accountSuspended, .missingRequiredMedia, .sponsoredNotEligible:
            addActivity(type: .moderation, detail: "Quote not allowed — \(mod.reason)")
            return
        case .safe, .violenceNeedsConsent:
            break
        }
        let violence = mod.label == .violenceNeedsConsent || source.violenceWarningRequired
        let quoted = PostItem(
            id: UUID(),
            authorHandle: currentUser.handle,
            caption: caption,
            type: .post,
            createdAt: Date(),
            city: localCity,
            imageData: surfaceStyle == .chit ? source.imageData : nil,
            likeCount: 0,
            commentCount: 0,
            areLikesHidden: false,
            areCommentsHidden: false,
            isArchived: false,
            repostCount: 0,
            saveCount: 0,
            storyAudience: .public,
            audience: .public,
            isCollab: false,
            surfaceStyle: surfaceStyle,
            violenceWarningRequired: violence
        )
        posts.insert(quoted, at: 0)
        addActivity(type: .repost, detail: "Quoted \(source.authorHandle)'s post.")
        saveEngagementState()
    }

    func replyToPost(_ postID: UUID, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard addComment(to: postID, text: trimmed) else { return }
        guard let source = posts.first(where: { $0.id == postID }) else { return }
        let caption = "Replying to \(source.authorHandle): \(trimmed)"
        let mod = ModerationService.evaluate(caption: caption, blockNudity: true)
        switch mod.label {
        case .blockedNudity:
            handleBlockedNudityViolation(source: "reply_post", textSnippet: caption)
            return
        case .manualReview, .accountSuspended, .missingRequiredMedia, .sponsoredNotEligible:
            return
        case .safe, .violenceNeedsConsent:
            break
        }
        let violence = mod.label == .violenceNeedsConsent || source.violenceWarningRequired
        let replyPost = PostItem(
            id: UUID(),
            authorHandle: currentUser.handle,
            caption: caption,
            type: .post,
            createdAt: Date(),
            city: localCity,
            imageData: nil,
            likeCount: 0,
            commentCount: 0,
            areLikesHidden: false,
            areCommentsHidden: false,
            isArchived: false,
            repostCount: 0,
            saveCount: 0,
            storyAudience: .public,
            audience: .public,
            isCollab: false,
            surfaceStyle: .chat,
            violenceWarningRequired: violence
        )
        posts.insert(replyPost, at: 0)
    }

    func togglePinPost(_ postID: UUID) {
        if pinnedPostIDs.contains(postID) {
            pinnedPostIDs.remove(postID)
        } else {
            pinnedPostIDs.insert(postID)
        }
    }

    func isPostPinned(_ postID: UUID) -> Bool {
        pinnedPostIDs.contains(postID)
    }

    func aiPolishCaption(_ text: String, surfaceStyle: PostSurfaceStyle) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return surfaceStyle == .chat ? "Quick thought drop. Staying consistent and shipping daily." : "Fresh visual drop. Building daily momentum."
        }
        if surfaceStyle == .chat {
            return "\(trimmed)\n\n#ChitChatSocial #Conversation"
        }
        return "\(trimmed)\n\n#Chit #CreatorMode"
    }

    func suggestedAffiliateLink(from text: String) -> String {
        let lowered = text.lowercased()
        if lowered.contains("shoe") || lowered.contains("sneaker") {
            return "https://shop.chitchat.app/affiliate/sneaker-drop"
        }
        if lowered.contains("music") || lowered.contains("song") {
            return "https://shop.chitchat.app/affiliate/music-kit"
        }
        if lowered.contains("podcast") || lowered.contains("mic") {
            return "https://shop.chitchat.app/affiliate/podcast-starter"
        }
        if lowered.contains("fitness") || lowered.contains("gym") {
            return "https://shop.chitchat.app/affiliate/fit-edge"
        }
        return "https://shop.chitchat.app/affiliate/creator-tools"
    }

    func monetizationInsights() -> MonetizationInsights {
        let mine = posts.filter { $0.authorHandle == currentUser.handle && !$0.isArchived }
        let sponsored = mine.filter {
            $0.isSponsoredAd
                || $0.caption.localizedCaseInsensitiveContains("http://")
                || $0.caption.localizedCaseInsensitiveContains("https://")
                || $0.caption.localizedCaseInsensitiveContains("#ad")
                || $0.caption.localizedCaseInsensitiveContains("#sponsored")
        }
        let estimatedReach = mine.reduce(0) { partial, post in
            partial + post.likeCount + (post.commentCount * 2) + (post.repostCount * 3)
        }
        let revenue = (Double(estimatedReach) * 0.012) + (Double(sponsored.count) * 14.0)
        return MonetizationInsights(
            sponsoredPosts: sponsored.count,
            estimatedReach: estimatedReach,
            estimatedRevenueUSD: revenue
        )
    }

    func payoutForecast() -> PayoutForecast {
        let insight = monetizationInsights()
        let boostFactor = 1.0 + (creatorBoostBudgetUSD / 1000.0)
        let monetizationFactor = creatorMonetizationEnabled ? 1.18 : 0.92
        let baseDay = max(2.0, insight.estimatedRevenueUSD / 7.0)
        let nextDay = baseDay * boostFactor * monetizationFactor
        let nextWeek = nextDay * 7.0 * 1.04
        let nextMonth = nextDay * 30.0 * 1.12
        return PayoutForecast(
            nextDayUSD: nextDay,
            nextWeekUSD: nextWeek,
            nextMonthUSD: nextMonth
        )
    }

    func monetizationStrategyCards() -> [MonetizationStrategyCard] {
        let insights = monetizationInsights()
        let momentum = creatorMomentumScore()
        let cardA = MonetizationStrategyCard(
            id: UUID(),
            title: "Scale Sponsored Mix",
            action: insights.sponsoredPosts < 3 ? "Publish 2 sponsored posts this week with clear CTA links." : "Sustain sponsored cadence and optimize click-through copy.",
            targetMetric: "Target: +\(max(6, 18 - insights.sponsoredPosts * 2))% revenue next week"
        )
        let cardB = MonetizationStrategyCard(
            id: UUID(),
            title: "Boost High Momentum Posts",
            action: "Allocate boost budget to posts with strongest early comments/reposts.",
            targetMetric: "Momentum score: \(momentum) • Goal: 600+"
        )
        let cardC = MonetizationStrategyCard(
            id: UUID(),
            title: "Live Commerce Conversion",
            action: isLiveNow ? "Pin one product and drop timed offers every 4 minutes." : "Go live this week and run a 15-minute offer sequence.",
            targetMetric: "Goal: +12% shop conversion rate"
        )
        return [cardA, cardB, cardC]
    }

    func recommendedPostingWindow(for surface: PostSurfaceStyle) -> String {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: Date())
        let weekday = cal.component(.weekday, from: Date())
        let baseWindow: String
        switch surface {
        case .chit:
            baseWindow = weekday == 1 || weekday == 7 ? "11:00 AM - 1:00 PM" : "7:00 PM - 9:00 PM"
        case .chat:
            baseWindow = hour < 15 ? "12:00 PM - 2:00 PM" : "8:00 PM - 10:00 PM"
        }
        return "\(baseWindow) local (\(localCity))"
    }

    func captionVariants(for base: String, surface: PostSurfaceStyle) -> (a: String, b: String) {
        let trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
        let stem = trimmed.isEmpty ? (surface == .chat ? "Quick update for the community." : "Fresh visual drop for today.") : trimmed
        let variantA = "\(stem)\n\n\(surface == .chat ? "#ChitChatSocial #Discuss" : "#Chit #Create")"
        let variantB = "\(stem) Tap in and share your take.\n\n\(surface == .chat ? "#Conversation #Now" : "#Visual #Trend")"
        return (variantA, variantB)
    }

    func collabMatchSuggestions(limit: Int = 8) -> [CollabMatchSuggestion] {
        let myPosts = posts.filter { $0.authorHandle.caseInsensitiveCompare(currentUser.handle) == .orderedSame }
        let tagged = myPosts.flatMap(\.taggedHandles)
        var counts: [String: Int] = [:]
        for handle in tagged {
            counts[handle, default: 0] += 1
        }
        for post in posts where post.authorHandle.caseInsensitiveCompare(currentUser.handle) != .orderedSame {
            let overlap = post.taggedHandles.contains { tag in
                myPosts.contains { mine in mine.taggedHandles.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) }
            }
            if overlap {
                counts[post.authorHandle, default: 0] += 2
            }
        }
        let ranked = counts.map { (handle, score) in
            CollabMatchSuggestion(
                id: UUID(),
                handle: handle,
                reason: score >= 4 ? "High shared audience overlap" : "Emerging audience overlap",
                score: score
            )
        }
        .sorted { lhs, rhs in
            if lhs.score == rhs.score { return lhs.handle < rhs.handle }
            return lhs.score > rhs.score
        }
        return Array(ranked.prefix(limit))
    }

    func estimateCaptionPerformance(_ caption: String) -> Double {
        let lowered = caption.lowercased()
        var score = 52.0
        if lowered.contains("?") { score += 8.5 }
        if lowered.contains("#") { score += 6.0 }
        if lowered.contains("drop") || lowered.contains("exclusive") { score += 9.0 }
        if lowered.count > 160 { score -= 6.5 }
        if lowered.contains("http://") || lowered.contains("https://") { score += 4.0 }
        return min(99.0, max(8.0, score))
    }

    func schedulePost(
        caption: String,
        publishAt: Date,
        surfaceStyle: PostSurfaceStyle,
        includesImage: Bool,
        cadence: ScheduleCadence = .once,
        priority: Int = 50
    ) {
        let cleaned = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        let plan = ScheduledPostPlan(
            id: UUID(),
            caption: cleaned.isEmpty ? "Scheduled post draft" : cleaned,
            publishAt: publishAt,
            surfaceStyle: surfaceStyle,
            includesImage: includesImage,
            cadence: cadence,
            priority: max(1, min(100, priority))
        )
        scheduledPosts.append(plan)
        scheduledPosts.sort { $0.publishAt < $1.publishAt }
        saveScheduledPosts()
    }

    func publishScheduledPost(_ planID: UUID) {
        guard let idx = scheduledPosts.firstIndex(where: { $0.id == planID }) else { return }
        var plan = scheduledPosts.remove(at: idx)
        if shouldSkipPublishDate(plan.publishAt, skipKeys: plan.skipDateKeys) {
            if let next = nextPublishDate(from: plan.publishAt, cadence: plan.cadence) {
                plan.publishAt = next
                scheduledPosts.append(plan)
                scheduledPosts.sort { $0.publishAt < $1.publishAt }
            }
            saveScheduledPosts()
            return
        }
        saveScheduledPosts()
        let imageData = plan.includesImage ? generatedMediaImageData(seed: "\(currentUser.handle)-scheduled-\(plan.id.uuidString)") : nil
        _ = publishPost(
            caption: plan.caption,
            type: .post,
            imageData: imageData,
            storyAudience: .public,
            audience: .public,
            isCollab: false,
            areLikesHidden: hideLikeCountsByDefault,
            areCommentsHidden: hideCommentCountsByDefault,
            blockNudity: true,
            surfaceStyle: plan.surfaceStyle
        )
        switch plan.cadence {
        case .once:
            break
        case .daily, .weekly, .monthly:
            if let next = nextPublishDate(from: plan.publishAt, cadence: plan.cadence) {
                schedulePost(
                    caption: plan.caption,
                    publishAt: next,
                    surfaceStyle: plan.surfaceStyle,
                    includesImage: plan.includesImage,
                    cadence: plan.cadence,
                    priority: plan.priority
                )
            }
        }
    }

    func processDueScheduledPosts() {
        let dueIDs = scheduledPosts.filter { $0.publishAt <= Date() }.map(\.id)
        for id in dueIDs {
            publishScheduledPost(id)
        }
    }

    func removeScheduledPost(_ planID: UUID) {
        scheduledPosts.removeAll { $0.id == planID }
        saveScheduledPosts()
    }

    func skipNextScheduledOccurrence(_ planID: UUID) {
        guard let index = scheduledPosts.firstIndex(where: { $0.id == planID }) else { return }
        let dateKey = scheduleDateKey(for: scheduledPosts[index].publishAt)
        if !scheduledPosts[index].skipDateKeys.contains(dateKey) {
            scheduledPosts[index].skipDateKeys.append(dateKey)
        }
        if let next = nextPublishDate(from: scheduledPosts[index].publishAt, cadence: scheduledPosts[index].cadence) {
            scheduledPosts[index].publishAt = next
        }
        scheduledPosts.sort { $0.publishAt < $1.publishAt }
        saveScheduledPosts()
    }

    func recommendedScheduleSlots(for surface: PostSurfaceStyle) -> [Date] {
        let cal = Calendar.current
        let now = Date()
        let preferredHours: [Int] = surface == .chat ? [12, 16, 20] : [11, 14, 19]
        return preferredHours.compactMap { hour in
            var components = cal.dateComponents([.year, .month, .day], from: now)
            components.hour = hour
            components.minute = 0
            guard let todaySlot = cal.date(from: components) else { return nil }
            return todaySlot > now ? todaySlot : cal.date(byAdding: .day, value: 1, to: todaySlot)
        }
    }

    func recommendedGlobalScheduleSlots(
        for surface: PostSurfaceStyle,
        zoneIDs: [String] = ["America/New_York", "Europe/London", "Asia/Tokyo", "America/Los_Angeles"]
    ) -> [(zone: String, label: String)] {
        let preferredHours: [Int] = surface == .chat ? [12, 16, 20] : [11, 14, 19]
        return zoneIDs.compactMap { zoneID in
            guard let tz = TimeZone(identifier: zoneID) else { return nil }
            let slotLabels = preferredHours.prefix(2).map { hour in
                nextSlotLabel(hour: hour, in: tz)
            }
            return (zoneID, slotLabels.joined(separator: " • "))
        }
    }

    @discardableResult
    func autoScheduleBestPost(
        caption: String,
        surfaceStyle: PostSurfaceStyle,
        includesImage: Bool,
        cadence: ScheduleCadence
    ) -> ScheduledPostPlan? {
        let slot = recommendedScheduleSlots(for: surfaceStyle).first ?? Date().addingTimeInterval(3600)
        let score = Int(estimateCaptionPerformance(caption))
        schedulePost(
            caption: aiPolishCaption(caption, surfaceStyle: surfaceStyle),
            publishAt: slot,
            surfaceStyle: surfaceStyle,
            includesImage: includesImage,
            cadence: cadence,
            priority: score
        )
        return scheduledPosts.first(where: { $0.publishAt == slot && $0.surfaceStyle == surfaceStyle })
    }

    private func nextSlotLabel(hour: Int, in timeZone: TimeZone) -> String {
        var cal = Calendar.current
        cal.timeZone = timeZone
        let now = Date()
        var components = cal.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = 0
        let candidate = cal.date(from: components) ?? now
        let resolved = candidate > now ? candidate : (cal.date(byAdding: .day, value: 1, to: candidate) ?? candidate)
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: resolved)
    }

    func captureAnalyticsSnapshot() {
        let mine = posts.filter { $0.authorHandle == currentUser.handle && !$0.isArchived }
        let likes = mine.reduce(0) { $0 + $1.likeCount }
        let comments = mine.reduce(0) { $0 + $1.commentCount }
        let reposts = mine.reduce(0) { $0 + $1.repostCount }
        let saves = mine.reduce(0) { $0 + $1.saveCount }
        let revenue = monetizationInsights().estimatedRevenueUSD
        analyticsSnapshots.insert(
            AnalyticsSnapshot(
                id: UUID(),
                createdAt: Date(),
                likes: likes,
                comments: comments,
                reposts: reposts,
                saves: saves,
                estimatedRevenueUSD: revenue
            ),
            at: 0
        )
        if analyticsSnapshots.count > 60 {
            analyticsSnapshots = Array(analyticsSnapshots.prefix(60))
        }
        saveAnalyticsSnapshots()
    }

    func analyticsCSV() -> String {
        let header = "created_at,likes,comments,reposts,saves,estimated_revenue_usd"
        let rows = analyticsSnapshots.map { snap in
            let dateText = ISO8601DateFormatter().string(from: snap.createdAt)
            return "\(dateText),\(snap.likes),\(snap.comments),\(snap.reposts),\(snap.saves),\(String(format: "%.2f", snap.estimatedRevenueUSD))"
        }
        return ([header] + rows).joined(separator: "\n")
    }

    func enterpriseReportCards() -> [EnterpriseReportCard] {
        let forecast = payoutForecast()
        let insight = monetizationInsights()
        let weekly = weeklyGrowthInsights()
        return [
            EnterpriseReportCard(
                id: UUID(),
                title: "Revenue Forecast",
                summary: "Projected creator earnings trajectory.",
                metricLine: String(format: "Day $%.2f • Week $%.2f • Month $%.2f", forecast.nextDayUSD, forecast.nextWeekUSD, forecast.nextMonthUSD)
            ),
            EnterpriseReportCard(
                id: UUID(),
                title: "Audience Momentum",
                summary: "Engagement and audience energy pulse.",
                metricLine: "Reach \(insight.estimatedReach) • Sponsored \(insight.sponsoredPosts)"
            ),
            EnterpriseReportCard(
                id: UUID(),
                title: "Weekly Execution",
                summary: "Recent output and growth score.",
                metricLine: "Posts \(weekly.newPosts) • Likes \(weekly.newLikes) • Score \(weekly.growthScore)"
            )
        ]
    }

    func enterpriseReportCSV() -> String {
        let header = "title,summary,metrics"
        let rows = enterpriseReportCards().map { card in
            "\"\(card.title)\",\"\(card.summary)\",\"\(card.metricLine)\""
        }
        return ([header] + rows).joined(separator: "\n")
    }

    func schedulingPriorityScore(for plan: ScheduledPostPlan) -> Double {
        let base = Double(plan.priority)
        let caption = estimateCaptionPerformance(plan.caption)
        let hours = max(1.0, plan.publishAt.timeIntervalSinceNow / 3600.0)
        return base + caption + (12.0 / hours)
    }

    @discardableResult
    func reorderScheduledQueueByPriority() -> Int {
        guard scheduledPosts.count > 1 else { return 0 }
        let old = scheduledPosts
        scheduledPosts.sort { lhs, rhs in
            let l = schedulingPriorityScore(for: lhs)
            let r = schedulingPriorityScore(for: rhs)
            if l == r { return lhs.publishAt < rhs.publishAt }
            return l > r
        }
        saveScheduledPosts()
        return zip(old, scheduledPosts).filter { $0.id != $1.id }.count
    }

    func weekdayPerformanceHeatmap() -> [WeekdayPerformance] {
        let symbols = Calendar.current.weekdaySymbols
        return symbols.enumerated().map { idx, weekday in
            let postsForDay = posts.filter {
                Calendar.current.component(.weekday, from: $0.createdAt) == idx + 1
            }
            let score = postsForDay.reduce(0.0) { partial, post in
                partial + Double(post.likeCount + (post.commentCount * 2) + (post.repostCount * 3) + post.saveCount)
            }
            return WeekdayPerformance(id: UUID(), weekday: weekday, score: score)
        }
    }

    private func nextPublishDate(from date: Date, cadence: ScheduleCadence) -> Date? {
        switch cadence {
        case .once:
            return nil
        case .daily:
            return Calendar.current.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return Calendar.current.date(byAdding: .day, value: 7, to: date)
        case .monthly:
            return Calendar.current.date(byAdding: .month, value: 1, to: date)
        }
    }

    private func scheduleDateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func shouldSkipPublishDate(_ date: Date, skipKeys: [String]) -> Bool {
        skipKeys.contains(scheduleDateKey(for: date))
    }

    func schedulingConflicts(around date: Date, withinMinutes: Int = 45) -> [ScheduledPostPlan] {
        let threshold = TimeInterval(max(5, withinMinutes) * 60)
        return scheduledPosts.filter { abs($0.publishAt.timeIntervalSince(date)) <= threshold }
    }

    @discardableResult
    func optimizeScheduleQueue(minimumGapMinutes: Int = 45) -> Int {
        guard !scheduledPosts.isEmpty else { return 0 }
        let gap = TimeInterval(max(10, minimumGapMinutes) * 60)
        var plans = scheduledPosts.sorted { $0.publishAt < $1.publishAt }
        var updates = 0
        for index in 1..<plans.count {
            let prev = plans[index - 1].publishAt
            let current = plans[index].publishAt
            if current.timeIntervalSince(prev) < gap {
                plans[index].publishAt = prev.addingTimeInterval(gap)
                updates += 1
            }
        }
        scheduledPosts = plans
        if updates > 0 {
            saveScheduledPosts()
        }
        return updates
    }

    func autoPostEnterpriseSummaryToPulse() {
        let cards = enterpriseReportCards()
        guard !cards.isEmpty else { return }
        let line = cards.map { "\($0.title): \($0.metricLine)" }.joined(separator: " | ")
        addPulsePost(text: "Enterprise Weekly Summary • \(line)", imageSystemName: "chart.line.uptrend.xyaxis")
    }

    func applySchedulePriorityPreset(_ preset: SchedulePriorityPreset) {
        switch preset {
        case .balanced:
            rankingLikeWeight = 4.0
            rankingCommentWeight = 5.0
            rankingRepostWeight = 6.0
            rankingSaveWeight = 3.0
            rankingFreshnessPower = 0.58
        case .aggressive:
            rankingLikeWeight = 3.0
            rankingCommentWeight = 4.0
            rankingRepostWeight = 8.0
            rankingSaveWeight = 2.0
            rankingFreshnessPower = 0.78
        case .quality:
            rankingLikeWeight = 5.0
            rankingCommentWeight = 7.0
            rankingRepostWeight = 5.0
            rankingSaveWeight = 6.0
            rankingFreshnessPower = 0.46
        }
    }

    @discardableResult
    func autoRescheduleLowPerformingWindows(threshold: Double = 35.0) -> Int {
        guard !scheduledPosts.isEmpty else { return 0 }
        var updates = 0
        for index in scheduledPosts.indices {
            let score = estimateCaptionPerformance(scheduledPosts[index].caption)
            if score < threshold {
                if let nextBest = recommendedScheduleSlots(for: scheduledPosts[index].surfaceStyle).first {
                    scheduledPosts[index].publishAt = nextBest
                    updates += 1
                }
            }
        }
        if updates > 0 {
            scheduledPosts.sort { $0.publishAt < $1.publishAt }
            saveScheduledPosts()
        }
        return updates
    }

    func sendDailySummaryDMToCreatorThread() {
        let summary = "Daily Summary • Queue: \(scheduledPosts.count) • Snapshots: \(analyticsSnapshots.count) • Revenue Est: $\(String(format: "%.2f", monetizationInsights().estimatedRevenueUSD))"
        if let threadID = chats.first(where: { $0.title.localizedCaseInsensitiveContains("creator") })?.id {
            addMessage(to: threadID, text: summary)
            return
        }
        let newThread = ChatThread(
            id: UUID(),
            title: "Creator Daily Brief",
            messages: [
                MessageItem(id: UUID(), senderHandle: currentUser.handle, text: summary, sentAt: Date())
            ]
        )
        chats.insert(newThread, at: 0)
        addActivity(type: .message, detail: "Daily summary sent to Creator Daily Brief.")
    }

    var savedPosts: [PostItem] {
        posts.filter { savedPostIDs.contains($0.id) && !$0.isArchived }
    }

    func archivePost(_ postID: UUID) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[index].isArchived = true
    }

    func unarchivePost(_ postID: UUID) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[index].isArchived = false
    }

    func setLocalCity(_ city: String) {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        localCity = trimmed
        UserDefaults.standard.set(trimmed, forKey: localCityStorageKey)
    }

    private func loadLocalCityFromDefaults() {
        let s = UserDefaults.standard.string(forKey: localCityStorageKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !s.isEmpty {
            localCity = s
        }
    }

    /// Why someone appears in Suggested (contacts, mutual friends, linked platforms).
    func suggestedConnectionDetailLine(for suggestion: SuggestedConnection) -> String {
        let mutual = suggestion.mutualCount
        if suggestion.matchedFromContacts {
            if mutual > 0 { return "From your contacts · \(mutual) mutual friend\(mutual == 1 ? "" : "s")" }
            return "Matched from your phone contacts"
        }
        if suggestion.friendsOfFriends {
            if mutual > 0 {
                return "Friend of someone you follow · \(mutual) mutual connection\(mutual == 1 ? "" : "s")"
            }
            return "Friend of someone you follow"
        }
        let overlap = suggestion.sharedNetworksCount
        if mutual > 0, overlap > 0 {
            return "\(mutual) mutual friend\(mutual == 1 ? "" : "s") · \(overlap) linked network\(overlap == 1 ? "" : "s") in common"
        }
        if mutual > 0 {
            return "\(mutual) mutual friend\(mutual == 1 ? "" : "s")"
        }
        if overlap > 0 {
            return "\(overlap) linked platform\(overlap == 1 ? "" : "s") in common"
        }
        return "Suggested based on your network"
    }

    func markVerificationEmailSent() {
        emailVerificationSent = true
    }

    func completeProviderLogin(
        username: String,
        provider: String,
        accountEmailFromProvider: String? = nil,
        isNewSignUp: Bool = false,
        isNewFirebaseUser: Bool = false
    ) -> String? {
        let providerEmail = (accountEmailFromProvider ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
#if canImport(FirebaseAuth)
        let firebaseUid = Auth.auth().currentUser?.uid
#endif

#if canImport(FirebaseAuth)
        if let firebaseUid,
           let idx = internalUsers.firstIndex(where: { $0.firebaseUserId == firebaseUid }) {
            currentUser = internalUsers[idx]
            applyProviderContactFields(provider: provider, providerEmail: providerEmail, firebaseUid: firebaseUid)
            syncCurrentUserInDirectory()
            finalizeProviderLogin(provider: provider, username: currentUser.username, firebaseUid: firebaseUid)
            return nil
        }
#endif

        var usernameInput = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if usernameInput.isEmpty || usernameInput.lowercased() == "guest" {
            let existing = currentUser.username.trimmingCharacters(in: .whitespacesAndNewlines)
            if !existing.isEmpty, existing.lowercased() != "guest" {
                usernameInput = existing
            } else {
#if canImport(FirebaseAuth)
                let firebaseEmail = Auth.auth().currentUser?.email
#else
                let firebaseEmail: String? = nil
#endif
                let emailBase = providerEmail.split(separator: "@").first.map(String.init)
                    ?? firebaseEmail?.split(separator: "@").first.map(String.init)
                    ?? "user"
                usernameInput = suggestUniqueUsername(base: emailBase)
            }
        }

        guard var cleaned = normalizedUsername(from: usernameInput) else {
            return "Enter a valid unique username (3+ chars, letters/numbers/._)."
        }

        if let idx = internalUsers.firstIndex(where: { $0.username.caseInsensitiveCompare(cleaned) == .orderedSame }) {
            let existing = internalUsers[idx]
#if canImport(FirebaseAuth)
            let sameFirebaseAccount = firebaseUid != nil && existing.firebaseUserId == firebaseUid
#else
            let sameFirebaseAccount = false
#endif
            let explicitLogin = !isNewSignUp || !isNewFirebaseUser

            if sameFirebaseAccount || explicitLogin {
                currentUser = existing
                applyProviderContactFields(provider: provider, providerEmail: providerEmail, firebaseUid: firebaseUid)
                syncCurrentUserInDirectory()
                finalizeProviderLogin(provider: provider, username: currentUser.username, firebaseUid: firebaseUid)
                return nil
            }

            cleaned = suggestUniqueUsername(base: cleaned)
        }

        if ReservedHandles.isReserved(cleaned) {
            cleaned = suggestUniqueUsername(base: cleaned)
        }
        while internalUsers.contains(where: { $0.username.caseInsensitiveCompare(cleaned) == .orderedSame }) {
            cleaned = suggestUniqueUsername(base: "\(cleaned)1")
        }

        currentUser.username = cleaned
        currentUser.handle = "@\(cleaned)"
        if currentUser.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            currentUser.displayName = cleaned
        }
        applyProviderContactFields(provider: provider, providerEmail: providerEmail, firebaseUid: firebaseUid)
        syncCurrentUserInDirectory()
        finalizeProviderLogin(provider: provider, username: cleaned, firebaseUid: firebaseUid)
        return nil
    }

    private func applyProviderContactFields(provider: String, providerEmail: String, firebaseUid: String?) {
        if !providerEmail.isEmpty {
            if currentUser.accountEmail.isEmpty || Self.isPlaceholderAccountEmail(currentUser.accountEmail) {
                currentUser.accountEmail = providerEmail
            }
        } else if Self.isOAuthProvider(provider), currentUser.accountEmail.isEmpty {
            currentUser.accountEmail = Self.placeholderAccountEmail(forUsername: currentUser.username)
        }
        if Self.isOAuthProvider(provider) {
            let digits = currentUser.accountPhone.filter(\.isNumber)
            if digits.count < 10 {
                currentUser.accountPhone = Self.placeholderAccountPhoneDigits
            }
        }
#if canImport(FirebaseAuth)
        if let firebaseUid {
            currentUser.firebaseUserId = firebaseUid
        }
#endif
    }

    private func finalizeProviderLogin(provider: String, username: String, firebaseUid: String?) {
#if canImport(FirebaseAuth)
        if let firebaseUid {
            firebaseSignedInUID = firebaseUid
        }
#endif
        isSessionBootstrapComplete = false
        registerLoggedInAccount(username)
        refreshCurrentProfileMedia()
        loadSavedPosts()
        loadProfileQuoteState()
        loadProfileModeState()
        loadInterestState()
        loadReelCollections()
        loadExploreSignals()
        loadSeenStoryHandles()
        restoreEngagementState()
        loadScheduledPosts()
        loadAnalyticsSnapshots()
        loadExecutionQueueProgress()
        loadExecutionQueueSnapshots()
        loadExecutionQueueSettings()
        loadExecutionQueueRestorePoint()
        captureExecutionCompletionSnapshotIfNeededDaily()
        beginSession(provider: provider)
#if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        if Auth.auth().currentUser != nil {
            Task { @MainActor in
                await claimUsernameDocumentIfNeeded()
                await hydrateProfileFromFirestoreForCurrentFirebaseUser()
                isSessionBootstrapComplete = true
            }
        } else {
            isSessionBootstrapComplete = true
        }
#else
        isSessionBootstrapComplete = true
#endif
    }

    /// Whether the signed-in account uses email/password (needs password to delete).
    var currentAccountUsesPasswordProvider: Bool {
#if canImport(FirebaseAuth)
        if let user = Auth.auth().currentUser {
            return user.providerData.contains { $0.providerID == EmailAuthProviderID }
        }
#endif
        let key = currentUser.username.lowercased()
        return localCredentials[key] != nil
    }

    func endSession() {
        session = nil
        UserDefaults.standard.removeObject(forKey: sessionStorageKey)
        firebaseSignedInUID = nil
        isSessionBootstrapComplete = true
        isInternalAdminCache = false
#if canImport(FirebaseAuth)
        try? Auth.auth().signOut()
#endif
        currentUser = Self.makeGuestUserProfile()
    }

    /// Permanently deletes the signed-in account (Guideline 5.1.1(v)).
    func deleteCurrentAccount(password: String?) async -> String? {
        let usernameKey = currentUser.username.lowercased()
        guard !usernameKey.isEmpty, usernameKey != "guest" else {
            return "No account is signed in."
        }
        let profileId = currentUser.id
        let storedUID = currentUser.firebaseUserId

#if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        if let user = Auth.auth().currentUser {
            let usesPassword = user.providerData.contains { $0.providerID == EmailAuthProviderID }
            if usesPassword {
                let trimmedPassword = (password ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmedPassword.count >= 8 else {
                    return "Enter your password to permanently delete this account."
                }
                let email = (user.email ?? currentUser.accountEmail).trimmingCharacters(in: .whitespacesAndNewlines)
                guard !email.isEmpty else { return "Missing account email for verification." }
                do {
                    let credential = EmailAuthProvider.credential(withEmail: email, password: trimmedPassword)
                    try await user.reauthenticate(with: credential)
                } catch {
                    return "Password verification failed. Check your password and try again."
                }
            }

            if AppReviewDemoAccount.shouldPreserveServerAccount(
                username: usernameKey,
                accountEmail: currentUser.accountEmail,
                firebaseEmail: user.email
            ) {
                endSession()
                return nil
            }

            let db = Firestore.firestore()
            let uid = user.uid
            if !usernameKey.isEmpty {
                try? await db.collection(ChitChatFirestoreSchema.Collection.usernames)
                    .document(usernameKey)
                    .delete()
            }
            try? await db.collection(ChitChatFirestoreSchema.Collection.users)
                .document(uid)
                .delete()

            do {
                try await user.delete()
            } catch let error as NSError {
                if error.domain == AuthErrorDomain,
                   error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    return "For security, sign out, sign in again, then return to Delete account."
                }
                return error.localizedDescription
            }
        } else if !storedUID.isEmpty, !storedUID.hasPrefix("local_") {
            if AppReviewDemoAccount.shouldPreserveServerAccount(
                username: usernameKey,
                accountEmail: currentUser.accountEmail,
                firebaseEmail: nil
            ) {
                endSession()
                return nil
            }
            let db = Firestore.firestore()
            if !usernameKey.isEmpty {
                try? await db.collection(ChitChatFirestoreSchema.Collection.usernames)
                    .document(usernameKey)
                    .delete()
            }
            try? await db.collection(ChitChatFirestoreSchema.Collection.users)
                .document(storedUID)
                .delete()
        }
#else
        if let storedPassword = localCredentials[usernameKey] {
            let trimmedPassword = (password ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedPassword == storedPassword else {
                return "Enter your password to permanently delete this account."
            }
        }
        if AppReviewDemoAccount.shouldPreserveServerAccount(
            username: usernameKey,
            accountEmail: currentUser.accountEmail,
            firebaseEmail: nil
        ) {
            endSession()
            return nil
        }
#endif

        purgeLocalAccountArtifacts(usernameKey: usernameKey, profileId: profileId)
        endSession()
        return nil
    }

    private func purgeLocalAccountArtifacts(usernameKey: String, profileId: UUID) {
        verificationRequests.removeAll { $0.username.lowercased() == usernameKey }
        saveVerificationRequests()
        internalUsers.removeAll { $0.id == profileId || $0.username.lowercased() == usernameKey }
        localCredentials.removeValue(forKey: usernameKey)
        saveCredentials()
        loggedInAccountUsernames.removeAll { $0.lowercased() == usernameKey }
        saveLoggedInAccounts()
        UserDefaults.standard.removeObject(forKey: pendingPasswordResetStorageKey(usernameKey: usernameKey))
        UserDefaults.standard.removeObject(forKey: passwordResetUserRatePrefix + usernameKey)
        UserDefaults.standard.removeObject(forKey: passwordResetLockPrefix + usernameKey)

        profilePhotoByUsername.removeValue(forKey: usernameKey)
        profileGIFByUsername.removeValue(forKey: usernameKey)
        profileLoopVideoByUsername.removeValue(forKey: usernameKey)
        profileStoryImageByUsername.removeValue(forKey: usernameKey)
        profileStoryVideoByUsername.removeValue(forKey: usernameKey)
        profileStoryGIFByUsername.removeValue(forKey: usernameKey)

        let scopedPrefixes = [
            profilePhotoStoragePrefix,
            profileGifStoragePrefix,
            profileLoopVideoStoragePrefix,
            profileStoryImageStoragePrefix,
            profileStoryVideoStoragePrefix,
            profileStoryGifStoragePrefix,
            savedPostsStoragePrefix,
            storySeenStoragePrefix,
            profileQuoteStoragePrefix,
            profileQuoteVisibilityStoragePrefix,
            profileModeStateStoragePrefix,
            interestStateStoragePrefix,
            reelCollectionStoragePrefix,
            exploreSignalStoragePrefix,
            engagementStoragePrefix,
            superFeatureSelectionStoragePrefix,
            executionQueueProgressStoragePrefix,
            executionQueueSnapshotStoragePrefix,
            executionQueueLockStoragePrefix,
            executionQueueLastSnapshotDayStoragePrefix,
            executionQueueRestorePointStoragePrefix,
            scheduledPostsStoragePrefix,
            analyticsSnapshotsStoragePrefix
        ]
        for prefix in scopedPrefixes {
            UserDefaults.standard.removeObject(forKey: "\(prefix)\(usernameKey)")
        }

        posts.removeAll { $0.authorHandle.caseInsensitiveCompare(currentUser.handle) == .orderedSame }
        savedPostIDs.removeAll()
        let username = currentUser.username
        ReservedHandles.removeAdminHeldUsername(username)
        ReservedHandles.setHandoffEmail(forUsername: username, email: "")
    }

    func validateBusinessRegistration(_ registration: BusinessRegistration) -> String? {
        let einDigits = registration.ein.filter(\.isNumber)
        guard einDigits.count == 9 else {
            return "EIN must be exactly 9 digits (U.S. Employer Identification Number)."
        }
        let legal = registration.legalName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard legal.count >= 2 else { return "Legal business name is required." }
        let line1 = registration.addressLine1.trimmingCharacters(in: .whitespacesAndNewlines)
        guard line1.count >= 4 else { return "Business street address is required." }
        let city = registration.city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard city.count >= 2 else { return "City is required." }
        let st = registration.state.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard st.count == 2, st.allSatisfy(\.isLetter) else { return "Use a 2-letter state code (e.g. TX)." }
        let zipRaw = registration.zip.trimmingCharacters(in: .whitespacesAndNewlines).filter(\.isNumber)
        guard zipRaw.count == 5 || zipRaw.count == 9 else { return "ZIP must be 5 or 9 digits." }
        let phoneDigits = registration.phone.filter(\.isNumber)
        guard phoneDigits.count >= 10 else { return "Enter a valid business phone (10+ digits)." }
        if !registration.website.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let w = registration.website.trimmingCharacters(in: .whitespacesAndNewlines)
            if !w.lowercased().hasPrefix("http") {
                return "Website should start with https://"
            }
        }
        return nil
    }

    private func applyBusinessRegistration(_ registration: BusinessRegistration) {
        let einDigits = registration.ein.filter(\.isNumber)
        let einStr = String(einDigits)
        let formattedEIN = "\(einStr.prefix(2))-\(einStr.dropFirst(2))"
        let legal = registration.legalName.trimmingCharacters(in: .whitespacesAndNewlines)
        let dba = registration.dba.trimmingCharacters(in: .whitespacesAndNewlines)
        currentUser.businessEIN = formattedEIN
        currentUser.businessLegalName = legal
        currentUser.businessDBA = dba
        currentUser.businessAddressLine1 = registration.addressLine1.trimmingCharacters(in: .whitespacesAndNewlines)
        currentUser.businessCity = registration.city.trimmingCharacters(in: .whitespacesAndNewlines)
        currentUser.businessState = registration.state.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let z = registration.zip.trimmingCharacters(in: .whitespacesAndNewlines).filter(\.isNumber)
        currentUser.businessZIP = z.count == 9 ? String(z.prefix(5)) + "-" + String(z.dropFirst(5)) : z
        let p = registration.phone.filter(\.isNumber)
        currentUser.businessPhone = p
        currentUser.businessWebsite = registration.website.trimmingCharacters(in: .whitespacesAndNewlines)
        currentUser.isBusinessAccount = true
        currentUser.businessJobPostingApproved = false
        currentUser.displayName = legal
        currentUser.enterpriseAlias = dba.isEmpty ? legal : dba
        currentUser.allowEnterpriseReveal = true
    }

    private func clearBusinessRegistrationOnCurrentUser() {
        currentUser.businessEIN = ""
        currentUser.businessLegalName = ""
        currentUser.businessDBA = ""
        currentUser.businessAddressLine1 = ""
        currentUser.businessCity = ""
        currentUser.businessState = ""
        currentUser.businessZIP = ""
        currentUser.businessPhone = ""
        currentUser.businessWebsite = ""
        currentUser.isBusinessAccount = false
        currentUser.businessJobPostingApproved = false
    }

    @discardableResult
    func switchToAccount(username: String) -> Bool {
        let key = username.lowercased()
#if canImport(FirebaseAuth)
        if let fu = Auth.auth().currentUser {
            guard
                let scoped = internalUsers.first(where: { $0.username.lowercased() == key }),
                scoped.firebaseUserId == fu.uid
            else { return false }
        }
#endif
        if let existing = internalUsers.first(where: { $0.username.lowercased() == key }) {
            currentUser = existing
            registerLoggedInAccount(existing.username)
            refreshCurrentProfileMedia()
            loadSavedPosts()
            loadProfileQuoteState()
            loadProfileModeState()
            loadInterestState()
            loadReelCollections()
            loadExploreSignals()
            loadSeenStoryHandles()
            restoreEngagementState()
            loadScheduledPosts()
            loadAnalyticsSnapshots()
            loadExecutionQueueProgress()
            loadExecutionQueueSnapshots()
            loadExecutionQueueSettings()
            loadExecutionQueueRestorePoint()
            captureExecutionCompletionSnapshotIfNeededDaily()
            beginSession(provider: "account_switch")
            return true
        }
        guard localCredentials[key] != nil else { return false }
        currentUser.username = username
        currentUser.handle = "@\(username)"
        currentUser.displayName = username
        syncCurrentUserInDirectory()
        registerLoggedInAccount(username)
        refreshCurrentProfileMedia()
        loadSavedPosts()
        loadProfileQuoteState()
        loadProfileModeState()
        loadInterestState()
        loadReelCollections()
        loadExploreSignals()
        loadSeenStoryHandles()
        restoreEngagementState()
        loadScheduledPosts()
        loadAnalyticsSnapshots()
        loadExecutionQueueProgress()
        loadExecutionQueueSnapshots()
        loadExecutionQueueSettings()
        loadExecutionQueueRestorePoint()
        captureExecutionCompletionSnapshotIfNeededDaily()
        beginSession(provider: "account_switch")
        return true
    }

    var loggedInAccounts: [UserProfile] {
        loggedInAccountUsernames.compactMap { account in
            internalUsers.first(where: { $0.username.lowercased() == account.lowercased() })
        }
    }

    func addRecentSearch(_ rawQuery: String) {
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        recentSearches.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        recentSearches.insert(trimmed, at: 0)
        if recentSearches.count > 20 {
            recentSearches = Array(recentSearches.prefix(20))
        }
        saveRecentSearches()
    }

    func removeRecentSearch(_ query: String) {
        recentSearches.removeAll { $0.caseInsensitiveCompare(query) == .orderedSame }
        saveRecentSearches()
    }

    func clearRecentSearches() {
        recentSearches = []
        saveRecentSearches()
    }

    func toggleCloseFriend(_ handle: String) {
        if closeFriendsHandles.contains(handle) {
            closeFriendsHandles.remove(handle)
        } else {
            closeFriendsHandles.insert(handle)
        }
    }

    func updatePostCaption(postID: UUID, newCaption: String) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        let trimmed = newCaption.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        posts[index].caption = trimmed
    }

    func deletePost(_ postID: UUID) {
        posts.removeAll { $0.id == postID }
        savedPostIDs.remove(postID)
        commentsByPost[postID] = nil
        likesByPost[postID] = nil
        repostsByPost[postID] = nil
        reactionByPost[postID] = nil
        saveSavedPosts()
        saveEngagementState()
    }

    func deletePostWithUndo(_ postID: UUID) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        let post = posts[index]
        let snapshot = DeletedPostSnapshot(
            index: index,
            post: post,
            comments: commentsByPost[postID] ?? [],
            likes: likesByPost[postID] ?? [],
            reposts: repostsByPost[postID] ?? [],
            reaction: reactionByPost[postID]
        )
        lastDeletedPostSnapshot = snapshot
        registerUndoEntry(label: "Delete post", kind: .post(snapshot))
        deletePost(postID)
    }

    @discardableResult
    func undoLastDeletedPost() -> Bool {
        guard let index = undoQueue.lastIndex(where: {
            if case .post = $0.kind { return true }
            return false
        }) else { return false }
        let entry = undoQueue.remove(at: index)
        let result = applyUndoEntry(entry)
        syncUndoIndicators()
        return result
    }

    @discardableResult
    func undoLatestAction() -> Bool {
        guard let entry = undoQueue.popLast() else { return false }
        let result = applyUndoEntry(entry)
        syncUndoIndicators()
        return result
    }

    func clearUndoQueue() {
        undoQueue.removeAll()
        syncUndoIndicators()
    }

    private func registerUndoEntry(label: String, kind: UndoQueueEntry.Kind) {
        undoQueue.append(UndoQueueEntry(label: label, kind: kind))
        if undoQueue.count > 25 {
            undoQueue.removeFirst(undoQueue.count - 25)
        }
        syncUndoIndicators()
    }

    @discardableResult
    private func applyUndoEntry(_ entry: UndoQueueEntry) -> Bool {
        switch entry.kind {
        case .post(let snapshot):
            let insertIndex = max(0, min(snapshot.index, posts.count))
            posts.insert(snapshot.post, at: insertIndex)
            commentsByPost[snapshot.post.id] = snapshot.comments
            likesByPost[snapshot.post.id] = snapshot.likes
            repostsByPost[snapshot.post.id] = snapshot.reposts
            reactionByPost[snapshot.post.id] = snapshot.reaction
            lastDeletedPostSnapshot = nil
            saveEngagementState()
            return true
        case .message(let snapshot):
            guard let threadIndex = chats.firstIndex(where: { $0.id == snapshot.threadID }) else { return false }
            let insertIndex = max(0, min(snapshot.index, chats[threadIndex].messages.count))
            chats[threadIndex].messages.insert(snapshot.message, at: insertIndex)
            lastDeletedMessageSnapshot = nil
            return true
        }
    }

    private func syncUndoIndicators() {
        undoQueueCount = undoQueue.count
        latestUndoLabel = undoQueue.last?.label ?? ""
        canUndoPostDeletion = undoQueue.contains {
            if case .post = $0.kind { return true }
            return false
        }
        canUndoMessageDeletion = undoQueue.contains {
            if case .message = $0.kind { return true }
            return false
        }
        if let lastMessageEntry = undoQueue.reversed().first(where: {
            if case .message = $0.kind { return true }
            return false
        }), case .message(let snapshot) = lastMessageEntry.kind {
            lastDeletedMessagePreview = snapshot.message.text
        } else {
            lastDeletedMessagePreview = ""
        }
    }

    func usersForLikes(postID: UUID) -> [PostEngagementUser] {
        let users = likesByPost[postID] ?? []
        if users.isEmpty, let post = posts.first(where: { $0.id == postID }), post.likeCount > 0 {
            return [engagementUser(for: post.authorHandle)]
        }
        return users
    }

    func usersForReposts(postID: UUID) -> [PostEngagementUser] {
        repostsByPost[postID] ?? []
    }

    func profilePhoto(for handle: String) -> Data? {
        if let known = internalUsers.first(where: { $0.handle.caseInsensitiveCompare(handle) == .orderedSame }) {
            return profilePhotoByUsername[known.username.lowercased()] ?? nil
        }
        let normalized = handle.replacingOccurrences(of: "@", with: "").lowercased()
        if !normalized.isEmpty {
            return profilePhotoByUsername[normalized] ?? nil
        }
        return nil
    }

    func displayName(for handle: String) -> String {
        if mode == .social && !socialProfileVisible {
            return handle.replacingOccurrences(of: "@", with: "")
        }
        if mode == .enterprise && !corporateProfileVisible {
            return "Private Corporate Profile"
        }
        // Social surface should show usernames/handles, not real names.
        if mode == .social {
            return handle.replacingOccurrences(of: "@", with: "")
        }
        if currentUser.handle.caseInsensitiveCompare(handle) == .orderedSame {
            if mode == .enterprise {
                return currentUser.displayName
            }
            return currentUser.displayName
        }
        if let found = internalUsers.first(where: { $0.handle.caseInsensitiveCompare(handle) == .orderedSame }) {
            return found.displayName
        }
        return handle.replacingOccurrences(of: "@", with: "")
    }

    var unreadActivityCount: Int {
        visibleActivityFeed.filter { !$0.isRead }.count
    }

    func markAllActivityRead() {
        for index in activityFeed.indices {
            activityFeed[index].isRead = true
        }
    }

    func creatorInsights() -> CreatorInsights {
        let myPosts = posts.filter { $0.authorHandle == currentUser.handle && !$0.isArchived }
        let likes = myPosts.reduce(0) { $0 + $1.likeCount }
        let comments = myPosts.reduce(0) { $0 + $1.commentCount }
        let reposts = myPosts.reduce(0) { $0 + $1.repostCount }
        let saves = myPosts.reduce(0) { $0 + $1.saveCount }
        let engagement = likes + comments + reposts + saves
        return CreatorInsights(
            totalPosts: myPosts.count,
            totalLikes: likes,
            totalComments: comments,
            totalReposts: reposts,
            totalSaves: saves,
            engagementScore: engagement
        )
    }

    func topPerformingPosts(limit: Int = 5) -> [PostItem] {
        posts
            .filter { $0.authorHandle == currentUser.handle && !$0.isArchived }
            .sorted { lhs, rhs in
                let left = lhs.likeCount + lhs.commentCount + lhs.repostCount + lhs.saveCount
                let right = rhs.likeCount + rhs.commentCount + rhs.repostCount + rhs.saveCount
                if left == right { return lhs.createdAt > rhs.createdAt }
                return left > right
            }
            .prefix(limit)
            .map { $0 }
    }

    func weeklyGrowthInsights() -> WeeklyGrowthInsights {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
        let recent = posts.filter { $0.authorHandle == currentUser.handle && $0.createdAt >= weekAgo && !$0.isArchived }
        let likes = recent.reduce(0) { $0 + $1.likeCount }
        let comments = recent.reduce(0) { $0 + $1.commentCount }
        let score = likes + comments + (recent.count * 2)
        return WeeklyGrowthInsights(
            newPosts: recent.count,
            newLikes: likes,
            newComments: comments,
            growthScore: score
        )
    }

    var visibleActivityFeed: [ActivityItem] {
        activityFeed.filter { !mutedActivityTypes.contains($0.type) }
    }

    func toggleMutedActivityType(_ type: ActivityType) {
        if mutedActivityTypes.contains(type) {
            mutedActivityTypes.remove(type)
        } else {
            mutedActivityTypes.insert(type)
        }
    }

    private func syncCurrentUserInDirectory() {
        if let index = internalUsers.firstIndex(where: { $0.id == currentUser.id }) {
            internalUsers[index] = currentUser
        } else {
            internalUsers.insert(currentUser, at: 0)
        }
#if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        pushChitChatUserDirectoryIfFirebaseSignedIn()
#endif
    }

    private func canViewPost(_ post: PostItem) -> Bool {
        if post.authorHandle == currentUser.handle {
            return true
        }
        switch post.audience {
        case .public:
            return true
        case .followers:
            return activeFollowingHandles.contains(post.authorHandle)
        case .closeFriends:
            return closeFriendsHandles.contains(post.authorHandle)
        }
    }

    private func normalizedUsername(from rawValue: String) -> String? {
        let cleaned = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
        guard cleaned.count >= 3 else { return nil }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._"))
        guard cleaned.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return nil }
        return cleaned
    }

    private func loadCredentials() {
        guard
            let data = UserDefaults.standard.data(forKey: credentialsStorageKey),
            let decoded = try? JSONDecoder().decode([String: String].self, from: data)
        else {
            localCredentials = [:]
            return
        }
        localCredentials = decoded
    }

    private func saveCredentials() {
        guard let data = try? JSONEncoder().encode(localCredentials) else { return }
        UserDefaults.standard.set(data, forKey: credentialsStorageKey)
    }

    private func loadVerificationRequests() {
        guard let data = UserDefaults.standard.data(forKey: verificationRequestStorageKey) else { return }
        guard let decoded = try? JSONDecoder().decode([VerificationRequest].self, from: data) else { return }
        verificationRequests = decoded
    }

    private func saveVerificationRequests() {
        guard let data = try? JSONEncoder().encode(verificationRequests) else { return }
        UserDefaults.standard.set(data, forKey: verificationRequestStorageKey)
    }

    private func loadCombinedPostRequests() {
        guard let data = UserDefaults.standard.data(forKey: combinedPostRequestStorageKey) else { return }
        guard let decoded = try? JSONDecoder().decode([CombinedPostRequest].self, from: data) else { return }
        combinedPostRequests = decoded
    }

    private func saveCombinedPostRequests() {
        guard let data = try? JSONEncoder().encode(combinedPostRequests) else { return }
        UserDefaults.standard.set(data, forKey: combinedPostRequestStorageKey)
    }

    private func loadProfilePhotoMap() {
        profilePhotoByUsername = [:]
        profileGIFByUsername = [:]
        profileLoopVideoByUsername = [:]
        profileStoryImageByUsername = [:]
        profileStoryVideoByUsername = [:]
        profileStoryGIFByUsername = [:]
        let usernames = Set(internalUsers.map { $0.username.lowercased() }).union(localCredentials.keys)
        for username in usernames {
            let photoKey = "\(profilePhotoStoragePrefix)\(username)"
            if let data = UserDefaults.standard.data(forKey: photoKey) {
                profilePhotoByUsername[username] = data
            }
            let gifKey = "\(profileGifStoragePrefix)\(username)"
            if let data = UserDefaults.standard.data(forKey: gifKey) {
                profileGIFByUsername[username] = data
            }
            let videoKey = "\(profileLoopVideoStoragePrefix)\(username)"
            if let data = UserDefaults.standard.data(forKey: videoKey) {
                profileLoopVideoByUsername[username] = data
            }
            let storyImageKey = "\(profileStoryImageStoragePrefix)\(username)"
            if let data = UserDefaults.standard.data(forKey: storyImageKey) {
                profileStoryImageByUsername[username] = data
            }
            let storyVideoKey = "\(profileStoryVideoStoragePrefix)\(username)"
            if let data = UserDefaults.standard.data(forKey: storyVideoKey) {
                profileStoryVideoByUsername[username] = data
            }
            let storyGifKey = "\(profileStoryGifStoragePrefix)\(username)"
            if let data = UserDefaults.standard.data(forKey: storyGifKey) {
                profileStoryGIFByUsername[username] = data
            }
        }
        refreshCurrentProfileMedia()
    }

    private func registerLoggedInAccount(_ username: String) {
        let normalized = username.lowercased()
        if !loggedInAccountUsernames.map({ $0.lowercased() }).contains(normalized) {
            loggedInAccountUsernames.insert(username, at: 0)
            saveLoggedInAccounts()
        }
    }

    private func loadLoggedInAccounts() {
        guard let saved = UserDefaults.standard.array(forKey: loggedInAccountsKey) as? [String] else {
            loggedInAccountUsernames = []
            return
        }
        loggedInAccountUsernames = saved
    }

    private func saveLoggedInAccounts() {
        UserDefaults.standard.set(loggedInAccountUsernames, forKey: loggedInAccountsKey)
    }

    /// Strips device-only leftovers from the old hard-coded demo identity; Firebase Auth + `users/{uid}` are authoritative.
    private func purgeLegacySeededAccountArtifacts() {
        let doomed = Set(
            localCredentials.keys.filter { Self.isLegacySeededUsernameKey($0) }
                + loggedInAccountUsernames.map { $0.lowercased() }.filter { Self.isLegacySeededUsernameKey($0) }
        )
        guard !doomed.isEmpty else {
            if Self.isLegacySeededUsernameKey(currentUser.username) {
                currentUser = Self.makeGuestUserProfile()
            }
            if let data = UserDefaults.standard.data(forKey: sessionStorageKey),
               let decoded = try? JSONDecoder().decode(AppSession.self, from: data),
               Self.isLegacySeededUsernameKey(decoded.username) {
                UserDefaults.standard.removeObject(forKey: sessionStorageKey)
                session = nil
            }
            return
        }
        for key in doomed {
            localCredentials.removeValue(forKey: key)
            UserDefaults.standard.removeObject(forKey: pendingPasswordResetStorageKey(usernameKey: key))
            UserDefaults.standard.removeObject(forKey: passwordResetUserRatePrefix + key)
            UserDefaults.standard.removeObject(forKey: passwordResetLockPrefix + key)
            let scopedPrefixes = [
                profilePhotoStoragePrefix,
                profileGifStoragePrefix,
                profileLoopVideoStoragePrefix,
                profileStoryImageStoragePrefix,
                profileStoryVideoStoragePrefix,
                profileStoryGifStoragePrefix,
                savedPostsStoragePrefix,
                storySeenStoragePrefix,
                profileQuoteStoragePrefix,
                profileQuoteVisibilityStoragePrefix,
                profileModeStateStoragePrefix,
                interestStateStoragePrefix,
                reelCollectionStoragePrefix,
                exploreSignalStoragePrefix,
                engagementStoragePrefix,
                superFeatureSelectionStoragePrefix,
                executionQueueProgressStoragePrefix,
                executionQueueSnapshotStoragePrefix,
                executionQueueLockStoragePrefix,
                executionQueueLastSnapshotDayStoragePrefix,
                executionQueueRestorePointStoragePrefix,
                scheduledPostsStoragePrefix,
                analyticsSnapshotsStoragePrefix
            ]
            for prefix in scopedPrefixes {
                UserDefaults.standard.removeObject(forKey: "\(prefix)\(key)")
            }
        }
        loggedInAccountUsernames.removeAll { Self.isLegacySeededUsernameKey($0) }
        saveCredentials()
        saveLoggedInAccounts()
        if let data = UserDefaults.standard.data(forKey: sessionStorageKey),
           let decoded = try? JSONDecoder().decode(AppSession.self, from: data),
           Self.isLegacySeededUsernameKey(decoded.username) {
            UserDefaults.standard.removeObject(forKey: sessionStorageKey)
            session = nil
        }
        if Self.isLegacySeededUsernameKey(currentUser.username) {
            currentUser = Self.makeGuestUserProfile()
        }
    }

    private static func isLegacySeededUsernameKey(_ raw: String) -> Bool {
        let k = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return k.contains("almighty_bruce") || k == "almightybruce_"
    }

    private func loadRecentSearches() {
        guard let stored = UserDefaults.standard.array(forKey: recentSearchesStorageKey) as? [String] else {
            recentSearches = []
            return
        }
        recentSearches = stored
    }

    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: recentSearchesStorageKey)
    }

    private func loadProfileModeState() {
        guard let data = UserDefaults.standard.data(forKey: profileModeStateStorageKey) else { return }
        guard let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) else { return }
        hasSocialProfile = decoded["hasSocialProfile"] ?? hasSocialProfile
        hasCorporateProfile = decoded["hasCorporateProfile"] ?? hasCorporateProfile
        socialProfileVisible = decoded["socialProfileVisible"] ?? socialProfileVisible
        corporateProfileVisible = decoded["corporateProfileVisible"] ?? corporateProfileVisible
    }

    private func saveProfileModeState() {
        let payload: [String: Bool] = [
            "hasSocialProfile": hasSocialProfile,
            "hasCorporateProfile": hasCorporateProfile,
            "socialProfileVisible": socialProfileVisible,
            "corporateProfileVisible": corporateProfileVisible
        ]
        guard let data = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: profileModeStateStorageKey)
    }

    private func loadInterestState() {
        guard let data = UserDefaults.standard.data(forKey: interestStateStorageKey) else { return }
        guard let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) else { return }
        if let social = decoded["social"] {
            socialInterests = Set(social)
        }
        if let corporate = decoded["corporate"] {
            corporateInterests = Set(corporate)
        }
    }

    private func saveInterestState() {
        let payload: [String: [String]] = [
            "social": Array(socialInterests).sorted(),
            "corporate": Array(corporateInterests).sorted()
        ]
        guard let data = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: interestStateStorageKey)
    }

    private func loadReelCollections() {
        guard let data = UserDefaults.standard.data(forKey: reelCollectionStorageKey) else { return }
        guard let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) else { return }
        var mapped: [String: Set<UUID>] = [:]
        for (key, ids) in decoded {
            mapped[key] = Set(ids.compactMap { UUID(uuidString: $0) })
        }
        reelCollections = mapped
    }

    private func saveReelCollections() {
        let payload = reelCollections.reduce(into: [String: [String]]()) { partial, pair in
            partial[pair.key] = pair.value.map(\.uuidString).sorted()
        }
        guard let data = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: reelCollectionStorageKey)
    }

    private func loadExploreSignals() {
        guard let data = UserDefaults.standard.data(forKey: exploreSignalStorageKey) else {
            exploreBoostByPostID = [:]
            return
        }
        guard let decoded = try? JSONDecoder().decode([String: Int].self, from: data) else {
            exploreBoostByPostID = [:]
            return
        }
        exploreBoostByPostID = decoded
    }

    private func saveExploreSignals() {
        guard let data = try? JSONEncoder().encode(exploreBoostByPostID) else { return }
        UserDefaults.standard.set(data, forKey: exploreSignalStorageKey)
    }

    private var savedPostsStorageKey: String {
        "\(savedPostsStoragePrefix)\(currentUser.username.lowercased())"
    }

    private var seenStoryStorageKey: String {
        "\(storySeenStoragePrefix)\(currentUser.username.lowercased())"
    }

    private var profileQuoteStorageKey: String {
        "\(profileQuoteStoragePrefix)\(currentUser.username.lowercased())"
    }

    private var profileQuoteVisibilityStorageKey: String {
        "\(profileQuoteVisibilityStoragePrefix)\(currentUser.username.lowercased())"
    }

    private var profileModeStateStorageKey: String {
        "\(profileModeStateStoragePrefix)\(currentUser.username.lowercased())"
    }

    private var interestStateStorageKey: String {
        "\(interestStateStoragePrefix)\(currentUser.username.lowercased())"
    }

    private var reelCollectionStorageKey: String {
        "\(reelCollectionStoragePrefix)\(currentUser.username.lowercased())"
    }

    private var exploreSignalStorageKey: String {
        "\(exploreSignalStoragePrefix)\(currentUser.username.lowercased())"
    }

    private var superFeatureSelectionStorageKey: String {
        "\(superFeatureSelectionStoragePrefix)\(currentUser.username.lowercased())"
    }

    private var executionQueueProgressStorageKey: String {
        "\(executionQueueProgressStoragePrefix)\(currentUser.username.lowercased())"
    }

    private var executionQueueSnapshotStorageKey: String {
        "\(executionQueueSnapshotStoragePrefix)\(currentUser.username.lowercased())"
    }

    private var executionQueueLockStorageKey: String {
        "\(executionQueueLockStoragePrefix)\(currentUser.username.lowercased())"
    }

    private var executionQueueLastSnapshotDayStorageKey: String {
        "\(executionQueueLastSnapshotDayStoragePrefix)\(currentUser.username.lowercased())"
    }

    private var executionQueueRestorePointStorageKey: String {
        "\(executionQueueRestorePointStoragePrefix)\(currentUser.username.lowercased())"
    }

    private var scheduledPostsStorageKey: String {
        "\(scheduledPostsStoragePrefix)\(currentUser.username.lowercased())"
    }

    private var analyticsSnapshotsStorageKey: String {
        "\(analyticsSnapshotsStoragePrefix)\(currentUser.username.lowercased())"
    }

    private func loadSavedPosts() {
        guard let stored = UserDefaults.standard.array(forKey: savedPostsStorageKey) as? [String] else {
            savedPostIDs = []
            return
        }
        let ids = stored.compactMap { UUID(uuidString: $0) }
        let postIDs = Set(posts.map(\.id))
        savedPostIDs = Set(ids).intersection(postIDs)
    }

    private func saveSavedPosts() {
        let values = savedPostIDs.map(\.uuidString)
        UserDefaults.standard.set(values, forKey: savedPostsStorageKey)
    }

    private func loadSeenStoryHandles() {
        guard let values = UserDefaults.standard.array(forKey: seenStoryStorageKey) as? [String] else {
            seenStoryHandles = []
            return
        }
        seenStoryHandles = Set(values.map { $0.lowercased() })
    }

    private func saveSeenStoryHandles() {
        UserDefaults.standard.set(Array(seenStoryHandles), forKey: seenStoryStorageKey)
    }

    private func loadProfileQuoteState() {
        currentUser.profileQuote = UserDefaults.standard.string(forKey: profileQuoteStorageKey) ?? ""
        if UserDefaults.standard.object(forKey: profileQuoteVisibilityStorageKey) == nil {
            currentUser.isProfileQuoteVisible = true
        } else {
            currentUser.isProfileQuoteVisible = UserDefaults.standard.bool(forKey: profileQuoteVisibilityStorageKey)
        }
        syncCurrentUserInDirectory()
    }

    private func saveProfileQuoteState() {
        UserDefaults.standard.set(currentUser.profileQuote, forKey: profileQuoteStorageKey)
        UserDefaults.standard.set(currentUser.isProfileQuoteVisible, forKey: profileQuoteVisibilityStorageKey)
    }

    private func loadScheduledPosts() {
        guard
            let data = UserDefaults.standard.data(forKey: scheduledPostsStorageKey),
            let decoded = try? JSONDecoder().decode([ScheduledPostPlan].self, from: data)
        else {
            scheduledPosts = []
            return
        }
        scheduledPosts = decoded.sorted { $0.publishAt < $1.publishAt }
    }

    private func saveScheduledPosts() {
        guard let data = try? JSONEncoder().encode(scheduledPosts) else { return }
        UserDefaults.standard.set(data, forKey: scheduledPostsStorageKey)
    }

    private func loadAnalyticsSnapshots() {
        guard
            let data = UserDefaults.standard.data(forKey: analyticsSnapshotsStorageKey),
            let decoded = try? JSONDecoder().decode([AnalyticsSnapshot].self, from: data)
        else {
            analyticsSnapshots = []
            return
        }
        analyticsSnapshots = decoded
    }

    private func saveAnalyticsSnapshots() {
        guard let data = try? JSONEncoder().encode(analyticsSnapshots) else { return }
        UserDefaults.standard.set(data, forKey: analyticsSnapshotsStorageKey)
    }

    private func loadSuperFeatureSelection() {
        guard let values = UserDefaults.standard.array(forKey: superFeatureSelectionStorageKey) as? [String] else {
            enabledSuperFeatureIDs = []
            return
        }
        enabledSuperFeatureIDs = Set(values)
    }

    private func saveSuperFeatureSelection() {
        UserDefaults.standard.set(Array(enabledSuperFeatureIDs), forKey: superFeatureSelectionStorageKey)
    }

    private func loadExecutionQueueProgress() {
        guard let values = UserDefaults.standard.array(forKey: executionQueueProgressStorageKey) as? [String] else {
            completedExecutionQueueIDs = []
            return
        }
        completedExecutionQueueIDs = Set(values)
    }

    private func saveExecutionQueueProgress() {
        UserDefaults.standard.set(Array(completedExecutionQueueIDs), forKey: executionQueueProgressStorageKey)
    }

    private func loadExecutionQueueSettings() {
        executionQueueLockCompleted = UserDefaults.standard.bool(forKey: executionQueueLockStorageKey)
    }

    private func saveExecutionQueueSettings() {
        UserDefaults.standard.set(executionQueueLockCompleted, forKey: executionQueueLockStorageKey)
    }

    private func loadExecutionQueueRestorePoint() {
        guard
            let data = UserDefaults.standard.data(forKey: executionQueueRestorePointStorageKey),
            let decoded = try? JSONDecoder().decode(ExecutionQueueRestorePoint.self, from: data)
        else {
            executionQueueRestorePoint = nil
            return
        }
        executionQueueRestorePoint = decoded
    }

    private func saveExecutionQueueRestorePoint() {
        guard let point = executionQueueRestorePoint else {
            UserDefaults.standard.removeObject(forKey: executionQueueRestorePointStorageKey)
            return
        }
        guard let data = try? JSONEncoder().encode(point) else { return }
        UserDefaults.standard.set(data, forKey: executionQueueRestorePointStorageKey)
    }

    private func loadExecutionQueueSnapshots() {
        guard
            let data = UserDefaults.standard.data(forKey: executionQueueSnapshotStorageKey),
            let decoded = try? JSONDecoder().decode([ExecutionCompletionSnapshot].self, from: data)
        else {
            executionCompletionSnapshots = []
            return
        }
        executionCompletionSnapshots = decoded
    }

    private func saveExecutionQueueSnapshots() {
        guard let data = try? JSONEncoder().encode(executionCompletionSnapshots) else { return }
        UserDefaults.standard.set(data, forKey: executionQueueSnapshotStorageKey)
    }

    private func currentDayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: Date())
    }

    private func dayKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

    private func lastExecutionSnapshotDayKey() -> String? {
        UserDefaults.standard.string(forKey: executionQueueLastSnapshotDayStorageKey)
    }

    private func saveLastExecutionSnapshotDayKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: executionQueueLastSnapshotDayStorageKey)
    }

    func beginSession(provider: String) {
        let now = Date()
        session = AppSession(
            username: currentUser.username,
            handle: currentUser.handle,
            provider: provider,
            isAuthenticated: true,
            issuedAt: session?.issuedAt ?? now,
            lastValidatedAt: now
        )
        if let encoded = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(encoded, forKey: sessionStorageKey)
        }
    }

    private func restoreSession() {
#if canImport(FirebaseAuth)
        if Auth.auth().currentUser == nil {
            UserDefaults.standard.removeObject(forKey: sessionStorageKey)
            session = nil
            return
        }
#endif
        guard
            let data = UserDefaults.standard.data(forKey: sessionStorageKey),
            let decoded = try? JSONDecoder().decode(AppSession.self, from: data),
            decoded.isAuthenticated
        else {
            session = nil
            return
        }
        session = decoded
        if let existing = internalUsers.first(where: { $0.username.caseInsensitiveCompare(decoded.username) == .orderedSame }) {
            currentUser = existing
            refreshCurrentProfileMedia()
            loadSavedPosts()
            loadProfileQuoteState()
            loadProfileModeState()
            loadInterestState()
            loadReelCollections()
            loadExploreSignals()
            loadSeenStoryHandles()
            loadScheduledPosts()
            loadAnalyticsSnapshots()
            loadExecutionQueueProgress()
            loadExecutionQueueSnapshots()
            loadExecutionQueueSettings()
            loadExecutionQueueRestorePoint()
            captureExecutionCompletionSnapshotIfNeededDaily()
        }
    }

    private var engagementStorageKey: String {
        "\(engagementStoragePrefix)\(currentUser.username.lowercased())"
    }

    private func saveEngagementState() {
        let state = PersistedEngagementState(
            commentsByPost: commentsByPost.reduce(into: [:]) { $0[$1.key.uuidString] = $1.value },
            likesByPost: likesByPost.reduce(into: [:]) { $0[$1.key.uuidString] = $1.value },
            repostsByPost: repostsByPost.reduce(into: [:]) { $0[$1.key.uuidString] = $1.value }
        )
        if let encoded = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(encoded, forKey: engagementStorageKey)
        }
    }

    private func restoreEngagementState() {
        guard
            let encoded = UserDefaults.standard.data(forKey: engagementStorageKey),
            let decoded = try? JSONDecoder().decode(PersistedEngagementState.self, from: encoded)
        else {
            commentsByPost = [:]
            likesByPost = [:]
            repostsByPost = [:]
            return
        }

        commentsByPost = decoded.commentsByPost.reduce(into: [:]) { partial, pair in
            if let id = UUID(uuidString: pair.key) { partial[id] = pair.value }
        }
        likesByPost = decoded.likesByPost.reduce(into: [:]) { partial, pair in
            if let id = UUID(uuidString: pair.key) { partial[id] = pair.value }
        }
        repostsByPost = decoded.repostsByPost.reduce(into: [:]) { partial, pair in
            if let id = UUID(uuidString: pair.key) { partial[id] = pair.value }
        }
    }

    private func addActivity(type: ActivityType, detail: String) {
        let item = ActivityItem(
            id: UUID(),
            actorHandle: currentUser.handle,
            type: type,
            detail: detail,
            createdAt: Date(),
            isRead: !notificationsEnabled || isWithinQuietHours()
        )
        activityFeed.insert(item, at: 0)
    }

    private func engagementUser(for handle: String) -> PostEngagementUser {
        let display: String
        if let known = internalUsers.first(where: { $0.handle.caseInsensitiveCompare(handle) == .orderedSame }) {
            display = known.displayName
        } else {
            display = handle.replacingOccurrences(of: "@", with: "")
        }
        return PostEngagementUser(
            id: UUID(),
            handle: handle,
            displayName: display,
            profilePhotoData: profilePhoto(for: handle)
        )
    }

    private func isWithinQuietHours() -> Bool {
        guard quietHoursEnabled else { return false }
        let hour = Calendar.current.component(.hour, from: Date())
        if quietHoursStart == quietHoursEnd { return true }
        if quietHoursStart < quietHoursEnd {
            return hour >= quietHoursStart && hour < quietHoursEnd
        }
        return hour >= quietHoursStart || hour < quietHoursEnd
    }
}

#if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
import FirebaseAuth
import FirebaseFirestore
#if canImport(FirebaseCore)
import FirebaseCore
#endif

extension AppState {
    func installFirebaseAuthBridge() {
        #if canImport(FirebaseCore)
        guard FirebaseApp.app() != nil else { return }
        #endif
        firebaseSignedInUID = Auth.auth().currentUser?.uid
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                self.handleFirebaseAuthStateChange(user)
            }
        }
        reconcileFirebaseOnColdLaunch()
        Task { await AppReviewDemoAccount.ensureProvisionedIfNeeded() }
    }

    private func handleFirebaseAuthStateChange(_ user: User?) {
        if user != nil {
            firebaseSignedInUID = user?.uid
            Task { await refreshInternalAdminAccess() }
        } else {
            firebaseSignedInUID = nil
            isSessionBootstrapComplete = true
            isInternalAdminCache = false
            session = nil
            UserDefaults.standard.removeObject(forKey: AppState.sessionUserDefaultsKey)
            currentUser = AppState.makeGuestUserProfile()
        }
    }

    private func reconcileFirebaseOnColdLaunch() {
        guard Auth.auth().currentUser != nil else {
            firebaseSignedInUID = nil
            isSessionBootstrapComplete = true
            return
        }
        firebaseSignedInUID = Auth.auth().currentUser?.uid
        isSessionBootstrapComplete = false
        Task { @MainActor in
            await hydrateProfileFromFirestoreForCurrentFirebaseUser()
            await refreshInternalAdminAccess()
            isSessionBootstrapComplete = true
        }
    }

    func hydrateProfileFromFirestoreForCurrentFirebaseUser() async {
        guard let user = Auth.auth().currentUser else { return }
        let uid = user.uid
        let preserved = currentUser
        let ref = Firestore.firestore().collection(ChitChatFirestoreSchema.Collection.users).document(uid)
        let snap: DocumentSnapshot?
        do {
            snap = try await ref.getDocument()
        } catch {
            snap = nil
        }
        if let snap, snap.exists, let data = snap.data() {
            var merged = userProfileFromChitChatFirestoreData(data, uid: uid, existing: preserved)
            if preserved.username.lowercased() != "guest", merged.username.lowercased() == "user" {
                merged.username = preserved.username
                merged.handle = preserved.handle
            }
            currentUser = merged
            syncCurrentUserInDirectory()
            runPostLoginAccountDataReload()
            let provider = user.providerData.first?.providerID ?? "firebase"
            beginSession(provider: provider)
            pushChitChatUserDirectoryIfFirebaseSignedIn()
            return
        }
        if currentUser.username.lowercased() == "guest" {
            scaffoldCurrentUserFromFirebaseAuth(user: user)
        }
        syncCurrentUserInDirectory()
        runPostLoginAccountDataReload()
        if session?.isAuthenticated != true {
            beginSession(provider: user.providerData.first?.providerID ?? "firebase")
        }
        pushChitChatUserDirectoryIfFirebaseSignedIn()
    }

    private func scaffoldCurrentUserFromFirebaseAuth(user: User) {
        let email = user.email ?? ""
        let rawBase: String
        if let s = email.split(separator: "@").first, !s.isEmpty {
            rawBase = String(s)
        } else {
            rawBase = "user_\(user.uid.prefix(6))"
        }
        let cleaned = rawBase.filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "." }
        let unameRaw = cleaned.isEmpty ? "user_\(String(user.uid.prefix(8)))" : String(cleaned.prefix(30))
        let uname = unameRaw.lowercased()
        currentUser.username = uname
        currentUser.handle = "@\(uname)"
        currentUser.displayName = user.displayName ?? uname
        currentUser.enterpriseAlias = currentUser.displayName
        currentUser.accountEmail = email
        currentUser.accountPhone = Self.placeholderAccountPhoneDigits
        currentUser.followers = 0
        currentUser.verificationStatus = .unverified
        currentUser.firebaseUserId = user.uid
        if Self.isOAuthProvider(user.providerData.first?.providerID ?? ""), email.isEmpty {
            currentUser.accountEmail = Self.placeholderAccountEmail(forUsername: uname)
        }
    }

    func claimUsernameDocumentIfNeeded() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let key = currentUser.username.lowercased()
        guard !key.isEmpty, key != "guest" else { return }
        let db = Firestore.firestore()
        let ref = db.collection(ChitChatFirestoreSchema.Collection.usernames).document(key)
        do {
            let snap = try await ref.getDocument()
            if snap.exists {
                if let existing = snap.data()?["uid"] as? String, existing == uid { return }
                return
            }
            try await ref.setData(["uid": uid])
        } catch {
            // ignore
        }
    }

    func refreshInternalAdminAccess() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            isInternalAdminCache = false
            return
        }
        let ref = Firestore.firestore().collection(ChitChatFirestoreSchema.Collection.adminUsers).document(uid)
        do {
            let snap = try await ref.getDocument()
            isInternalAdminCache = snap.exists
        } catch {
            isInternalAdminCache = false
        }
    }

    func signUpWithFirebase(
        username: String,
        password: String,
        accountEmail: String,
        accountPhone: String,
        personalDisplayName: String?,
        business: BusinessRegistration?
    ) async -> String? {
        guard let cleaned = normalizedUsername(from: username) else {
            return "Username must be 3+ characters and only letters, numbers, . or _"
        }
        guard cleaned.lowercased() != "guest" else { return "That username is reserved." }
        guard !ReservedHandles.isReserved(cleaned) else {
            return "This username is reserved."
        }
        guard password.count >= 8 else {
            return "Password must be at least 8 characters."
        }
        let trimmedEmail = accountEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if let err = validateAccountEmail(trimmedEmail) { return err }
        if business == nil {
            let p = accountPhone.filter(\.isNumber)
            if !p.isEmpty, p.count < 10 { return "Phone number must include at least 10 digits if provided." }
            if !p.isEmpty, p == Self.placeholderAccountPhoneDigits { return "Enter a real phone number (not placeholder digits)." }
        }
        let key = cleaned.lowercased()
        if internalUsers.contains(where: { $0.username.lowercased() == key }) {
            return "Username already exists."
        }
        if let registration = business {
            if let err = validateBusinessRegistration(registration) { return err }
        }

        let db = Firestore.firestore()
        let unameRef = db.collection(ChitChatFirestoreSchema.Collection.usernames).document(key)
        do {
            let preSnap = try await unameRef.getDocument()
            if preSnap.exists {
                return "Username already taken."
            }
        } catch {
            return "Could not verify username. Check your connection and try again."
        }

        do {
            let authResult = try await Auth.auth().createUser(withEmail: trimmedEmail, password: password)
            let uid = authResult.user.uid
            do {
                try await unameRef.setData(["uid": uid])
            } catch {
                try? await authResult.user.delete()
                return "Could not reserve username. Try a different one."
            }

            clearBusinessRegistrationOnCurrentUser()
            var base = UserProfile(
                id: UUID(),
                username: cleaned,
                handle: "@\(cleaned)",
                accountEmail: trimmedEmail,
                accountPhone: "",
                enterpriseAlias: cleaned,
                displayName: cleaned,
                followers: 0,
                verificationStatus: .unverified,
                allowEnterpriseReveal: false,
                linkedPlatforms: []
            )
            base.firebaseUserId = uid
            currentUser = base

            if let registration = business {
                applyBusinessRegistration(registration)
                currentUser.username = cleaned
                currentUser.handle = "@\(cleaned)"
                currentUser.accountEmail = trimmedEmail
                currentUser.firebaseUserId = uid
                currentUser.accountPhone = registration.phone.filter(\.isNumber)
                guard currentUser.accountPhone.count >= 10 else {
                    try? await authResult.user.delete()
                    try? await unameRef.delete()
                    return "Enter a valid business phone (10+ digits)."
                }
                guard currentUser.accountPhone != Self.placeholderAccountPhoneDigits else {
                    try? await authResult.user.delete()
                    try? await unameRef.delete()
                    return "Enter a real business phone number."
                }
            } else {
                let rawName = personalDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if rawName.isEmpty {
                    currentUser.displayName = cleaned
                    currentUser.enterpriseAlias = cleaned
                } else {
                    currentUser.displayName = rawName
                    currentUser.enterpriseAlias = rawName
                }
                let phoneDigits = accountPhone.filter(\.isNumber)
                currentUser.accountPhone = phoneDigits.isEmpty ? Self.placeholderAccountPhoneDigits : phoneDigits
            }
            registerLoggedInAccount(cleaned)
            syncCurrentUserInDirectory()
            pushChitChatUserDirectoryIfFirebaseSignedIn()
            isSessionBootstrapComplete = false
            runPostLoginAccountDataReload()
            beginSession(provider: "password")
            firebaseSignedInUID = uid
            await hydrateProfileFromFirestoreForCurrentFirebaseUser()
            await refreshInternalAdminAccess()
            isSessionBootstrapComplete = true
            return nil
        } catch {
            isSessionBootstrapComplete = true
            return error.localizedDescription
        }
    }

    func logInWithFirebase(email: String, password: String) async -> String? {
        let em = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if let err = validateAccountEmail(em) { return err }
        isSessionBootstrapComplete = false
        do {
            let r = try await Auth.auth().signIn(withEmail: em, password: password)
            firebaseSignedInUID = r.user.uid
            await hydrateProfileFromFirestoreForCurrentFirebaseUser()
            await refreshInternalAdminAccess()
            registerLoggedInAccount(currentUser.username)
            isSessionBootstrapComplete = true
            return nil
        } catch {
            isSessionBootstrapComplete = true
            return error.localizedDescription
        }
    }
}
#endif

struct CreatorInsights {
    var totalPosts: Int
    var totalLikes: Int
    var totalComments: Int
    var totalReposts: Int
    var totalSaves: Int
    var engagementScore: Int
}

struct WeeklyGrowthInsights {
    var newPosts: Int
    var newLikes: Int
    var newComments: Int
    var growthScore: Int
}
