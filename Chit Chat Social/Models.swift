import Foundation

enum PlatformMode: String, CaseIterable, Codable {
    case social
    case enterprise
}

/// Instagram-style verification category for request form.
enum VerificationCategory: String, CaseIterable, Codable, Identifiable {
    case creator
    case athlete
    case business
    case journalist
    case newsOrganization = "news_org"
    case government = "govt"
    case brand
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .creator: return "Creator"
        case .athlete: return "Athlete"
        case .business: return "Business"
        case .journalist: return "Journalist"
        case .newsOrganization: return "News Organization"
        case .government: return "Government"
        case .brand: return "Brand"
        case .other: return "Other"
        }
    }
}

enum SocialPlatform: String, CaseIterable, Codable, Identifiable {
    case instagram
    case snapchat
    case facebook
    case threads
    case x
    case youtube
    case linkedin

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .snapchat: return "Snapchat"
        case .facebook: return "Facebook"
        case .threads: return "Threads"
        case .x: return "X / Twitter"
        case .youtube: return "YouTube"
        case .linkedin: return "LinkedIn"
        }
    }
}

enum ContentType: String, CaseIterable, Codable {
    case post
    case reel
    case story
    case shortVideo
}

enum PostSurfaceStyle: String, CaseIterable, Codable {
    case chit
    case chat
}

enum FeedSortMode: String, CaseIterable, Codable {
    case latest
    case trending
    case rising

    /// Short label for compact controls (HIG-friendly tap targets use full words).
    var displayTitle: String {
        switch self {
        case .latest: return "Latest"
        case .trending: return "Trending"
        case .rising: return "Rising"
        }
    }
}

/// Which slice of the graph the home feed shows (was fileprivate on Home).
enum FeedLens: String, CaseIterable, Codable, Identifiable, Hashable {
    case forYou
    case following
    case closeFriends

    var id: String { rawValue }

    var label: String {
        switch self {
        case .forYou: return "For You"
        case .following: return "Following"
        case .closeFriends: return "Close Friends"
        }
    }

    var systemImage: String {
        switch self {
        case .forYou: return "sparkles"
        case .following: return "person.2.fill"
        case .closeFriends: return "lock.fill"
        }
    }
}

enum AppAppearance: String, CaseIterable, Codable {
    case system
    case auto
    case light
    case dark
}

struct MonetizationInsights {
    var sponsoredPosts: Int
    var estimatedReach: Int
    var estimatedRevenueUSD: Double
}

struct PayoutForecast {
    var nextDayUSD: Double
    var nextWeekUSD: Double
    var nextMonthUSD: Double
}

struct ScheduledPostPlan: Identifiable, Codable {
    let id: UUID
    var caption: String
    var publishAt: Date
    var surfaceStyle: PostSurfaceStyle
    var includesImage: Bool
    var cadence: ScheduleCadence
    var priority: Int = 50
    var skipDateKeys: [String] = []
}

enum ScheduleCadence: String, CaseIterable, Codable, Identifiable {
    case once
    case daily
    case weekly
    case monthly
    var id: String { rawValue }
}

struct AnalyticsSnapshot: Identifiable, Codable {
    let id: UUID
    var createdAt: Date
    var likes: Int
    var comments: Int
    var reposts: Int
    var saves: Int
    var estimatedRevenueUSD: Double
}

struct EnterpriseReportCard: Identifiable {
    let id: UUID
    var title: String
    var summary: String
    var metricLine: String
}

struct WeekdayPerformance: Identifiable {
    let id: UUID
    var weekday: String
    var score: Double
}

enum SchedulePriorityPreset: String, CaseIterable, Identifiable {
    case balanced
    case aggressive
    case quality
    var id: String { rawValue }
}

enum QueueItemStatus: String, Codable {
    case pending
    case completed
}

struct ExecutionQueueItem: Identifiable {
    let id: String
    var order: Int
    var title: String
    var summary: String
    var status: QueueItemStatus
}

struct ExecutionCompletionSnapshot: Identifiable, Codable {
    let id: UUID
    var createdAt: Date
    var completedCount: Int
    var totalCount: Int
    var completionPercent: Double
}

struct ExecutionDeltaSummary {
    var latestCompleted: Int
    var previousCompleted: Int
    var deltaCompleted: Int
    var latestPercent: Double
}

