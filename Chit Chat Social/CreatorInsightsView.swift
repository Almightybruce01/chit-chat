import SwiftUI

struct CreatorInsightsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let insights = appState.creatorInsights()
        let weekly = appState.weeklyGrowthInsights()
        let topPosts = appState.topPerformingPosts(limit: 5)
        let audienceMix = audienceBreakdown
        ZStack {
            EliteBackground()
            List {
                Section("Overview") {
                    insightRow("Posts", "\(insights.totalPosts)")
                    insightRow("Likes", "\(insights.totalLikes)")
                    insightRow("Comments", "\(insights.totalComments)")
                    insightRow("Reposts", "\(insights.totalReposts)")
                    insightRow("Saves", "\(insights.totalSaves)")
                    insightRow("Engagement", "\(insights.engagementScore)")
                }
                Section("Top Performing Posts") {
                    if topPosts.isEmpty {
                        Text("Create content to unlock analytics.")
                            .foregroundStyle(secondaryText)
                    } else {
                        ForEach(topPosts) { post in
                            let score = post.likeCount + post.commentCount + post.repostCount + post.saveCount
                            VStack(alignment: .leading, spacing: 6) {
                                Text(post.caption)
                                    .lineLimit(2)
                                    .foregroundStyle(primaryText)
                                HStack {
                                    Text("Score \(score)")
                                        .font(.caption)
                                        .foregroundStyle(BrandPalette.neonGreen)
                                    Spacer()
                                    Text(post.createdAt, style: .relative)
                                        .font(.caption2)
                                        .foregroundStyle(secondaryText)
                                }
                                GeometryReader { geo in
                                    let width = max(14, min(geo.size.width, CGFloat(score * 4)))
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [BrandPalette.neonBlue, BrandPalette.neonGreen],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: width, height: 8)
                                }
                                .frame(height: 8)
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
                Section("Weekly Growth") {
                    insightRow("New posts (7d)", "\(weekly.newPosts)")
                    insightRow("New likes (7d)", "\(weekly.newLikes)")
                    insightRow("New comments (7d)", "\(weekly.newComments)")
                    insightRow("Growth score", "\(weekly.growthScore)")
                }
                Section("Audience Mix") {
                    insightRow("Public", "\(audienceMix.publicCount)")
                    insightRow("Followers", "\(audienceMix.followersCount)")
                    insightRow("Close Friends", "\(audienceMix.closeFriendsCount)")
                }
                Section("Tips") {
                    Text("Post consistently in your strongest niche.")
                    Text("Save-worthy content increases long-term reach.")
                    Text("Reposts are a signal for distribution momentum.")
                }
                .foregroundStyle(primaryText)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Creator Insights")
    }

    private func insightRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(secondaryText)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundStyle(primaryText)
        }
    }

    private var primaryText: Color {
        BrandPalette.adaptiveTextPrimary(for: colorScheme)
    }

    private var secondaryText: Color {
        BrandPalette.adaptiveTextSecondary(for: colorScheme)
    }

    private var audienceBreakdown: (publicCount: Int, followersCount: Int, closeFriendsCount: Int) {
        let mine = appState.posts.filter { $0.authorHandle == appState.currentUser.handle && !$0.isArchived }
        let publicCount = mine.filter { $0.audience == .public }.count
        let followersCount = mine.filter { $0.audience == .followers }.count
        let closeFriendsCount = mine.filter { $0.audience == .closeFriends }.count
        return (publicCount, followersCount, closeFriendsCount)
    }
}
