//
//  SearchView.swift
//  Chit Chat Social
//
//  Created by Brian Bruce on 2025-06-24.
//

import SwiftUI

private enum SearchScope: String, CaseIterable, Identifiable {
    case all = "All"
    case posts = "Posts"
    case videos = "Videos"
    case profiles = "Profiles"
    case communities = "Groups"
    case shop = "Shop"
    case music = "Music"
    case pulse = "Pulse"

    var id: String { rawValue }
}

private enum DiscoverTab: String, CaseIterable, Identifiable {
    case forYou = "For You"
    case accounts = "Accounts"
    case audio = "Audio"
    var id: String { rawValue }
}

struct SearchView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var query = ""
    @State private var selectedScope: SearchScope = .all
    @State private var discoverTab: DiscoverTab = .forYou
    @State private var selectedPost: PostItem?
    @State private var showInterestTuning = false
    @State private var showRankingControls = false
    @State private var preferDiversity = true
    @State private var prioritizeFreshness = true
    @State private var minimumExploreScore: Double = 0
    private let gridColumns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
    private var primaryText: Color { BrandPalette.adaptiveTextPrimary(for: colorScheme) }
    private var secondaryText: Color { BrandPalette.adaptiveTextSecondary(for: colorScheme) }

    var body: some View {
        NavigationStack {
            ZStack {
                EliteBackground()
                ScrollView {
                    VStack(spacing: 12) {
                        searchBar
                        topDiscoverTabs
                        HStack {
                            Button {
                                showRankingControls.toggle()
                            } label: {
                                Label(showRankingControls ? "Hide Ranking" : "Ranking", systemImage: "dial.high")
                                    .font(.caption.bold())
                            }
                            .buttonStyle(.bordered)
                            Spacer()
                            Button {
                                showInterestTuning = true
                            } label: {
                                Label("Tune Interests", systemImage: "slider.horizontal.3")
                                    .font(.caption.bold())
                            }
                            .buttonStyle(.bordered)
                        }
                        if showRankingControls {
                            rankingControlCard
                        }
                        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            recentSection
                        }
                        scopeChips
                        content
                    }
                    .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                    .padding(.horizontal, LayoutTokens.screenHorizontal)
                    .padding(.top, 10)
                }
            }
            .navigationTitle(appState.mode == .social ? "Search" : "Market")
            .sheet(item: $selectedPost) { post in
                NavigationStack {
                    ZStack {
                        EliteBackground()
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                if let data = post.imageData, let image = UIImage(data: data) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                Text(post.authorHandle)
                                    .font(.headline)
                                    .foregroundStyle(primaryText)
                                Text(post.caption)
                                    .foregroundStyle(primaryText)
                            }
                            .padding()
                        }
                    }
                    .navigationTitle("Preview")
                }
            }
            .sheet(isPresented: $showInterestTuning) {
                NavigationStack {
                    Form {
                        Section("Interest signals") {
                            ForEach(interestOptions, id: \.self) { topic in
                                Toggle(topic.capitalized, isOn: Binding(
                                    get: { appState.activeInterests.contains(topic) },
                                    set: { appState.setInterest(topic, enabled: $0) }
                                ))
                            }
                        }
                        Section("Mode") {
                            Text("Interests are scoped to \(appState.mode == .social ? "Social" : "Corporate") mode.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .navigationTitle("Explore Tuning")
                }
            }
        }
    }

    private var content: some View {
        VStack(spacing: 12) {
            if selectedScope == .all {
                trendSection
                editorialCollectionsSection
            }
            if selectedScope == .all || selectedScope == .posts || selectedScope == .videos {
                exploreGrid
            }
            if selectedScope == .all || selectedScope == .profiles {
                profileSection
            }
            if selectedScope == .all || selectedScope == .posts {
                postSection
            }
            if selectedScope == .all || selectedScope == .videos {
                videoSection
            }
            if selectedScope == .all || selectedScope == .communities {
                communitiesSection
            }
            if selectedScope == .all || selectedScope == .shop {
                shopSection
            }
            if selectedScope == .all || selectedScope == .music {
                musicSection
            }
            if selectedScope == .all || selectedScope == .pulse {
                pulseSection
            }
            if selectedScope == .all {
                channelsSection
            }
        }
        .padding(.bottom, 90)
    }

    private var rankingControlCard: some View {
        EliteCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Explore Ranking Controls")
                Toggle("Prefer creator diversity", isOn: $preferDiversity)
                    .foregroundStyle(primaryText)
                Toggle("Prioritize freshness", isOn: $prioritizeFreshness)
                    .foregroundStyle(primaryText)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Minimum explore score: \(Int(minimumExploreScore))")
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                    Slider(value: $minimumExploreScore, in: 0...220, step: 5)
                        .tint(BrandPalette.neonBlue)
                }
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(secondaryText)
            TextField("Search posts, videos, profiles, music, groups, shop...", text: $query)
                .foregroundStyle(primaryText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit {
                    appState.addRecentSearch(query)
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(BrandPalette.adaptiveCardBg(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(BrandPalette.adaptiveGlassStroke(for: colorScheme), lineWidth: 1)
        )
    }

    private var topDiscoverTabs: some View {
        HStack(spacing: 26) {
            ForEach(DiscoverTab.allCases) { tab in
                Button {
                    discoverTab = tab
                    switch tab {
                    case .forYou:
                        selectedScope = .all
                    case .accounts:
                        selectedScope = .profiles
                    case .audio:
                        selectedScope = .music
                    }
                } label: {
                    VStack(spacing: 5) {
                        Text(tab.rawValue)
                            .font(.headline)
                            .foregroundStyle(discoverTab == tab ? primaryText : secondaryText)
                        Rectangle()
                            .fill(discoverTab == tab ? BrandPalette.neonBlue : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 2)
    }

    private var recentSection: some View {
        EliteCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    sectionTitle("Recent")
                    Spacer()
                    if !appState.recentSearches.isEmpty {
                        Button("Clear all") {
                            appState.clearRecentSearches()
                        }
                        .font(.caption.bold())
                        .foregroundStyle(BrandPalette.neonBlue)
                    }
                }
                if appState.recentSearches.isEmpty {
                    emptyLabel("No recent searches yet.")
                } else {
                    ForEach(appState.recentSearches.prefix(8), id: \.self) { recent in
                        HStack {
                            Button {
                                query = recent
                                appState.addRecentSearch(recent)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock")
                                        .foregroundStyle(.white.opacity(0.7))
                                    Text(recent)
                                        .foregroundStyle(.white)
                                }
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            Button {
                                appState.removeRecentSearch(recent)
                            } label: {
                                Image(systemName: "xmark")
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var trendSection: some View {
        EliteCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Trending now")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["#food", "#reels", "#sports", "#fashion", "#music", "#jobs", "#local"], id: \.self) { trend in
                            Button(trend) {
                                query = trend.replacingOccurrences(of: "#", with: "")
                                appState.addRecentSearch(query)
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(BrandPalette.cardBg.opacity(0.8))
                            .overlay(Capsule().stroke(BrandPalette.glassStroke, lineWidth: 1))
                            .clipShape(Capsule())
                            .foregroundStyle(primaryText)
                            .buttonStyle(SnappyScaleButtonStyle())
                        }
                    }
                }
            }
        }
    }

    private var scopeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SearchScope.allCases) { scope in
                    Button(scope.rawValue) {
                        selectedScope = scope
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedScope == scope ? BrandPalette.neonBlue.opacity(0.35) : BrandPalette.cardBg.opacity(0.85))
                    .overlay(
                        Capsule()
                            .stroke(selectedScope == scope ? BrandPalette.neonBlue : .white.opacity(0.12), lineWidth: 1)
                    )
                    .clipShape(Capsule())
                    .foregroundStyle(primaryText)
                    .buttonStyle(SnappyScaleButtonStyle())
                }
            }
        }
    }

    private var exploreGrid: some View {
        EliteCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Explore")
                    .font(.headline)
                    .foregroundStyle(primaryText)
                LazyVGrid(columns: gridColumns, spacing: 8) {
                    ForEach(Array(exploreItems.prefix(12).enumerated()), id: \.offset) { _, post in
                        Button {
                            openPost(post)
                        } label: {
                            ZStack(alignment: .bottomTrailing) {
                                previewTile(for: post, height: curatedTileHeight(for: post))
                                Text(exploreConfidenceLabel(for: post))
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 5)
                                    .background(.black.opacity(0.55))
                                    .clipShape(Capsule())
                                    .foregroundStyle(.white)
                                    .padding(6)
                                if post.type == .reel || post.type == .shortVideo {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.white.opacity(0.95))
                                        .padding(6)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                appState.toggleSavedPost(post.id)
                            } label: {
                                Label("Save post", systemImage: "bookmark")
                            }
                            Button {
                                appState.follow(post.authorHandle)
                            } label: {
                                Label("Follow creator", systemImage: "person.badge.plus")
                            }
                        }
                    }
                }
            }
        }
    }

    private var profileSection: some View {
        EliteCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Profiles")
                if profileResults.isEmpty {
                    emptyLabel("No matching profiles.")
                } else {
                    ForEach(profileResults.prefix(8)) { user in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(BrandPalette.neonBlue.opacity(0.22))
                                .frame(width: 42, height: 42)
                                .overlay(Image(systemName: "person.fill").foregroundStyle(primaryText))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.handle).font(.headline).foregroundStyle(primaryText)
                                Text(user.displayName).font(.caption).foregroundStyle(secondaryText)
                            }
                            Spacer()
                            Button("Follow") {
                                appState.follow(user.handle)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
        }
    }

    private var postSection: some View {
        EliteCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Posts")
                if postResults.isEmpty {
                    emptyLabel("No matching posts.")
                } else {
                    ForEach(postResults.prefix(10)) { post in
                        Button {
                            openPost(post)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                previewTile(for: post, height: 160)
                                Text(post.authorHandle).font(.caption).foregroundStyle(secondaryText)
                                Text(post.caption).foregroundStyle(primaryText)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var videoSection: some View {
        EliteCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Videos & Reels")
                if videoResults.isEmpty {
                    emptyLabel("No matching videos.")
                } else {
                    ForEach(videoResults.prefix(8)) { post in
                        Button {
                            openPost(post)
                        } label: {
                            ZStack(alignment: .center) {
                                previewTile(for: post, height: 190)
                                Image(systemName: "play.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                                    .padding(14)
                                    .background(.black.opacity(0.35))
                                    .clipShape(Circle())
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var communitiesSection: some View {
        EliteCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Groups")
                if communityResults.isEmpty {
                    emptyLabel("No matching groups.")
                } else {
                    ForEach(communityResults.prefix(6)) { group in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(group.name).font(.headline).foregroundStyle(primaryText)
                            Text(group.summary).font(.caption).foregroundStyle(secondaryText)
                        }
                    }
                }
            }
        }
    }

    private var shopSection: some View {
        EliteCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Shop")
                if shopResults.isEmpty {
                    emptyLabel("No matching products.")
                } else {
                    ForEach(shopResults.prefix(8)) { item in
                        HStack {
                            Label(item.title, systemImage: item.imageSystemName)
                                .foregroundStyle(primaryText)
                            Spacer()
                            Text("$\(item.priceUSD)")
                                .font(.caption.bold())
                                .foregroundStyle(BrandPalette.neonGreen)
                        }
                    }
                }
            }
        }
    }

    private var musicSection: some View {
        EliteCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Music")
                if musicResults.isEmpty {
                    emptyLabel("No matching tracks.")
                } else {
                    ForEach(musicResults.prefix(8)) { track in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.title).foregroundStyle(primaryText)
                                Text("\(track.artist) • \(track.source.displayName)")
                                    .font(.caption)
                                    .foregroundStyle(secondaryText)
                            }
                            Spacer()
                            Button {
                                appState.playTrack(track)
                            } label: {
                                Image(systemName: "play.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(BrandPalette.neonGreen)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var pulseSection: some View {
        EliteCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Pulse")
                if pulseResults.isEmpty {
                    emptyLabel("No matching Pulse posts.")
                } else {
                    ForEach(pulseResults.prefix(8)) { item in
                        ViolenceWarningGate(postID: item.id, isRequired: item.violenceWarningRequired) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.authorHandle).font(.headline).foregroundStyle(primaryText)
                                Text(item.text).foregroundStyle(secondaryText)
                            }
                        }
                    }
                }
            }
        }
    }

    private var channelsSection: some View {
        EliteCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Channels")
                ForEach(appState.broadcastChannels.prefix(5)) { channel in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(channel.title).font(.headline).foregroundStyle(primaryText)
                            Text(channel.latestMessage).font(.caption).foregroundStyle(secondaryText)
                        }
                        Spacer()
                        Text("\(channel.memberCount)")
                            .font(.caption.bold())
                            .foregroundStyle(BrandPalette.neonGreen)
                    }
                }
            }
        }
    }

    private var editorialCollectionsSection: some View {
        EliteCard {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Editorial Collections")
                ForEach(editorialCollections, id: \.title) { collection in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(collection.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(BrandPalette.neonBlue)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(collection.posts.prefix(6)) { post in
                                    Button {
                                        openPost(post)
                                    } label: {
                                        ZStack(alignment: .topLeading) {
                                            previewTile(for: post, height: 108)
                                                .frame(width: 120)
                                            Text(exploreConfidenceLabel(for: post))
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 4)
                                                .background(.black.opacity(0.55))
                                                .clipShape(Capsule())
                                                .foregroundStyle(.white)
                                                .padding(6)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button {
                                            appState.toggleSavedPost(post.id)
                                        } label: {
                                            Label("Save post", systemImage: "bookmark")
                                        }
                                        Button {
                                            appState.follow(post.authorHandle)
                                        } label: {
                                            Label("Follow creator", systemImage: "person.badge.plus")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func previewTile(for post: PostItem, height: CGFloat) -> some View {
        if let data = post.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [BrandPalette.neonBlue.opacity(0.35), BrandPalette.accentPurple.opacity(0.28)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: height)
                .overlay(
                    VStack(spacing: 4) {
                        Image(systemName: post.type == .reel || post.type == .shortVideo ? "play.rectangle.fill" : "photo")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.9))
                        Text(post.type.rawValue.capitalized)
                            .font(.caption2.bold())
                            .foregroundStyle(.white.opacity(0.8))
                    }
                )
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title).font(TypeTokens.title).foregroundStyle(primaryText)
    }

    private func emptyLabel(_ text: String) -> some View {
        Text(text).font(.caption).foregroundStyle(secondaryText)
    }

    private var normalizedQueryTokens: [String] {
        query
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace || $0 == "#" || $0 == "," })
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private func matchesAllTokens(_ fields: [String]) -> Bool {
        let tokens = normalizedQueryTokens
        guard !tokens.isEmpty else { return true }
        let lowerFields = fields.map { $0.lowercased() }
        return tokens.allSatisfy { token in
            lowerFields.contains { $0.contains(token) }
        }
    }

    private var exploreItems: [PostItem] {
        let all = appState.posts.filter { !$0.isArchived && $0.type != .story }
        let ranked = all
            .filter { exploreScore($0) >= minimumExploreScore }
            .sorted { lhs, rhs in
            let l = exploreScore(lhs)
            let r = exploreScore(rhs)
            if l == r { return lhs.createdAt > rhs.createdAt }
            return l > r
        }
        if !preferDiversity {
            return ranked
        }
        var seenAuthors = Set<String>()
        var diversified: [PostItem] = []
        for item in ranked {
            let key = item.authorHandle.lowercased()
            if !seenAuthors.contains(key) || diversified.count < 4 {
                diversified.append(item)
                seenAuthors.insert(key)
            }
        }
        for item in ranked where diversified.count < ranked.count {
            if !diversified.contains(where: { $0.id == item.id }) {
                diversified.append(item)
            }
        }
        return diversified
    }

    private var interestOptions: [String] {
        ["creators", "fashion", "music", "reels", "local", "networking", "hiring", "resume", "analytics", "jobs", "education", "finance", "sports", "travel"]
    }

    private var editorialCollections: [(title: String, posts: [PostItem])] {
        let base = exploreItems
        let today = base.sorted { $0.createdAt > $1.createdAt }
        let rising = base.sorted { ($0.likeCount + $0.commentCount + $0.repostCount) > ($1.likeCount + $1.commentCount + $1.repostCount) }
        let local = base.filter { $0.city.caseInsensitiveCompare(appState.localCity) == .orderedSame }
        let corporate = base.filter { $0.surfaceStyle == .chat || $0.caption.lowercased().contains("job") || $0.caption.lowercased().contains("hiring") }
        return [
            ("Today's Picks", today),
            ("Rising Creators", rising),
            ("Local Now", local.isEmpty ? today : local),
            ("Corporate Trends", corporate.isEmpty ? rising : corporate)
        ]
    }

    private func exploreScore(_ post: PostItem) -> Double {
        let ageHours = max(1, Date().timeIntervalSince(post.createdAt) / 3600)
        let engagement = Double(post.likeCount * 2 + post.commentCount * 3 + post.repostCount * 4 + post.saveCount * 3)
        let recency = prioritizeFreshness ? (40.0 / ageHours) : (18.0 / pow(ageHours, 0.45))
        let mediaBoost: Double = (post.type == .reel || post.type == .shortVideo) ? 35 : 12
        let interactionBoost = appState.exploreBoostScore(for: post.id)
        return engagement + recency + mediaBoost + interactionBoost
    }

    private func exploreConfidenceLabel(for post: PostItem) -> String {
        let score = exploreScore(post)
        if score >= 160 { return "High" }
        if score >= 90 { return "Medium" }
        return "Emerging"
    }

    private func curatedTileHeight(for post: PostItem) -> CGFloat {
        switch post.type {
        case .reel, .shortVideo:
            return 146
        case .post:
            return 122
        case .story:
            return 110
        }
    }

    private var profileResults: [UserProfile] {
        appState.internalUsers.filter { user in
            matchesAllTokens([user.username, user.handle, user.displayName])
        }
        .sorted { lhs, rhs in
            let leftScore = fieldMatchScore([lhs.username, lhs.handle, lhs.displayName])
            let rightScore = fieldMatchScore([rhs.username, rhs.handle, rhs.displayName])
            if leftScore == rightScore { return lhs.followers > rhs.followers }
            return leftScore > rightScore
        }
    }

    private var postResults: [PostItem] {
        appState.posts.filter { post in
            !post.isArchived
            && matchesAllTokens([post.caption, post.authorHandle, post.city, post.type.rawValue])
        }
        .sorted { lhs, rhs in
            let leftScore = fieldMatchScore([lhs.caption, lhs.authorHandle, lhs.city, lhs.type.rawValue]) + lhs.likeCount + lhs.repostCount
            let rightScore = fieldMatchScore([rhs.caption, rhs.authorHandle, rhs.city, rhs.type.rawValue]) + rhs.likeCount + rhs.repostCount
            if leftScore == rightScore { return lhs.createdAt > rhs.createdAt }
            return leftScore > rightScore
        }
    }

    private var videoResults: [PostItem] {
        postResults.filter { $0.type == .reel || $0.type == .shortVideo || $0.type == .story }
    }

    private var communityResults: [CommunityGroup] {
        appState.communities.filter { group in
            matchesAllTokens([group.name, group.summary, group.creator, group.managers.joined(separator: " ")])
        }
    }

    private var shopResults: [ShopProduct] {
        appState.shopProducts.filter { product in
            matchesAllTokens([product.title, product.description, product.sellerHandle])
        }
    }

    private var musicResults: [MusicTrack] {
        appState.musicLibrary.filter { track in
            matchesAllTokens([track.title, track.artist, track.source.displayName])
        }
    }

    private var pulseResults: [PublicPulsePost] {
        appState.publicPulse.filter { item in
            matchesAllTokens([item.authorHandle, item.text])
        }
        .sorted { lhs, rhs in
            let leftScore = fieldMatchScore([lhs.authorHandle, lhs.text])
            let rightScore = fieldMatchScore([rhs.authorHandle, rhs.text])
            if leftScore == rightScore { return lhs.createdAt > rhs.createdAt }
            return leftScore > rightScore
        }
    }

    private func fieldMatchScore(_ fields: [String]) -> Int {
        let tokens = normalizedQueryTokens
        guard !tokens.isEmpty else { return 1 }
        let lowered = fields.map { $0.lowercased() }
        return tokens.reduce(0) { partial, token in
            let exact = lowered.contains(where: { $0 == token }) ? 4 : 0
            let prefix = lowered.contains(where: { $0.hasPrefix(token) }) ? 3 : 0
            let contains = lowered.contains(where: { $0.contains(token) }) ? 2 : 0
            return partial + max(exact, prefix, contains)
        }
    }

    private func openPost(_ post: PostItem) {
        appState.recordExploreInteraction(postID: post.id)
        selectedPost = post
    }
}