struct ExecutionQueueRestorePoint: Codable {
    var createdAt: Date
    var completedIDs: [String]
    var completedCount: Int
    var label: String
}

enum StoryAudience: String, CaseIterable, Codable {
    case `public` = "Public"
    case closeFriends = "Close Friends"
}

enum PostAudience: String, CaseIterable, Codable {
    case `public` = "Public"
    case followers = "Followers"
    case closeFriends = "Close Friends"
}

enum VerificationStatus: String, Codable {
    case unverified
    case pending
    case paid
    case verifiedInternal
}

struct AppSession: Codable, Equatable {
    var username: String
    var handle: String
    var provider: String
    var isAuthenticated: Bool
    var issuedAt: Date
    var lastValidatedAt: Date
}

struct BusinessRegistration: Equatable, Sendable {
    var ein: String
    var legalName: String
    var dba: String
    var addressLine1: String
    var city: String
    var state: String
    var zip: String
    var phone: String
    var website: String
}

struct UserProfile: Identifiable, Codable {
    let id: UUID
    var username: String
    var handle: String
    var enterpriseAlias: String
    var displayName: String
    var profileQuote: String = ""
    var isProfileQuoteVisible: Bool = true
    var profileLinkURL: String = ""
    var followers: Int
    var verificationStatus: VerificationStatus
    var allowEnterpriseReveal: Bool
    var linkedPlatforms: [SocialPlatform]
    /// Business accounts must be approved to post jobs.
    var isBusinessAccount: Bool = false
    var businessJobPostingApproved: Bool = false
    /// U.S. EIN formatted as XX-XXXXXXX when provided.
    var businessEIN: String = ""
    var businessLegalName: String = ""
    var businessDBA: String = ""
    var businessAddressLine1: String = ""
    var businessCity: String = ""
    var businessState: String = ""
    var businessZIP: String = ""
    var businessPhone: String = ""
    var businessWebsite: String = ""
}

struct PostItem: Identifiable, Codable {
    let id: UUID
    let authorHandle: String
    var caption: String
    let type: ContentType
    let createdAt: Date
    var city: String
    var imageData: Data?
    /// Local video bytes for reels / stories / short video (thumbnail stays in `imageData`).
    var videoData: Data? = nil
    var likeCount: Int = 0
    var commentCount: Int = 0
    var areLikesHidden: Bool = false
    var areCommentsHidden: Bool = false
    var isArchived: Bool = false
    var repostCount: Int = 0
    var saveCount: Int = 0
    var storyAudience: StoryAudience = .public
    var audience: PostAudience = .public
    var isCollab: Bool
    var surfaceStyle: PostSurfaceStyle = .chit
    var taggedHandles: [String] = []
    var combinedOwnerHandle: String? = nil
    /// When true, feed shows an opaque warning before revealing caption/media (violent news / graphic).
    var violenceWarningRequired: Bool = false
}

struct CombinedPostRequest: Identifiable, Codable {
    let id: UUID
    var fromHandle: String
    var toHandle: String
    var caption: String
    var imageData: Data?
    var surfaceStyle: PostSurfaceStyle
    var createdAt: Date
}

struct PostComment: Identifiable, Codable {
    let id: UUID
    var postID: UUID
    var authorHandle: String
    var text: String
    var createdAt: Date
}

struct PostEngagementUser: Identifiable, Codable {
    let id: UUID
    var handle: String
    var displayName: String
    var profilePhotoData: Data?
}

struct PersistedEngagementState: Codable {
    var commentsByPost: [String: [PostComment]]
    var likesByPost: [String: [PostEngagementUser]]
    var repostsByPost: [String: [PostEngagementUser]]
}

enum ActivityType: String, Codable, CaseIterable, Hashable {
    case like
    case comment
    case follow
    case repost
    case save
    case message
    case verification
    /// Trust & safety — strikes, suspensions, policy email confirmations.
    case moderation
}

struct ActivityItem: Identifiable, Codable {
    let id: UUID
    var actorHandle: String
    var type: ActivityType
    var detail: String
    var createdAt: Date
    var isRead: Bool
}

struct StoryItem: Identifiable, Codable {
    let id: UUID
    let authorHandle: String
    let title: String
    let createdAt: Date
}

enum VerificationRequestStatus: String, Codable, CaseIterable {
    case pending
    case approved
    case declined
}

