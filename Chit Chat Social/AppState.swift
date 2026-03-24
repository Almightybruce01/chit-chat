import Foundation
import SwiftUI
import AVFoundation
import UIKit

@MainActor
final class AppState: ObservableObject {
    private let backend: BackendServicing
    private let credentialsStorageKey = "chitchat.local.credentials"
    private let loggedInAccountsKey = "chitchat.logged.accounts"
    private let recentSearchesStorageKey = "chitchat.recent.searches"
    private let savedPostsStoragePrefix = "chitchat.saved.posts."
    private let sessionStorageKey = "chitchat.session.v1"
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
    @Published var currentUser = UserProfile(
        id: UUID(),
        username: "Almighty_Bruce_",
        handle: "@Almighty_Bruce_",
        enterpriseAlias: "Brian B.",
        displayName: "Brian Bruce",
        followers: 1875,
        verificationStatus: .verifiedInternal,
        allowEnterpriseReveal: false,
        linkedPlatforms: [.instagram, .youtube]
    )

    @Published var posts: [PostItem] = [
        PostItem(
            id: UUID(),
            authorHandle: "@chitchatsocial",
            caption: "Welcome to the ultimate social media app.",
            type: .post,
            createdAt: Date(),
            city: "Dallas",
            isCollab: false
        ),
        PostItem(
            id: UUID(),
            authorHandle: "@djmike",
            caption: "Going live tonight. Song queue is open.",
            type: .reel,
            createdAt: Date().addingTimeInterval(-1800),
            city: "Dallas",
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
    @Published var isLiveNow = false
    @Published var liveViewerCount = 0
    @Published var liveComments: [LiveCommentItem] = []
    @Published var liveCoHosts: [String] = ["@creatorone"]
    @Published var audienceRoleByHandle: [String: SocialLiveAudienceRole] = [:]

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
    @Published var localCity = "Dallas"
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
        "@chitchat": ["@creatorone", "@coachmia", "@djmike", "@streetvault", "@almighty_bruce_"],
        "@creatorone": ["@chitchat", "@djmike", "@coachmia", "@almighty_bruce_"],
        "@coachmia": ["@chitchat", "@creatorone", "@dallasbiz", "@almighty_bruce_"],
        "@djmike": ["@chitchat", "@creatorone", "@streetvault", "@almighty_bruce_"]
    ]

    var canAccessInternalDashboard: Bool {
        ["almighty_bruce_", "admin", "owner"].contains(currentUser.username.lowercased())
    }
    @Published var resume = ResumeProfile(
        headline: "Creator, producer, and community builder",
        skills: ["Content Strategy", "Live Production", "Brand Partnerships"],
        yearsExperience: 4
    )
    @Published var contracts: [ContractDeal] = [
        ContractDeal(id: UUID(), title: "Event DJ Host", budgetUSD: 1200, location: "Dallas", isLocalHire: true),
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
            currentUser,
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
        loadProfilePhotoMap()
        loadLoggedInAccounts()
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
        if completedExecutionQueueIDs.count < 1000 {
            markAllExecutionItemsComplete()
        }
        captureExecutionCompletionSnapshotIfNeededDaily()
        if enabledSuperFeatureIDs.isEmpty {
            enableAllSuperFeatures()
        }
        ensurePostMediaCoverage()
        if localCredentials[currentUser.username.lowercased()] == nil {
            localCredentials[currentUser.username.lowercased()] = "Yzesati01!"
            saveCredentials()
        }
        registerLoggedInAccount(currentUser.username)
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
            for postIndex in 1...10 {
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
                        city: "Dallas",
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
        combinedOwnerHandle: String? = nil
    ) -> ModerationResult {
        clearExpiredPolicyBanIfNeeded()
        if isPolicySuspendedNow {
            return ModerationResult(
                label: .accountSuspended,
                reason: policySuspensionUserMessage
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
            let created = PostItem(
                id: UUID(),
                authorHandle: currentUser.handle,
                caption: caption,
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
                violenceWarningRequired: violenceWarning
            )
            posts.insert(created, at: 0)
            newPost = created
            moderationEvents.insert(moderationResult.reason, at: 0)
            if violenceWarning {
                notifyPosterViolenceWarningPosted()
            }
        case .missingRequiredMedia, .accountSuspended:
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

    func startLiveSession(headline: String) {
        isLiveNow = true
        liveViewerCount = Int.random(in: 44...320)
        liveComments = [
            LiveCommentItem(id: UUID(), authorHandle: "@fan_live", text: "We are in!", createdAt: Date()),
            LiveCommentItem(id: UUID(), authorHandle: "@creatorone", text: "Drop the product link 🔥", createdAt: Date().addingTimeInterval(-20))
        ]
        addActivity(type: .message, detail: "Started live: \(headline)")
    }

    func endLiveSession() {
        isLiveNow = false
    }

    func postLiveComment(_ text: String, from handle: String? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        liveComments.insert(
            LiveCommentItem(
                id: UUID(),
                authorHandle: handle ?? currentUser.handle,
                text: trimmed,
                createdAt: Date()
            ),
            at: 0
        )
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

    func requestPaidVerification() {
        guard currentUser.verificationStatus != .verifiedInternal else { return }
        currentUser.verificationStatus = .paid
        syncCurrentUserInDirectory()
    }

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
            return (true, "Job post submitted for approval. You'll be notified when it's reviewed.")
        }
        return (true, "Contract published.")
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
        case .manualReview, .accountSuspended, .missingRequiredMedia:
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
        let candidates = internalUsers.filter {
            $0.handle != currentUser.handle
            && !myFollowing.contains($0.handle)
            && !isBlocked($0.handle)
        }

        let suggestions = candidates.map { user in
            let userFollowing = socialGraph[user.handle, default: []]
            let mutual = myFollowing.intersection(userFollowing).count
            return SuggestedConnection(user: user, mutualCount: mutual)
        }
        .sorted { lhs, rhs in
            if lhs.mutualCount == rhs.mutualCount {
                return lhs.user.followers > rhs.user.followers
            }
            return lhs.mutualCount > rhs.mutualCount
        }

        return Array(suggestions.prefix(limit))
    }

    func syncContacts(displayNames: [String], identifiers: [String]) {
        let lowered = displayNames.map { $0.lowercased() }
        let matches = internalUsers.filter { user in
            lowered.contains(where: { contact in
                user.displayName.lowercased() == contact
                || user.username.lowercased() == contact
                || user.handle.lowercased().contains(contact)
            })
        }
        matchedContactHandles = Set(matches.map(\.handle))
        contactsSyncStatus = matches.isEmpty
            ? "No matching contacts found in Chit Chat Social yet."
            : "Found \(matches.count) contacts on Chit Chat Social."
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
            scoped = visible.filter { $0.city.caseInsensitiveCompare(localCity) == .orderedSame }
        }
        let tuned = scoped.sorted { interestMatchScore(for: $0) > interestMatchScore(for: $1) }
        return sortFeed(tuned, sortMode: sortMode)
    }

    func closeFriendsFeedPosts(sortMode: FeedSortMode = .latest) -> [PostItem] {
        let scoped = posts.filter { post in
            !post.isArchived
            && canViewPost(post)
            && (closeFriendsHandles.contains(post.authorHandle) || post.authorHandle == currentUser.handle)
        }
        return sortFeed(scoped, sortMode: sortMode)
    }

    private func interestMatchScore(for post: PostItem) -> Double {
        let tokens = activeInterests
        guard !tokens.isEmpty else { return 0 }
        let haystack = "\(post.caption) \(post.city) \(post.authorHandle) \(post.type.rawValue)".lowercased()
        let hits = tokens.filter { haystack.contains($0) }.count
        return Double(hits) * 5.0
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
        case .manualReview, .accountSuspended, .missingRequiredMedia:
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
            type: .post,
            createdAt: Date(),
            city: localCity,
            imageData: source.imageData,
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
            taggedHandles: source.taggedHandles,
            combinedOwnerHandle: source.combinedOwnerHandle,
            violenceWarningRequired: violence
        )
        posts.insert(reposted, at: 0)
        addActivity(type: .repost, detail: firstTimeRepost ? "Reposted \(source.authorHandle)'s post." : "Re-shared \(source.authorHandle)'s post.")
        saveEngagementState()
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
        case .manualReview, .accountSuspended, .missingRequiredMedia:
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
        case .manualReview, .accountSuspended, .missingRequiredMedia:
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
            return "\(trimmed)\n\n#ChitChat #Conversation"
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
            $0.caption.localizedCaseInsensitiveContains("http://")
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
        let variantA = "\(stem)\n\n\(surface == .chat ? "#ChitChat #Discuss" : "#Chit #Create")"
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
    }

    func markVerificationEmailSent() {
        emailVerificationSent = true
    }

    func completeProviderLogin(username: String, provider: String) -> String? {
        guard let cleaned = normalizedUsername(from: username) else {
            return "Enter a valid unique username (3+ chars, letters/numbers/._)."
        }
        guard !ReservedHandles.isReserved(cleaned) else {
            return "This username is reserved."
        }
        if let existing = internalUsers.first(where: { $0.username.caseInsensitiveCompare(cleaned) == .orderedSame }) {
            currentUser = existing
        } else {
            currentUser.username = cleaned
            currentUser.handle = "@\(cleaned)"
            currentUser.displayName = cleaned
            syncCurrentUserInDirectory()
        }
        registerLoggedInAccount(cleaned)
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
        return nil
    }

    func endSession() {
        session = nil
        UserDefaults.standard.removeObject(forKey: sessionStorageKey)
    }

    func signUp(username: String, password: String) -> String? {
        guard let cleaned = normalizedUsername(from: username) else {
            return "Username must be 3+ characters and only letters, numbers, . or _"
        }
        guard !ReservedHandles.isReserved(cleaned) else {
            return "This username is reserved."
        }
        guard password.count >= 8 else {
            return "Password must be at least 8 characters."
        }
        let key = cleaned.lowercased()
        if localCredentials[key] != nil {
            return "Username already exists."
        }
        if internalUsers.contains(where: { $0.username.lowercased() == key }) {
            return "Username already exists."
        }
        localCredentials[key] = password
        saveCredentials()
        currentUser.username = cleaned
        currentUser.handle = "@\(cleaned)"
        currentUser.verificationStatus = cleaned.lowercased() == "almighty_bruce_" ? .verifiedInternal : .unverified
        registerLoggedInAccount(cleaned)
        syncCurrentUserInDirectory()
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
        beginSession(provider: "local")
        return nil
    }

    func logIn(username: String, password: String) -> String? {
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
        beginSession(provider: "local")
        return nil
    }

    @discardableResult
    func switchToAccount(username: String) -> Bool {
        let key = username.lowercased()
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
        if currentUser.handle.caseInsensitiveCompare(handle) == .orderedSame {
            if mode == .enterprise {
                return currentUser.displayName
            }
            return currentUser.handle.replacingOccurrences(of: "@", with: "")
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

    private func beginSession(provider: String) {
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