struct VerificationRequest: Identifiable, Codable {
    let id: UUID
    var username: String
    var handle: String
    var note: String
    var hasInstagramVerification: Bool
    var requestedAt: Date
    var status: VerificationRequestStatus
    var reviewerNote: String
    var category: VerificationCategory = .creator

    enum CodingKeys: String, CodingKey {
        case id, username, handle, note, hasInstagramVerification, requestedAt, status, reviewerNote, category
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        username = try c.decode(String.self, forKey: .username)
        handle = try c.decode(String.self, forKey: .handle)
        note = try c.decode(String.self, forKey: .note)
        hasInstagramVerification = try c.decode(Bool.self, forKey: .hasInstagramVerification)
        requestedAt = try c.decode(Date.self, forKey: .requestedAt)
        status = try c.decode(VerificationRequestStatus.self, forKey: .status)
        reviewerNote = try c.decode(String.self, forKey: .reviewerNote)
        category = try c.decodeIfPresent(VerificationCategory.self, forKey: .category) ?? .creator
    }

    init(id: UUID, username: String, handle: String, note: String, hasInstagramVerification: Bool, requestedAt: Date, status: VerificationRequestStatus, reviewerNote: String, category: VerificationCategory = .creator) {
        self.id = id
        self.username = username
        self.handle = handle
        self.note = note
        self.hasInstagramVerification = hasInstagramVerification
        self.requestedAt = requestedAt
        self.status = status
        self.reviewerNote = reviewerNote
        self.category = category
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(username, forKey: .username)
        try c.encode(handle, forKey: .handle)
        try c.encode(note, forKey: .note)
        try c.encode(hasInstagramVerification, forKey: .hasInstagramVerification)
        try c.encode(requestedAt, forKey: .requestedAt)
        try c.encode(status, forKey: .status)
        try c.encode(reviewerNote, forKey: .reviewerNote)
        try c.encode(category, forKey: .category)
    }
}

enum MessageDeliveryState: String, Codable {
    case sent
    case delivered
    case seen
}

enum MessageContentKind: String, Codable {
    case text
    case media
    case voice
    case system
}

struct MessageItem: Identifiable, Codable {
    let id: UUID
    let senderHandle: String
    let text: String
    let sentAt: Date
    var kind: MessageContentKind = .text
    var delivery: MessageDeliveryState = .sent
    /// Violent / breaking-news phrasing — chat bubble shows consent overlay before text.
    var requiresViolenceWarning: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, senderHandle, text, sentAt, kind, delivery, requiresViolenceWarning
    }

    init(
        id: UUID,
        senderHandle: String,
        text: String,
        sentAt: Date,
        kind: MessageContentKind = .text,
        delivery: MessageDeliveryState = .sent,
        requiresViolenceWarning: Bool = false
    ) {
        self.id = id
        self.senderHandle = senderHandle
        self.text = text
        self.sentAt = sentAt
        self.kind = kind
        self.delivery = delivery
        self.requiresViolenceWarning = requiresViolenceWarning
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        senderHandle = try c.decode(String.self, forKey: .senderHandle)
        text = try c.decode(String.self, forKey: .text)
        sentAt = try c.decode(Date.self, forKey: .sentAt)
        kind = try c.decodeIfPresent(MessageContentKind.self, forKey: .kind) ?? .text
        delivery = try c.decodeIfPresent(MessageDeliveryState.self, forKey: .delivery) ?? .sent
        requiresViolenceWarning = try c.decodeIfPresent(Bool.self, forKey: .requiresViolenceWarning) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(senderHandle, forKey: .senderHandle)
        try c.encode(text, forKey: .text)
        try c.encode(sentAt, forKey: .sentAt)
        try c.encode(kind, forKey: .kind)
        try c.encode(delivery, forKey: .delivery)
        try c.encode(requiresViolenceWarning, forKey: .requiresViolenceWarning)
    }
}

struct ChatThread: Identifiable, Codable {
    let id: UUID
    let title: String
    var messages: [MessageItem]
}

enum CallRoomMode: String, Codable, CaseIterable {
    case oneOnOne
    case groupDJ
    case executive
}

struct CallRoom: Identifiable, Codable {
    let id: UUID
    let roomName: String
    let mode: CallRoomMode
    var participants: [String]
    var isScreenSharingEnabled: Bool
}

enum CorporateCallRole: String, CaseIterable, Codable, Identifiable {
    case host
    case presenter
    case moderator
    case listener
    var id: String { rawValue }
}

struct CorporateMeetingRoom: Identifiable, Codable {
    let id: UUID
    var title: String
    var participantHandles: [String]
    var activeAgenda: String
}

struct LiveCommentItem: Identifiable, Codable {
    let id: UUID
    var authorHandle: String
    var text: String
    var createdAt: Date
}

enum SocialLiveAudienceRole: String, CaseIterable, Codable, Identifiable {
    case viewer
    case supporter
    case vip
    case moderator
    var id: String { rawValue }
}

struct MonetizationStrategyCard: Identifiable {
    let id: UUID
    var title: String
    var action: String
    var targetMetric: String
}

struct CollabMatchSuggestion: Identifiable {
    let id: UUID
    var handle: String
    var reason: String
    var score: Int
}

struct SongQueueItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let artist: String
    let requestedBy: String
}

struct ResumeProfile: Codable {
    var headline: String
    var skills: [String]
    var yearsExperience: Int
}

struct ContractDeal: Identifiable, Codable {
    let id: UUID
    var title: String
    var budgetUSD: Int
    var location: String
    var isLocalHire: Bool
    var authorHandle: String
    var isPendingApproval: Bool

    init(id: UUID, title: String, budgetUSD: Int, location: String, isLocalHire: Bool, authorHandle: String = "", isPendingApproval: Bool = false) {
        self.id = id
        self.title = title
        self.budgetUSD = budgetUSD
        self.location = location
        self.isLocalHire = isLocalHire
        self.authorHandle = authorHandle
        self.isPendingApproval = isPendingApproval
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        budgetUSD = try c.decode(Int.self, forKey: .budgetUSD)
        location = try c.decode(String.self, forKey: .location)
        isLocalHire = try c.decode(Bool.self, forKey: .isLocalHire)
        authorHandle = try c.decodeIfPresent(String.self, forKey: .authorHandle) ?? ""
        isPendingApproval = try c.decodeIfPresent(Bool.self, forKey: .isPendingApproval) ?? false
    }

    enum CodingKeys: String, CodingKey {
        case id, title, budgetUSD, location, isLocalHire, authorHandle, isPendingApproval
    }
}

struct MarketListing: Identifiable, Codable {
    let id: UUID
    var title: String
    var priceUSD: Int
    var seller: String
    var category: String
}

struct CommunityGroup: Identifiable, Codable {
    let id: UUID
    var name: String
    var summary: String
    var creator: String
    var managers: [String]
    var isPublic: Bool
    var requiresPassword: Bool
}

struct ShopProduct: Identifiable, Codable {
    let id: UUID
    var sellerHandle: String
    var title: String
    var description: String
    var priceUSD: Int
    var imageSystemName: String
    var isDropshipEnabled: Bool
}

struct LiveShopSession: Identifiable, Codable {
    let id: UUID
    var hostHandle: String
    var productID: UUID
    var headline: String
    var viewerCount: Int
}

enum MusicSource: String, CaseIterable, Codable {
    case appleMusic
    case spotify
    case youtube

    var displayName: String {
        switch self {
        case .appleMusic: return "Apple Music"
        case .spotify: return "Spotify"
        case .youtube: return "YouTube"
        }
    }
}

struct MusicTrack: Identifiable, Codable {
    let id: UUID
    var title: String
    var artist: String
    var source: MusicSource
    var bundledFileName: String
}

struct PublicPulsePost: Identifiable, Codable {
    let id: UUID
    var authorHandle: String
    var text: String
    var imageSystemName: String?
    var createdAt: Date
    /// AI flagged violent / disturbing news — Search shows consent gate.
    var violenceWarningRequired: Bool = false
}

struct SuggestedConnection: Identifiable {
    let user: UserProfile
    let mutualCount: Int
    var id: UUID { user.id }
}

struct InboxNote: Identifiable, Codable {
    let id: UUID
    var authorHandle: String
    var text: String
    var createdAt: Date
}

struct BroadcastChannel: Identifiable, Codable {
    let id: UUID
    var title: String
    var ownerHandle: String
    var memberCount: Int
    var latestMessage: String
}

struct DMRequest: Identifiable, Codable {
    let id: UUID
    var fromHandle: String
    var previewText: String
    var createdAt: Date
}
