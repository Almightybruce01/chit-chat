//
//  HomeView.swift
//  Chit Chat Social
//
//  Created by Brian Bruce on 2025-06-24.
//

import SwiftUI
import UIKit
import PhotosUI
import Foundation
import AVKit

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var showLiveStudio = false
    @State private var showCreate = false
    @State private var showMusic = false
    @State private var showPulse = false
    @State private var showFeatures = false
    @State private var showRankingLab = false
    @State private var showMonetizationLab = false
    @State private var showCreatorGrowthLab = false
    @State private var showSchedulerLab = false
    @State private var showAIMix = false
    @State private var aiMixIdeas: [String] = []
    @State private var selectedSurface: PostSurfaceStyle = .chit
    @State private var selectedFeedLens: FeedLens = .forYou
    @State private var selectedSortMode: FeedSortMode = .latest
    @State private var showQuickShortcuts = false
    @State private var homeFeedRefreshTick = 0
    @State private var quickPostText = ""
    @State private var quickPostPhotoItem: PhotosPickerItem?
    @State private var quickPostPhotoData: Data?
    @State private var quickPostStatus = ""
    @State private var quickUseAIPolish = true
    @State private var quickMonetize = false
    @State private var quickAffiliateURL = ""
    @State private var selectedStoryHandle = ""
    @State private var showStoryViewer = false
    @State private var showMarket = false

    var body: some View {
        NavigationStack {
            ZStack {
                EliteBackground()

                ScrollView {
                    VStack(spacing: LayoutTokens.sectionGap) {
                        HomeWelcomeHeader {
                            homeFeedRefreshTick += 1
                        }
                        .environmentObject(appState)

                        FeedControlDeck(
                            surface: $selectedSurface,
                            lens: $selectedFeedLens,
                            sort: $selectedSortMode
                        )

                        FuturisticSectionHeader(
                            title: "Today",
                            subtitle: "Stories, market, quick post, then your live feed."
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)

                        storyTray

                        marketEntryCard

                        CollapsibleShortcutRail(
                            isExpanded: $showQuickShortcuts,
                            title: "Shortcuts & labs",
                            collapsedSummary: "Market, Music, Live, ranking, monetization, AI Mix, and more."
                        ) {
                            topActionRail
                        }

                        quickComposerCard

                        Group {
                            if selectedFeedLens == .closeFriends {
                                CloseFriendsFeedView(surfaceStyle: selectedSurface, sortMode: selectedSortMode)
                                    .environmentObject(appState)
                            } else if selectedSurface == .chat {
                                ChatPostsFeedView(isFollowingOnly: selectedFeedLens == .following, sortMode: selectedSortMode)
                                    .environmentObject(appState)
                            } else {
                                FeedView(isFollowingOnly: selectedFeedLens == .following, surfaceStyle: .chit, sortMode: selectedSortMode)
                                    .environmentObject(appState)
                            }
                        }
                        .id(homeFeedRefreshTick)
                    }
                    .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                    .padding(.horizontal, LayoutTokens.screenHorizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 28)
                    .readableContentWidth()
                }
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreate = true
                    } label: {
                        Image(systemName: "plus.app.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(BrandPalette.neonGreen)
                    }
                    .minimumInteractiveTarget()
                    .accessibilityLabel("Create new post")
                }
            }
            .sheet(isPresented: $showCreate) {
                PostView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showMusic) {
                NavigationStack {
                    MusicHubView().environmentObject(appState)
                }
            }
            .sheet(isPresented: $showPulse) {
                NavigationStack {
                    PulseBoardView().environmentObject(appState)
                }
            }
            .sheet(isPresented: $showFeatures) {
                IconHubView().environmentObject(appState)
            }
            .sheet(isPresented: $showRankingLab) {
                NavigationStack {
                    RankingLabView()
                        .environmentObject(appState)
                }
            }
            .sheet(isPresented: $showMonetizationLab) {
                NavigationStack {
                    MonetizationLabView()
                        .environmentObject(appState)
                }
            }
            .sheet(isPresented: $showCreatorGrowthLab) {
                NavigationStack {
                    CreatorGrowthLabView()
                        .environmentObject(appState)
                }
            }
            .sheet(isPresented: $showSchedulerLab) {
                NavigationStack {
                    SchedulerLabView()
                        .environmentObject(appState)
                }
            }
            .sheet(isPresented: $showLiveStudio) {
                NavigationStack {
                    LiveStudioView()
                        .environmentObject(appState)
                }
            }
            .sheet(isPresented: $showAIMix) {
                NavigationStack {
                    AIMixSheet(
                        ideas: aiMixIdeas,
                        applyIdea: { idea in
                            quickPostText = idea
                            showAIMix = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showStoryViewer) {
                NavigationStack {
                    StoryViewerSheet(handle: selectedStoryHandle)
                        .environmentObject(appState)
                }
            }
            .fullScreenCover(isPresented: $showMarket) {
                FullStoreView(onBack: { showMarket = false })
                    .environmentObject(appState)
            }
            .onAppear {
                appState.processDueScheduledPosts()
            }
            .onChange(of: quickPostPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            quickPostPhotoData = data
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var quickComposerCard: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(selectedSurface == .chat ? "Quick Chat Post" : "Quick Chit Post")
                    .font(.headline)
                    .foregroundStyle(.white)
                TextField(
                    selectedSurface == .chat ? "Share a thought..." : "Share a visual moment...",
                    text: $quickPostText,
                    axis: .vertical
                )
                .lineLimit(2...4)
                .textFieldStyle(EliteTextFieldStyle())

                Toggle("AI polish caption", isOn: $quickUseAIPolish)
                    .foregroundStyle(.white.opacity(0.9))
                Toggle("Monetize this post", isOn: $quickMonetize)
                    .foregroundStyle(.white.opacity(0.9))
                if quickMonetize {
                    TextField("Affiliate / promo URL (optional)", text: $quickAffiliateURL)
                        .textFieldStyle(EliteTextFieldStyle())
                    Button("Suggest best affiliate link") {
                        quickAffiliateURL = appState.suggestedAffiliateLink(from: quickPostText)
                    }
                    .buttonStyle(.borderedProminent)
                }

                HStack {
                    PhotosPicker(selection: $quickPostPhotoItem, matching: .images) {
                        Label(quickPostPhotoData == nil ? "Attach" : "Photo Added", systemImage: "photo")
                            .font(.caption.bold())
                            .foregroundStyle(BrandPalette.neonBlue)
                    }
                    Button("Clear") {
                        quickPostText = ""
                        quickPostStatus = ""
                    }
                    .buttonStyle(.bordered)
                    Button("Remove Photo", role: .destructive) {
                        quickPostPhotoData = nil
                        quickPostPhotoItem = nil
                    }
                    .buttonStyle(.bordered)
                    .disabled(quickPostPhotoData == nil)
                    Spacer()
                    Button("Add Story") {
                        publishQuickPost(type: .story)
                    }
                    .buttonStyle(.bordered)
                    Button("Post Now") {
                        publishQuickPost(type: .post)
                    }
                    .buttonStyle(NeonPrimaryButtonStyle())
                }
                if !quickPostStatus.isEmpty {
                    Text(quickPostStatus)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.76))
                }
            }
        }
    }

    @ViewBuilder
    private var storyTray: some View {
        let handles = appState.activeStoryHandles(limit: 16)
        if !handles.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Stories")
                    .font(.caption.bold())
                    .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                    .padding(.horizontal, 4)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(handles, id: \.self) { handle in
                            Button {
                                selectedStoryHandle = handle
                                appState.markStorySeen(handle: handle)
                                showStoryViewer = true
                            } label: {
                                VStack(spacing: 6) {
                                    storyAvatar(for: handle)
                                    Text(handle)
                                        .font(.caption2)
                                        .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme).opacity(0.9))
                                        .lineLimit(1)
                                        .frame(width: 68)
                                }
                            }
                            .buttonStyle(SnappyScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }

    @ViewBuilder
    private var marketEntryCard: some View {
        Button {
            showMarket = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "storefront.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Market")
                        .font(.headline)
                        .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                    Text("Shop, ship, meetups & live commerce")
                        .font(.caption)
                        .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
            }
            .padding(14)
            .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.9))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(BrandPalette.adaptiveGlassStroke(for: colorScheme), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .contentShape(Rectangle())
        }
        .buttonStyle(SnappyScaleButtonStyle())
    }

    private var topActionRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                actionPill("Market", icon: "storefront.fill", tint: .orange) { showMarket = true }
                actionPill("Music", icon: "music.note", tint: BrandPalette.neonBlue) { showMusic = true }
                actionPill("Pulse", icon: "bolt.bubble.fill", tint: BrandPalette.neonGreen) { showPulse = true }
                actionPill("Features", icon: "square.grid.2x2.fill", tint: BrandPalette.accentPurple) { showFeatures = true }
                actionPill("Ranking", icon: "slider.horizontal.3", tint: .white) { showRankingLab = true }
                actionPill("Money", icon: "dollarsign.circle.fill", tint: .green) { showMonetizationLab = true }
                actionPill("Growth", icon: "chart.line.uptrend.xyaxis.circle.fill", tint: .orange) { showCreatorGrowthLab = true }
                actionPill("Schedule", icon: "calendar.badge.clock", tint: .mint) { showSchedulerLab = true }
                actionPill("AI Mix", icon: "sparkles", tint: BrandPalette.accentPink) {
                    aiMixIdeas = generateAIMixIdeas()
                    showAIMix = true
                }
                actionPill("Live", icon: "dot.radiowaves.left.and.right", tint: BrandPalette.neonBlue) { showLiveStudio = true }
                actionPill("Create", icon: "plus.app.fill", tint: BrandPalette.neonGreen) { showCreate = true }
            }
            .padding(.horizontal, 2)
        }
    }

    private func actionPill(_ title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.bold())
                Text(title)
                    .font(.caption.bold())
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(BrandPalette.cardBg.opacity(0.9))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(BrandPalette.glassStroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
        }
        .buttonStyle(SnappyScaleButtonStyle())
    }

    @ViewBuilder
    private func storyAvatar(for handle: String) -> some View {
        let hasSeen = appState.hasSeenStory(handle: handle)
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: hasSeen
                            ? [.white.opacity(0.35), .white.opacity(0.18)]
                            : [BrandPalette.accentPink, BrandPalette.neonBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.6
                )
                .frame(width: 66, height: 66)
            Group {
                if let data = appState.profilePhoto(for: handle), let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Circle()
                        .fill(BrandPalette.neonBlue.opacity(0.28))
                        .overlay(
                            Text(String(handle.replacingOccurrences(of: "@", with: "").prefix(1)).uppercased())
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        )
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())

            if handle.caseInsensitiveCompare(appState.currentUser.handle) == .orderedSame {
                Image(systemName: "plus.circle.fill")
                    .font(.caption)
                    .foregroundStyle(BrandPalette.neonGreen)
                    .background(Circle().fill(.black))
            }
        }
    }

    private func publishQuickPost(type: ContentType) {
        let base = quickPostText
        let polished = quickUseAIPolish
            ? appState.aiPolishCaption(base, surfaceStyle: selectedSurface)
            : (base.isEmpty ? (selectedSurface == .chat ? "Quick chat update." : "Quick chit drop.") : base)
        let result = appState.publishPost(
            caption: polished,
            type: type,
            imageData: quickPostPhotoData,
            storyAudience: type == .story ? appState.defaultStoryAudience : .public,
            audience: .public,
            isCollab: false,
            areLikesHidden: appState.hideLikeCountsByDefault,
            areCommentsHidden: appState.hideCommentCountsByDefault,
            blockNudity: true,
            surfaceStyle: selectedSurface
        )
        if quickMonetize && type != .story {
            appState.creatorMonetizationEnabled = true
            appState.creatorAffiliateLink = quickAffiliateURL
            appState.creatorBoostBudgetUSD = max(appState.creatorBoostBudgetUSD, 25)
            if let idx = appState.posts.firstIndex(where: { $0.authorHandle == appState.currentUser.handle }) {
                let adTag = quickAffiliateURL.isEmpty ? "#sponsored" : "\(quickAffiliateURL) #ad"
                appState.posts[idx].caption += "\n\(adTag)"
            }
            appState.addPulsePost(
                text: "Boosted post published. Link: \(quickAffiliateURL.isEmpty ? "not set" : quickAffiliateURL)",
                imageSystemName: "megaphone.fill"
            )
        }
        quickPostStatus = result.reason
        if result.label != .blockedNudity && result.label != .missingRequiredMedia {
            quickPostText = ""
            quickPostPhotoData = nil
            quickAffiliateURL = ""
        }
    }

    private func generateAIMixIdeas() -> [String] {
        let base = appState.posts
            .filter { $0.type == .post || $0.type == .reel || $0.type == .shortVideo }
            .prefix(4)
            .map(\.caption)
        let seed = base.isEmpty ? ["Fresh drop loading...", "Behind-the-scenes update", "Hot takes only"] : base
        return seed.prefix(3).flatMap { text in
            let variants = appState.captionVariants(for: text, surface: selectedSurface)
            return [variants.a, variants.b]
        }
    }
}

private struct AIMixSheet: View {
    let ideas: [String]
    let applyIdea: (String) -> Void

    var body: some View {
        List {
            Section("AI Mix Ideas") {
                if ideas.isEmpty {
                    Text("No ideas generated yet.")
                } else {
                    ForEach(Array(ideas.enumerated()), id: \.offset) { _, idea in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(idea)
                            Button("Use this idea") {
                                applyIdea(idea)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("AI Mix")
    }
}

private struct StoryViewerSheet: View {
    @EnvironmentObject private var appState: AppState
    let handle: String
    @Environment(\.dismiss) private var dismiss
    @State private var activeIndex = 0
    @State private var progress: CGFloat = 0
    @State private var isPaused = false
    @State private var replyText = ""
    @State private var verticalDrag: CGFloat = 0
    @State private var horizontalDrag: CGFloat = 0
    private let timer = Timer.publish(every: 0.06, on: .main, in: .common).autoconnect()
    private let quickReplies = [
        "Fire story",
        "Love this",
        "Where is this?",
        "Need details",
        "Dropping soon?"
    ]

    private struct StoryFrame: Identifiable {
        enum Kind {
            case image(Data)
            case gif(Data)
            case video(Data)
            case post(PostItem)
        }

        let id: UUID
        let kind: Kind
        let title: String
        let subtitle: String
    }

    private var frames: [StoryFrame] {
        var items: [StoryFrame] = []
        if let image = appState.profileStoryImage(for: handle) {
            items.append(StoryFrame(id: UUID(), kind: .image(image), title: appState.displayName(for: handle), subtitle: "Story photo"))
        }
        if let gif = appState.profileStoryGIF(for: handle) {
            items.append(StoryFrame(id: UUID(), kind: .gif(gif), title: appState.displayName(for: handle), subtitle: "Story GIF"))
        }
        if let video = appState.profileStoryVideo(for: handle) {
            items.append(StoryFrame(id: UUID(), kind: .video(video), title: appState.displayName(for: handle), subtitle: "Story video"))
        }
        items.append(contentsOf: appState.activeStoryPosts(for: handle, limit: 8).map {
            StoryFrame(id: $0.id, kind: .post($0), title: $0.authorHandle, subtitle: $0.createdAt.formatted(date: .omitted, time: .shortened))
        })
        if items.isEmpty {
            items.append(StoryFrame(id: UUID(), kind: .post(
                PostItem(
                    id: UUID(),
                    authorHandle: handle,
                    caption: "No active stories right now.",
                    type: .story,
                    createdAt: Date(),
                    city: "",
                    imageData: nil,
                    isCollab: false,
                    surfaceStyle: .chit
                )
            ), title: appState.displayName(for: handle), subtitle: "Story"))
        }
        return items
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                topProgress
                    .padding(.top, 12)
                    .padding(.horizontal, 10)

                storyContent
                    .padding(.horizontal, 10)
                    .padding(.top, 8)

                Spacer()
            }
        }
        .offset(y: verticalDrag)
        .gesture(
            DragGesture(minimumDistance: 6)
                .onChanged { value in
                    if abs(value.translation.width) > abs(value.translation.height) {
                        horizontalDrag = value.translation.width
                    } else if value.translation.height > 0 {
                        verticalDrag = value.translation.height
                    }
                }
                .onEnded { value in
                    if abs(value.translation.width) > abs(value.translation.height) {
                        if value.translation.width < -90 {
                            withAnimation(MotionTokens.spring) {
                                goToNext()
                            }
                        } else if value.translation.width > 90 {
                            withAnimation(MotionTokens.spring) {
                                goToPrevious()
                            }
                        }
                    } else if value.translation.height > 120 {
                        dismiss()
                    }
                    verticalDrag = 0
                    horizontalDrag = 0
                }
        )
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickReplies, id: \.self) { quick in
                            Button(quick) {
                                applyQuickReply(quick)
                            }
                            .buttonStyle(.bordered)
                            .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    .padding(.horizontal, 2)
                }
                HStack(spacing: 8) {
                    TextField("Reply to story...", text: $replyText)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        replyText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.8))
                    Button("Send") {
                        sendStoryReply()
                    }
                    .buttonStyle(NeonPrimaryButtonStyle())
                    .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .onReceive(timer) { _ in
            guard !isPaused else { return }
            progress += 0.02
            if progress >= 1 {
                goToNext()
            }
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.1)
                .onChanged { _ in isPaused = true }
                .onEnded { _ in isPaused = false }
        )
        .onAppear {
            appState.markStorySeen(handle: handle)
            preloadUpcomingFrames()
        }
    }

    @ViewBuilder
    private var topProgress: some View {
        VStack(spacing: 10) {
            HStack(spacing: 4) {
                ForEach(Array(frames.enumerated()), id: \.offset) { idx, _ in
                    Capsule()
                        .fill(.white.opacity(0.28))
                        .frame(height: 3)
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(.white)
                                .frame(width: progressWidth(for: idx), height: 3)
                        }
                }
            }
            HStack {
                Text(appState.displayName(for: handle))
                    .foregroundStyle(.white)
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    @ViewBuilder
    private var storyContent: some View {
        let frame = frames[safe: activeIndex] ?? frames.first
        if let frame {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.35))
                .overlay(frameView(frame))
                .frame(maxWidth: .infinity, maxHeight: 520)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { goToPrevious() }
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { goToNext() }
            }
        }
        .offset(x: horizontalDrag * 0.25)
        .animation(.easeOut(duration: MotionTokens.normal), value: horizontalDrag)
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 2) {
                Text(frame.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(frame.subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.82))
            }
            .padding(12)
        }
        } else {
            Text("No stories")
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: 520)
        }
    }

    @ViewBuilder
    private func frameView(_ frame: StoryFrame) -> some View {
        switch frame.kind {
        case .image(let data), .gif(let data):
            if let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                EmptyView()
            }
        case .video:
            LinearGradient(
                colors: [BrandPalette.bgMid, BrandPalette.accentPurple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                Label("Video story", systemImage: "video.fill")
                    .foregroundStyle(.white.opacity(0.9))
            )
        case .post(let post):
            if let data = post.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [BrandPalette.bgMid, BrandPalette.accentPurple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    private func progressWidth(for index: Int) -> CGFloat {
        let segmentWidth: CGFloat = 40
        if index < activeIndex { return segmentWidth }
        if index > activeIndex { return 0 }
        return segmentWidth * max(0, min(1, progress))
    }

    private func goToNext() {
        if activeIndex + 1 < frames.count {
            HapticTokens.light()
            activeIndex += 1
            progress = 0
            return
        }
        dismiss()
    }

    private func goToPrevious() {
        if activeIndex > 0 {
            HapticTokens.light()
            activeIndex -= 1
            progress = 0
        }
    }

    private func applyQuickReply(_ text: String) {
        replyText = text
        sendStoryReply()
    }

    private func sendStoryReply() {
        let trimmed = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        appState.replyToStory(handle: handle, text: trimmed)
        HapticTokens.success()
        replyText = ""
    }

    private func preloadUpcomingFrames() {
        let future = frames.dropFirst(min(activeIndex + 1, frames.count))
        for frame in future.prefix(3) {
            switch frame.kind {
            case .image(let data), .gif(let data):
                _ = UIImage(data: data)
            case .video, .post:
                break
            }
        }
    }
}

struct RankingLabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            EliteBackground()
            Form {
                Section("Engagement Weights") {
                    sliderRow("Like weight", value: $appState.rankingLikeWeight, range: 0...10)
                    sliderRow("Comment weight", value: $appState.rankingCommentWeight, range: 0...10)
                    sliderRow("Repost weight", value: $appState.rankingRepostWeight, range: 0...12)
                    sliderRow("Save weight", value: $appState.rankingSaveWeight, range: 0...10)
                }
                Section("Freshness") {
                    sliderRow("Decay power", value: $appState.rankingFreshnessPower, range: 0.2...1.2)
                    Text("Lower decay keeps older posts in ranking longer; higher favors newer posts.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }
                Section {
                    Button("Reset defaults") {
                        appState.rankingLikeWeight = 4.0
                        appState.rankingCommentWeight = 5.0
                        appState.rankingRepostWeight = 6.0
                        appState.rankingSaveWeight = 3.0
                        appState.rankingFreshnessPower = 0.58
                    }
                    .buttonStyle(NeonPrimaryButtonStyle())
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Ranking Lab")
    }

    @ViewBuilder
    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .foregroundStyle(.white)
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.78))
            }
            Slider(value: value, in: range)
                .tint(BrandPalette.neonBlue)
        }
    }
}

struct MonetizationLabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        let insights = appState.monetizationInsights()
        ZStack {
            EliteBackground()
            Form {
                Section("Creator Monetization") {
                    Toggle("Enable monetization stack", isOn: $appState.creatorMonetizationEnabled)
                    HStack {
                        Text("Boost budget (USD)")
                        Spacer()
                        Text("$\(Int(appState.creatorBoostBudgetUSD))")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $appState.creatorBoostBudgetUSD, in: 0...1000, step: 10)
                }
                Section("Affiliate") {
                    TextField("Primary affiliate URL", text: $appState.creatorAffiliateLink)
                    Button("Auto suggest from recent posts") {
                        let seed = appState.posts.first(where: { $0.authorHandle == appState.currentUser.handle })?.caption ?? ""
                        appState.creatorAffiliateLink = appState.suggestedAffiliateLink(from: seed)
                    }
                    .buttonStyle(.borderedProminent)
                }
                Section("Insights") {
                    Label("Sponsored posts: \(insights.sponsoredPosts)", systemImage: "tag.fill")
                    Label("Estimated reach: \(insights.estimatedReach)", systemImage: "waveform.path.ecg")
                    Label(String(format: "Est. revenue: $%.2f", insights.estimatedRevenueUSD), systemImage: "dollarsign.circle.fill")
                }
                Section("Command Center") {
                    ForEach(appState.monetizationStrategyCards()) { card in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.title)
                                .font(.headline)
                            Text(card.action)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(card.targetMetric)
                                .font(.caption.bold())
                                .foregroundStyle(BrandPalette.neonBlue)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Monetization Lab")
    }
}

struct CreatorGrowthLabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var baseCaption = ""
    @State private var selectedSurface: PostSurfaceStyle = .chat
    @State private var showReportCSVSheet = false
    @State private var reportCSV = ""

    var body: some View {
        let variants = appState.captionVariants(for: baseCaption, surface: selectedSurface)
        let scoreA = appState.estimateCaptionPerformance(variants.a)
        let scoreB = appState.estimateCaptionPerformance(variants.b)
        let forecast = appState.payoutForecast()

        ZStack {
            EliteBackground()
            Form {
                Section("Best Posting Window") {
                    Picker("Surface", selection: $selectedSurface) {
                        Text("Chat").tag(PostSurfaceStyle.chat)
                        Text("Chit").tag(PostSurfaceStyle.chit)
                    }
                    .pickerStyle(.segmented)
                    Text(appState.recommendedPostingWindow(for: selectedSurface))
                        .foregroundStyle(.white)
                }

                Section("A/B Caption Test") {
                    TextField("Base caption idea", text: $baseCaption, axis: .vertical)
                        .lineLimit(2...5)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Variant A")
                            .font(.caption.bold())
                        Text(variants.a)
                            .foregroundStyle(.white.opacity(0.9))
                        Text(String(format: "Estimated score: %.1f", scoreA))
                            .font(.caption)
                            .foregroundStyle(BrandPalette.neonGreen)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Variant B")
                            .font(.caption.bold())
                        Text(variants.b)
                            .foregroundStyle(.white.opacity(0.9))
                        Text(String(format: "Estimated score: %.1f", scoreB))
                            .font(.caption)
                            .foregroundStyle(BrandPalette.neonBlue)
                    }
                }

                Section("Payout Forecast") {
                    Label(String(format: "Next day: $%.2f", forecast.nextDayUSD), systemImage: "dollarsign.circle")
                    Label(String(format: "Next week: $%.2f", forecast.nextWeekUSD), systemImage: "calendar")
                    Label(String(format: "Next month: $%.2f", forecast.nextMonthUSD), systemImage: "chart.bar.xaxis")
                }

                Section("Enterprise Report Cards") {
                    ForEach(appState.enterpriseReportCards()) { card in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(card.title)
                                .font(.headline)
                            Text(card.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(card.metricLine)
                                .font(.caption.bold())
                                .foregroundStyle(BrandPalette.neonBlue)
                        }
                    }
                    Button("Export Report CSV") {
                        reportCSV = appState.enterpriseReportCSV()
                        showReportCSVSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                Section("Auto Collab Match") {
                    let matches = appState.collabMatchSuggestions(limit: 6)
                    if matches.isEmpty {
                        Text("No strong matches yet. Tag creators in your next posts.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(matches) { match in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(match.handle)
                                    Text("\(match.reason) • score \(match.score)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Follow") {
                                    appState.follow(match.handle)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Growth Lab")
        .sheet(isPresented: $showReportCSVSheet) {
            NavigationStack {
                VStack(spacing: 10) {
                    TextEditor(text: $reportCSV)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(BrandPalette.cardBg.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Button("Copy Report CSV") {
                        UIPasteboard.general.string = reportCSV
                    }
                    .buttonStyle(NeonPrimaryButtonStyle())
                }
                .padding()
                .navigationTitle("Report CSV")
            }
        }
    }
}

struct SchedulerLabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var draftCaption = ""
    @State private var selectedSurface: PostSurfaceStyle = .chat
    @State private var selectedDate = Date().addingTimeInterval(3600)
    @State private var includeImage = false
    @State private var cadence: ScheduleCadence = .once
    @State private var priority = 50.0
    @State private var selectedRecommendedSlot: Date?
    @State private var selectedZoneID = "America/New_York"
    @State private var selectedPreset: SchedulePriorityPreset = .balanced
    @State private var csvPreview = ""
    @State private var showCSVSheet = false

    var body: some View {
        let slots = appState.recommendedScheduleSlots(for: selectedSurface)
        let zoneIDs = ["America/New_York", "Europe/London", "Asia/Tokyo", "America/Los_Angeles", "Australia/Sydney"]
        let globalSlots = appState.recommendedGlobalScheduleSlots(for: selectedSurface, zoneIDs: zoneIDs)
        let conflicts = appState.schedulingConflicts(around: selectedDate, withinMinutes: 45)
        ZStack {
            EliteBackground()
            Form {
                Section("Schedule Composer") {
                    Picker("Surface", selection: $selectedSurface) {
                        Text("Chat").tag(PostSurfaceStyle.chat)
                        Text("Chit").tag(PostSurfaceStyle.chit)
                    }
                    .pickerStyle(.segmented)
                    Picker("Cadence", selection: $cadence) {
                        ForEach(ScheduleCadence.allCases) { cadence in
                            Text(cadence.rawValue.capitalized).tag(cadence)
                        }
                    }
                    HStack {
                        Text("Priority")
                        Slider(value: $priority, in: 1...100, step: 1)
                        Text("\(Int(priority))")
                            .font(.caption)
                    }
                    DatePicker("Publish at", selection: $selectedDate)
                    Toggle("Auto-include media", isOn: $includeImage)
                    TextField("Draft caption", text: $draftCaption, axis: .vertical)
                        .lineLimit(2...5)
                    Button("Add to Queue") {
                        appState.schedulePost(
                            caption: draftCaption,
                            publishAt: selectedDate,
                            surfaceStyle: selectedSurface,
                            includesImage: includeImage,
                            cadence: cadence,
                            priority: Int(priority)
                        )
                        draftCaption = ""
                    }
                    .buttonStyle(NeonPrimaryButtonStyle())
                    Button("Auto-schedule best slot (AI)") {
                        _ = appState.autoScheduleBestPost(
                            caption: draftCaption.isEmpty ? "Auto-scheduled creator update." : draftCaption,
                            surfaceStyle: selectedSurface,
                            includesImage: includeImage,
                            cadence: cadence
                        )
                        draftCaption = ""
                    }
                    .buttonStyle(.borderedProminent)
                    if !conflicts.isEmpty {
                        Text("Potential conflicts near selected time: \(conflicts.count)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Section("Priority Preset") {
                    Picker("Preset", selection: $selectedPreset) {
                        ForEach(SchedulePriorityPreset.allCases) { preset in
                            Text(preset.rawValue.capitalized).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                    Button("Apply preset to ranking + queue") {
                        appState.applySchedulePriorityPreset(selectedPreset)
                        _ = appState.reorderScheduledQueueByPriority()
                    }
                    .buttonStyle(.borderedProminent)
                }

                Section("Recommended Slots") {
                    ForEach(slots, id: \.self) { slot in
                        Button(slot.formatted(date: .abbreviated, time: .shortened)) {
                            selectedDate = slot
                            selectedRecommendedSlot = slot
                        }
                    }
                    if let selectedRecommendedSlot {
                        Text("Selected: \(selectedRecommendedSlot.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    Picker("Focus Timezone", selection: $selectedZoneID) {
                        ForEach(zoneIDs, id: \.self) { zone in
                            Text(zone).tag(zone)
                        }
                    }
                    ForEach(globalSlots.filter { $0.zone == selectedZoneID || selectedZoneID.isEmpty }, id: \.zone) { entry in
                        Text("\(entry.zone): \(entry.label)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Button("Queue top 3 recommended now") {
                        for slot in slots.prefix(3) {
                            appState.schedulePost(
                                caption: draftCaption.isEmpty ? "Auto scheduled from recommended slot." : draftCaption,
                                publishAt: slot,
                                surfaceStyle: selectedSurface,
                                includesImage: includeImage,
                                cadence: cadence
                            )
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                Section("Scheduled Queue") {
                    Button("Optimize queue spacing") {
                        _ = appState.optimizeScheduleQueue(minimumGapMinutes: 45)
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Sort queue by priority score") {
                        _ = appState.reorderScheduledQueueByPriority()
                    }
                    .buttonStyle(.bordered)
                    Button("Auto-reschedule low performers") {
                        _ = appState.autoRescheduleLowPerformingWindows(threshold: 35.0)
                    }
                    .buttonStyle(.bordered)
                    Button("Auto-post enterprise summary to Pulse") {
                        appState.autoPostEnterpriseSummaryToPulse()
                    }
                    .buttonStyle(.bordered)
                    Button("Send daily summary DM") {
                        appState.sendDailySummaryDMToCreatorThread()
                    }
                    .buttonStyle(.bordered)
                    if appState.scheduledPosts.isEmpty {
                        Text("No scheduled posts yet.")
                            .foregroundStyle(.white.opacity(0.75))
                    } else {
                        ForEach(appState.scheduledPosts) { plan in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plan.caption)
                                    .foregroundStyle(.white)
                                    .lineLimit(2)
                                Text("\(plan.surfaceStyle.rawValue.capitalized) • \(plan.publishAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.72))
                                Text("Cadence: \(plan.cadence.rawValue.capitalized)")
                                    .font(.caption2)
                                    .foregroundStyle(BrandPalette.neonBlue)
                                Text(String(format: "Priority score: %.1f", appState.schedulingPriorityScore(for: plan)))
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.7))
                                HStack {
                                    Button("Publish now") {
                                        appState.publishScheduledPost(plan.id)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    Button("Skip next") {
                                        appState.skipNextScheduledOccurrence(plan.id)
                                    }
                                    .buttonStyle(.bordered)
                                    Button("Remove") {
                                        appState.removeScheduledPost(plan.id)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }

                Section("Analytics Snapshots") {
                    Button("Capture snapshot now") {
                        appState.captureAnalyticsSnapshot()
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Export CSV Preview") {
                        csvPreview = appState.analyticsCSV()
                        showCSVSheet = true
                    }
                    .buttonStyle(.bordered)
                    ForEach(appState.analyticsSnapshots.prefix(6)) { snap in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(snap.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption.bold())
                                .foregroundStyle(BrandPalette.neonBlue)
                            Text("L \(snap.likes) • C \(snap.comments) • R \(snap.reposts) • S \(snap.saves)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                            Text(String(format: "Revenue est: $%.2f", snap.estimatedRevenueUSD))
                                .font(.caption2)
                                .foregroundStyle(BrandPalette.neonGreen)
                        }
                    }
                }
                Section("Weekly Heatmap") {
                    ForEach(appState.weekdayPerformanceHeatmap()) { row in
                        HStack {
                            Text(row.weekday)
                            Spacer()
                            Text(String(format: "%.0f", row.score))
                                .foregroundStyle(BrandPalette.neonGreen)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Scheduler Lab")
        .sheet(isPresented: $showCSVSheet) {
            NavigationStack {
                VStack(spacing: 10) {
                    TextEditor(text: $csvPreview)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(BrandPalette.cardBg.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Button("Copy CSV to Clipboard") {
                        UIPasteboard.general.string = csvPreview
                    }
                    .buttonStyle(NeonPrimaryButtonStyle())
                }
                .padding()
                .navigationTitle("CSV Export")
            }
        }
    }
}

struct CloseFriendsFeedView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    let surfaceStyle: PostSurfaceStyle
    let sortMode: FeedSortMode

    var body: some View {
        let posts = appState.closeFriendsFeedPosts(sortMode: sortMode).filter {
            $0.type != .story && ($0.surfaceStyle == surfaceStyle || $0.type != .post)
        }
        VStack(spacing: 14) {
            if posts.isEmpty {
                EliteCard {
                    Text("No close-friends posts yet. Add close friends in Connections.")
                        .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                }
            } else {
                ForEach(posts.prefix(12)) { post in
                    EliteCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(post.authorHandle)
                                    .font(.headline)
                                    .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                                Spacer()
                                Text("Close Friends")
                                    .font(.caption2.bold())
                                    .foregroundStyle(BrandPalette.neonGreen)
                            }
                            Text(post.caption)
                                .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                        }
                    }
                }
            }
        }
    }
}

struct FeedView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    let isFollowingOnly: Bool
    let surfaceStyle: PostSurfaceStyle
    let sortMode: FeedSortMode
    @State private var editingPost: PostItem?
    @State private var selectedPost: PostItem?
    @State private var commentingPost: PostItem?
    @State private var likesPost: PostItem?
    @State private var repostsPost: PostItem?
    @State private var reactionPickerPost: PostItem?
    @State private var draftComment = ""
    @State private var editedCaption = ""
    @State private var expandedCaptionPostIDs: Set<UUID> = []
    @State private var heartPulsePostID: UUID?
    private var primaryText: Color { BrandPalette.adaptiveTextPrimary(for: colorScheme) }
    private var secondaryText: Color { BrandPalette.adaptiveTextSecondary(for: colorScheme) }

    var body: some View {
        LazyVStack(spacing: 14) {
            ForEach(appState.feedPosts(isFollowingOnly: isFollowingOnly, sortMode: sortMode).filter { post in
                post.type != .story && (post.type != .post || post.surfaceStyle == surfaceStyle)
            }.sorted(by: { lhs, rhs in
                let lPinned = appState.isPostPinned(lhs.id)
                let rPinned = appState.isPostPinned(rhs.id)
                if lPinned != rPinned { return lPinned && !rPinned }
                return lhs.createdAt > rhs.createdAt
            }).prefix(12)) { post in
                ViolenceWarningGate(postID: post.id, isRequired: post.violenceWarningRequired) {
                VStack(spacing: 0) {
                EliteCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(post.authorHandle)
                                .font(.headline)
                                .foregroundStyle(primaryText)
                            if appState.isPostPinned(post.id) {
                                Image(systemName: "pin.fill")
                                    .font(.caption2)
                                    .foregroundStyle(BrandPalette.neonBlue)
                            }
                            Spacer()
                            Text(post.city)
                                .font(.caption2)
                                .foregroundStyle(BrandPalette.neonGreen)
                            Spacer().frame(width: 8)
                            Text(post.type.rawValue.capitalized)
                                .font(.caption)
                                .foregroundStyle(secondaryText)
                            if post.type == .story {
                                Text(post.storyAudience.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(post.storyAudience == .closeFriends ? BrandPalette.neonGreen : secondaryText)
                            }
                            if post.authorHandle == appState.currentUser.handle {
                                Menu {
                                    Button("Edit caption") {
                                        editingPost = post
                                        editedCaption = post.caption
                                    }
                                    Button("Delete post", role: .destructive) {
                                        appState.deletePostWithUndo(post.id)
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .foregroundStyle(secondaryText)
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(post.caption)
                                .font(.body)
                                .foregroundStyle(primaryText)
                                .lineLimit(expandedCaptionPostIDs.contains(post.id) ? nil : 3)
                            if let combined = post.combinedOwnerHandle, !combined.isEmpty {
                                Label("Combined post • \(combined)", systemImage: "person.2.fill")
                                    .font(.caption2)
                                    .foregroundStyle(BrandPalette.neonGreen.opacity(0.92))
                            }
                            if !post.taggedHandles.isEmpty {
                                Text("Tagged: \(post.taggedHandles.joined(separator: " "))")
                                    .font(.caption2)
                                    .foregroundStyle(secondaryText)
                            }
                            if let reaction = appState.reaction(for: post.id) {
                                Text("Your vibe: \(reaction)")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(BrandPalette.neonBlue.opacity(0.18))
                                    .clipShape(Capsule())
                            }
                            if post.caption.count > 140 {
                                Button(expandedCaptionPostIDs.contains(post.id) ? "Show less" : "Read more") {
                                    if expandedCaptionPostIDs.contains(post.id) {
                                        expandedCaptionPostIDs.remove(post.id)
                                    } else {
                                        expandedCaptionPostIDs.insert(post.id)
                                    }
                                }
                                .buttonStyle(.plain)
                                .font(.caption.bold())
                                .foregroundStyle(BrandPalette.neonBlue)
                            }
                        }
                        if let imageData = post.imageData, let image = UIImage(data: imageData) {
                            feedImageView(
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill(),
                                post: post
                            )
                        } else if let fallbackURL = demoFeedPhotoURL(for: post) {
                            feedImageView(
                                AsyncImage(url: fallbackURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    case .failure:
                                        Color.black.opacity(0.24)
                                    case .empty:
                                        ProgressView().tint(.white)
                                    @unknown default:
                                        Color.black.opacity(0.24)
                                    }
                                },
                                post: post
                            )
                        }
                        HStack {
                            HStack(spacing: 18) {
                                iconMetricButton(
                                    icon: "heart.fill",
                                    value: post.likeCount,
                                    tint: .pink,
                                    disabled: post.areLikesHidden,
                                    action: { appState.addLike(to: post.id) },
                                    metricAction: { likesPost = post }
                                )

                                iconMetricButton(
                                    icon: "bubble.right.fill",
                                    value: post.commentCount,
                                    tint: BrandPalette.neonBlue,
                                    disabled: post.areCommentsHidden,
                                    action: {
                                        draftComment = ""
                                        commentingPost = post
                                    },
                                    metricAction: nil
                                )

                                iconMetricButton(
                                    icon: "arrow.2.squarepath",
                                    value: post.repostCount,
                                    tint: BrandPalette.neonGreen,
                                    disabled: false,
                                    action: { appState.repostPost(post.id) },
                                    metricAction: { repostsPost = post }
                                )
                            }

                            Spacer(minLength: 8)

                            Button {
                                appState.toggleSavedPost(post.id)
                            } label: {
                                Image(systemName: appState.savedPostIDs.contains(post.id) ? "bookmark.fill" : "bookmark")
                                    .foregroundStyle(appState.savedPostIDs.contains(post.id) ? BrandPalette.accentPink : secondaryText)
                                    .font(.headline)
                                    .frame(width: 28, height: 28)
                                    .padding(6)
                                    .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.82))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(appState.savedPostIDs.contains(post.id) ? "Unsave post" : "Save post")

                            if post.authorHandle == appState.currentUser.handle {
                                Button {
                                    appState.archivePost(post.id)
                                } label: {
                                    Image(systemName: "archivebox.fill")
                                        .foregroundStyle(BrandPalette.accentPink)
                                        .font(.headline)
                                        .frame(width: 28, height: 28)
                                        .padding(6)
                                        .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.82))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Archive post")
                            }

                            Button {
                                appState.togglePinPost(post.id)
                            } label: {
                                Image(systemName: appState.isPostPinned(post.id) ? "pin.slash.fill" : "pin.fill")
                                    .foregroundStyle(BrandPalette.neonBlue)
                                    .font(.headline)
                                    .frame(width: 28, height: 28)
                                    .padding(6)
                                    .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.82))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(appState.isPostPinned(post.id) ? "Unpin post" : "Pin post")
                        }
                        .font(.caption.bold())
                    }
                }
                .contextMenu {
                    Button("Like", systemImage: "heart.fill") {
                        appState.addLike(to: post.id)
                    }
                    Button("React", systemImage: "face.smiling") {
                        reactionPickerPost = post
                    }
                    Button("Comment", systemImage: "bubble.right.fill") {
                        draftComment = ""
                        commentingPost = post
                    }
                    Button(appState.savedPostIDs.contains(post.id) ? "Unsave" : "Save", systemImage: appState.savedPostIDs.contains(post.id) ? "bookmark.slash.fill" : "bookmark.fill") {
                        appState.toggleSavedPost(post.id)
                    }
                    Button(appState.isPostPinned(post.id) ? "Unpin" : "Pin", systemImage: appState.isPostPinned(post.id) ? "pin.slash.fill" : "pin.fill") {
                        appState.togglePinPost(post.id)
                    }
                    if post.surfaceStyle == .chat {
                        Button("Quick Reply", systemImage: "arrowshape.turn.up.left.fill") {
                            appState.replyToPost(post.id, text: "Great take, thanks for sharing.")
                        }
                        Button("Quick Quote", systemImage: "quote.bubble.fill") {
                            appState.quotePost(post.id, commentary: "Strong point. Building on this.", surfaceStyle: .chat)
                        }
                    }
                    if post.authorHandle.caseInsensitiveCompare(appState.currentUser.handle) == .orderedSame {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            appState.deletePostWithUndo(post.id)
                        }
                    }
                }
                        HStack(spacing: 0) {
                            socialActionButton(title: "Like", system: "hand.thumbsup") {
                                appState.addLike(to: post.id)
                            }
                            socialActionButton(title: "Comment", system: "bubble.right") {
                                draftComment = ""
                                commentingPost = post
                            }
                            socialActionButton(title: "Share", system: "arrowshape.turn.up.right") {
                                appState.repostPost(post.id)
                            }
                            socialActionButton(title: "React", system: "face.smiling") {
                                reactionPickerPost = post
                            }
                        }
                        .padding(.top, 4)
                }
                }
            }
        }
        .sheet(item: $editingPost) { post in
            NavigationStack {
                Form {
                    Section("Edit caption") {
                        TextField("Caption", text: $editedCaption, axis: .vertical)
                            .lineLimit(2...5)
                        Button("Save changes") {
                            appState.updatePostCaption(postID: post.id, newCaption: editedCaption)
                            editingPost = nil
                            editedCaption = ""
                        }
                        .buttonStyle(NeonPrimaryButtonStyle())
                    }
                }
                .navigationTitle("Edit Post")
            }
        }
        .sheet(item: $selectedPost) { post in
            NavigationStack {
                ZStack {
                    EliteBackground()
                    ViolenceWarningGate(postID: post.id, isRequired: post.violenceWarningRequired) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                if let imageData = post.imageData, let image = UIImage(data: imageData) {
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
                }
                .navigationTitle("Post")
            }
        }
        .sheet(item: $commentingPost) { post in
            NavigationStack {
                ZStack {
                    EliteBackground()
                    List {
                        if appState.comments(for: post.id).isEmpty {
                            Section {
                                Text("No comments yet. Start the conversation.")
                                    .foregroundStyle(secondaryText)
                            }
                        } else {
                            Section("Comments") {
                                ForEach(appState.comments(for: post.id)) { comment in
                                    HStack(alignment: .top, spacing: 10) {
                                        profileAvatar(for: comment.authorHandle, size: 34)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(comment.authorHandle)
                                                .font(.caption.bold())
                                                .foregroundStyle(BrandPalette.neonGreen)
                                            Text(comment.text)
                                                .foregroundStyle(primaryText)
                                            Text(comment.createdAt, style: .relative)
                                                .font(.caption2)
                                                .foregroundStyle(secondaryText)
                                        }
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .safeAreaInset(edge: .bottom) {
                    HStack(spacing: 8) {
                        TextField("Add a comment...", text: $draftComment, axis: .vertical)
                            .lineLimit(1...3)
                            .textFieldStyle(.roundedBorder)
                        Button("Post") {
                            if appState.addComment(to: post.id, text: draftComment) {
                                draftComment = ""
                            }
                        }
                        .buttonStyle(NeonPrimaryButtonStyle())
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    .background(.ultraThinMaterial)
                }
                .navigationTitle("Comments")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.fraction(0.45), .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $likesPost) { post in
            engagementSheet(
                title: "Likes",
                users: appState.usersForLikes(postID: post.id)
            )
            .presentationDetents([.fraction(0.42), .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $repostsPost) { post in
            engagementSheet(
                title: "Reposts",
                users: appState.usersForReposts(postID: post.id)
            )
            .presentationDetents([.fraction(0.42), .large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Pick reaction", isPresented: Binding(
            get: { reactionPickerPost != nil },
            set: { if !$0 { reactionPickerPost = nil } }
        ), titleVisibility: .visible) {
            Button("🔥") { applyReaction("🔥") }
            Button("😂") { applyReaction("😂") }
            Button("😮") { applyReaction("😮") }
            Button("💯") { applyReaction("💯") }
            Button("👏") { applyReaction("👏") }
            Button("Cancel", role: .cancel) { reactionPickerPost = nil }
        }
    }

    @ViewBuilder
    private func iconMetricButton(
        icon: String,
        value: Int,
        tint: Color,
        disabled: Bool,
        action: @escaping () -> Void,
        metricAction: (() -> Void)?
    ) -> some View {
        HStack(spacing: 6) {
            Button(action: action) {
                Image(systemName: icon)
                    .foregroundStyle(disabled ? .white.opacity(0.62) : tint)
                    .font(.headline)
                    .frame(width: 24, height: 24)
                    .padding(8)
                    .background(BrandPalette.cardBg.opacity(0.72))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(disabled)
            .accessibilityLabel(icon)

            if !disabled {
                if let metricAction {
                    Button(action: metricAction) {
                        Text("\(value)")
                            .foregroundStyle(primaryText.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("\(value)")
                        .foregroundStyle(primaryText.opacity(0.9))
                }
            }
        }
    }

    @ViewBuilder
    private func socialActionButton(title: String, system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: system)
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(primaryText.opacity(0.9))
            .frame(maxWidth: .infinity, minHeight: 34)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func engagementSheet(title: String, users: [PostEngagementUser]) -> some View {
        NavigationStack {
            List {
                if users.isEmpty {
                    Text("No \(title.lowercased()) yet.")
                        .foregroundStyle(.white.opacity(0.8))
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(users) { user in
                        HStack(spacing: 10) {
                            profileAvatar(for: user.handle, size: 38)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.displayName)
                                    .foregroundStyle(.white)
                                Text(user.handle)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(EliteBackground())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func profileAvatar(for handle: String, size: CGFloat) -> some View {
        if let data = appState.profilePhoto(for: handle), let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 1))
        } else {
            let label = String(handle.replacingOccurrences(of: "@", with: "").prefix(1)).uppercased()
            Circle()
                .fill(BrandPalette.neonBlue.opacity(0.35))
                .frame(width: size, height: size)
                .overlay(
                    Text(label.isEmpty ? "U" : label)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                )
        }
    }

    @ViewBuilder
    private func feedImageView<Content: View>(_ content: Content, post: PostItem) -> some View {
        ZStack {
            content
                .frame(height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            if heartPulsePostID == post.id {
                Image(systemName: "heart.fill")
                    .font(.system(size: 62))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.28), radius: 8, y: 4)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            triggerFeedDoubleTapLike(post.id)
        }
        .onTapGesture {
            selectedPost = post
        }
    }

    private func triggerFeedDoubleTapLike(_ postID: UUID) {
        appState.addLike(to: postID)
        heartPulsePostID = postID
        HapticTokens.medium()
        withAnimation(.spring(response: 0.24, dampingFraction: 0.75)) {}
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 520_000_000)
            if heartPulsePostID == postID {
                withAnimation(.easeOut(duration: 0.2)) {
                    heartPulsePostID = nil
                }
            }
        }
    }

    private func applyReaction(_ emoji: String) {
        guard let target = reactionPickerPost else { return }
        appState.setPostReaction(postID: target.id, emoji: emoji)
        reactionPickerPost = nil
    }

    private func demoFeedPhotoURL(for post: PostItem) -> URL? {
        let query = post.type == .post ? "animal,portrait" : "character,cinematic"
        return URL(string: "https://loremflickr.com/1080/1080/\(query)?lock=\(abs(post.id.uuidString.hashValue % 99999))")
    }
}

struct ChatPostsFeedView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    let isFollowingOnly: Bool
    let sortMode: FeedSortMode
    @State private var composeTarget: PostItem?
    @State private var composeText = ""
    @State private var composeMode: ChatComposeMode = .reply
    @State private var repliesPost: PostItem?

    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(appState.feedPosts(isFollowingOnly: isFollowingOnly, sortMode: sortMode).filter {
                $0.type != .story && ($0.type != .post || $0.surfaceStyle == .chat)
            }.sorted(by: { lhs, rhs in
                let lPinned = appState.isPostPinned(lhs.id)
                let rPinned = appState.isPostPinned(rhs.id)
                if lPinned != rPinned { return lPinned && !rPinned }
                return lhs.createdAt > rhs.createdAt
            }).prefix(20)) { post in
                EliteSectionCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(post.authorHandle)
                                .font(.headline)
                                .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                            if appState.isPostPinned(post.id) {
                                Image(systemName: "pin.fill")
                                    .font(.caption2)
                                    .foregroundStyle(BrandPalette.neonBlue)
                            }
                            Spacer()
                            Text(post.city)
                                .font(.caption2)
                                .foregroundStyle(BrandPalette.neonBlue)
                        }
                        Text(post.caption)
                            .font(.body)
                            .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                        if !post.taggedHandles.isEmpty {
                            Text("Tagged: \(post.taggedHandles.joined(separator: " "))")
                                .font(.caption2)
                                .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                chatActionChip(title: "\(post.likeCount)", system: "heart.fill") {
                                    appState.addLike(to: post.id)
                                }
                                chatActionChip(title: "\(post.commentCount)", system: "bubble.right.fill") {
                                    composeMode = .reply
                                    composeText = ""
                                    composeTarget = post
                                }
                                chatActionChip(title: "Thread", system: "text.bubble.fill") {
                                    repliesPost = post
                                }
                                chatActionChip(title: "\(post.repostCount)", system: "arrow.2.squarepath") {
                                    appState.repostPost(post.id)
                                }
                                chatActionChip(title: "Quote", system: "quote.bubble.fill") {
                                    composeMode = .quote
                                    composeText = ""
                                    composeTarget = post
                                }
                                chatActionChip(title: appState.isPostPinned(post.id) ? "Unpin" : "Pin", system: appState.isPostPinned(post.id) ? "pin.slash.fill" : "pin.fill") {
                                    appState.togglePinPost(post.id)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .sheet(item: $composeTarget) { post in
            NavigationStack {
                Form {
                    Section(composeMode == .reply ? "Reply" : "Quote") {
                        Text("To: \(post.authorHandle)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField(composeMode == .reply ? "Write your reply..." : "Add your quote...", text: $composeText, axis: .vertical)
                            .lineLimit(2...6)
                        Button(composeMode == .reply ? "Send Reply" : "Publish Quote") {
                            if composeMode == .reply {
                                appState.replyToPost(post.id, text: composeText)
                            } else {
                                appState.quotePost(post.id, commentary: composeText, surfaceStyle: .chat)
                            }
                            composeTarget = nil
                            composeText = ""
                        }
                        .buttonStyle(NeonPrimaryButtonStyle())
                    }
                }
                .navigationTitle(composeMode == .reply ? "Reply" : "Quote")
            }
        }
        .sheet(item: $repliesPost) { post in
            NavigationStack {
                ZStack {
                    EliteBackground()
                    List {
                        Section("Thread for \(post.authorHandle)") {
                            Text(post.caption)
                                .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                        }
                        Section("Replies") {
                            if appState.comments(for: post.id).isEmpty {
                                Text("No replies yet.")
                                    .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                            } else {
                                ForEach(appState.comments(for: post.id)) { reply in
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(reply.authorHandle)
                                            .font(.caption.bold())
                                            .foregroundStyle(BrandPalette.neonGreen)
                                        Text(reply.text)
                                            .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
                .navigationTitle("Replies")
            }
            .presentationDetents([.fraction(0.45), .large])
        }
    }

    private func chatActionChip(title: String, system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: system)
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(BrandPalette.cardBg.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(BrandPalette.glassStroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func socialActionButton(title: String, system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: system)
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.88))
            .frame(maxWidth: .infinity, minHeight: 34)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private enum ChatComposeMode {
    case reply
    case quote
}

private struct LoopingVideoView: View {
    let url: URL
    @Binding var isMuted: Bool
    @State private var player = AVQueuePlayer()
    @State private var looper: AVPlayerLooper?

    var body: some View {
        ZStack {
            Color.black
            VideoPlayer(player: player)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .scaledToFill()
                .clipped()
        }
        .onAppear {
            guard looper == nil else { return }
            let item = AVPlayerItem(url: url)
            looper = AVPlayerLooper(player: player, templateItem: item)
            player.isMuted = isMuted
            player.play()
        }
        .onChange(of: isMuted) { _, new in
            player.isMuted = new
        }
        .onDisappear {
            player.pause()
            looper = nil
        }
    }
}

/// Plays video from in-memory data (user reels); caches one file per post id in Caches.
private struct LoopingVideoDataView: View {
    let videoData: Data
    let postID: UUID
    @Binding var isMuted: Bool
    @State private var player = AVQueuePlayer()
    @State private var looper: AVPlayerLooper?
    @State private var resolvedURL: URL?
    @State private var loadFailed = false

    var body: some View {
        ZStack {
            Color.black
            VideoPlayer(player: player)
                .opacity(resolvedURL != nil && !loadFailed ? 1 : 0)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .scaledToFill()
                .clipped()
            if loadFailed {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.9))
                    Text("Couldn't play this video")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.92))
                }
            } else if resolvedURL == nil {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
            }
        }
        .onAppear {
            loadFailed = false
            prepareAndPlayIfNeeded()
        }
        .onChange(of: isMuted) { _, new in
            player.isMuted = new
        }
        .onDisappear {
            player.pause()
            looper = nil
        }
    }

    private func prepareAndPlayIfNeeded() {
        guard looper == nil else { return }
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let url = caches.appendingPathComponent("chitchat-reel-\(postID.uuidString).mp4", isDirectory: false)
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try videoData.write(to: url, options: [.atomic])
            } catch {
                loadFailed = true
                return
            }
        }
        guard FileManager.default.fileExists(atPath: url.path) else {
            loadFailed = true
            return
        }
        resolvedURL = url
        let item = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: player, templateItem: item)
        player.isMuted = isMuted
        player.play()
    }
}

struct ReelsView: View {
    private enum ReelCommentSortMode: String, CaseIterable, Identifiable {
        case newest = "Newest"
        case oldest = "Oldest"
        case pinnedFirst = "Pinned First"
        var id: String { rawValue }
    }

    @EnvironmentObject private var appState: AppState
    @State private var selectedIndex = 0
    @State private var animationPhase: CGFloat = 0.0
    @State private var likedReelIDs: Set<UUID> = []
    @State private var sharedReelIDs: Set<UUID> = []
    @State private var quickFollowedHandles: Set<String> = []
    @State private var heartPulseReelID: UUID?
    @State private var toastMessage = ""
    @State private var remixTarget: ReelDemoItem?
    @State private var remixCaption = ""
    @State private var inlineCommentsTarget: ReelDemoItem?
    @State private var reelCommentDraft = ""
    @State private var saveTarget: ReelDemoItem?
    @State private var audioTarget: ReelDemoItem?
    @State private var customCollectionName = ""
    @State private var renameSourceCollection = ""
    @State private var renameTargetCollection = ""
    @State private var commentDrawerOffset: CGFloat = 420
    @State private var commentDrawerDrag: CGFloat = 0
    @State private var pinnedReelCommentIDs: Set<UUID> = []
    @State private var reelCommentSortMode: ReelCommentSortMode = .newest
    @State private var replyingToComment: PostComment?
    @State private var editingReelComment: PostComment?
    @State private var editReelCommentDraft = ""
    /// Reels autoplay muted by default; user can unmute from the rail.
    @State private var reelsMuted = true

    private var safeReelItems: [ReelDemoItem] { reelItems }

    @ViewBuilder private var reelEmptyState: some View {
        VStack(spacing: 22) {
            HStack {
                Button {
                    appState.requestedTabIndex = 0
                } label: {
                    Image(systemName: "house.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(12)
                        .background(Circle().fill(.black.opacity(0.4)))
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 18)
            Spacer()
            Image(systemName: "film.stack")
                .font(.system(size: 52, weight: .medium))
                .foregroundStyle(.white.opacity(0.65))
            Text("No reels yet")
                .font(.title3.bold())
                .foregroundStyle(.white.opacity(0.95))
            Text("Post a vertical video from Create — it will show up here for you and your followers.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.72))
                .padding(.horizontal, 28)
            Button {
                appState.requestedTabIndex = 2
            } label: {
                Label("Create a reel", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(BrandPalette.neonBlue))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()
                if safeReelItems.isEmpty {
                    reelEmptyState
                } else {
                TabView(selection: $selectedIndex) {
                    ForEach(Array(safeReelItems.enumerated()), id: \.element.id) { index, item in
                        ViolenceWarningGate(postID: item.id, isRequired: item.violenceWarningRequired) {
                        ZStack(alignment: .bottom) {
                            reelBackground(for: item)
                                .overlay {
                                    if heartPulseReelID == item.id {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 86, weight: .bold))
                                            .foregroundStyle(.white.opacity(0.92))
                                            .shadow(color: .black.opacity(0.25), radius: 16, y: 6)
                                            .scaleEffect(1.0 + (animationPhase * 0.2))
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .contextMenu {
                                    Button {
                                        openInlineComments(for: item)
                                    } label: {
                                        Label("Comments", systemImage: "bubble.right")
                                    }
                                    if canDeleteReel(item) {
                                        Button(role: .destructive) {
                                            if inlineCommentsTarget?.id == item.id {
                                                inlineCommentsTarget = nil
                                            }
                                            appState.deletePostWithUndo(item.id)
                                            showToast("Reel deleted")
                                        } label: {
                                            Label("Delete reel", systemImage: "trash")
                                        }
                                    }
                                }
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.72)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .ignoresSafeArea()

                            VStack(spacing: 10) {
                                HStack {
                                    Button {
                                        appState.requestedTabIndex = 0
                                    } label: {
                                        Image(systemName: "house.fill")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(.white.opacity(0.9))
                                            .padding(10)
                                            .background(Circle().fill(.black.opacity(0.35)))
                                    }
                                    .buttonStyle(.plain)
                                    progressHeader(for: item, isActive: selectedIndex == index)
                                }
                                .padding(.top, max(4, proxy.safeAreaInsets.top))
                                .padding(.horizontal, 14)

                                Spacer()

                                HStack {
                                    reelInfoPanel(for: item)
                                    Spacer()
                                    rightRail(for: item)
                                }
                                .padding(.horizontal, 14)
                                .padding(.bottom, max(20, proxy.safeAreaInsets.bottom + 8))
                            }
                        }
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .contentShape(Rectangle())
                        .simultaneousGesture(
                            TapGesture(count: 2).onEnded { triggerDoubleTapLike(item) }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                .onChange(of: safeReelItems.count) { _, newCount in
                    selectedIndex = safeReelItems.clampedIndex(selectedIndex)
                }
                .onChange(of: safeReelItems.map(\.id)) { _, ids in
                    if let target = inlineCommentsTarget, !ids.contains(target.id) {
                        inlineCommentsTarget = nil
                    }
                }
                }

                if !toastMessage.isEmpty {
                    VStack {
                        Spacer()
                        Text(toastMessage)
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.62))
                            .clipShape(Capsule())
                            .foregroundStyle(.white)
                            .padding(.bottom, max(18, proxy.safeAreaInsets.bottom + 8))
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if appState.canUndoPostDeletion {
                    VStack {
                        HStack(spacing: 8) {
                            Text("Post deleted")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                            Spacer()
                            Button("Undo") {
                                if appState.undoLastDeletedPost() {
                                    showToast("Post restored")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(10)
                        .background(.black.opacity(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 12)
                        Spacer()
                    }
                    .padding(.top, max(12, proxy.safeAreaInsets.top))
                }

                if let item = inlineCommentsTarget {
                    inlineCommentsDrawer(for: item, bottomInset: proxy.safeAreaInsets.bottom)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(4)
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                    animationPhase = 1.0
                }
            }
            .sheet(item: $remixTarget) { item in
                NavigationStack {
                    Form {
                        Section("Remix \(item.authorHandle)") {
                            Text("Audio: \(item.audioTitle)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("Add your remix caption...", text: $remixCaption, axis: .vertical)
                                .lineLimit(2...5)
                            Button("Publish Remix") {
                                let text = remixCaption.trimmingCharacters(in: .whitespacesAndNewlines)
                                _ = appState.publishPost(
                                    caption: text.isEmpty ? "Remix using \(item.audioTitle)" : text,
                                    type: .reel,
                                    imageData: item.imageData,
                                    videoData: item.videoData,
                                    storyAudience: .public,
                                    audience: .public,
                                    isCollab: true,
                                    areLikesHidden: appState.hideLikeCountsByDefault,
                                    areCommentsHidden: appState.hideCommentCountsByDefault,
                                    blockNudity: true,
                                    surfaceStyle: .chit
                                )
                                remixCaption = ""
                                remixTarget = nil
                            }
                            .buttonStyle(NeonPrimaryButtonStyle())
                        }
                    }
                    .navigationTitle("Remix")
                }
            }
            .sheet(item: $saveTarget) { item in
                NavigationStack {
                    Form {
                        Section("Save to collections") {
                            ForEach(appState.reelCollectionNames, id: \.self) { name in
                                Button {
                                    appState.toggleReelCollection(item.id, collection: name)
                                } label: {
                                    HStack {
                                        Text(name.capitalized)
                                        Text("(\(appState.reelCollectionCount(name)))")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        if appState.isReelSaved(item.id, collection: name) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(BrandPalette.neonGreen)
                                        }
                                    }
                                }
                            }
                        }
                        Section("Create collection") {
                            TextField("Collection name", text: $customCollectionName)
                            Button("Save") {
                                appState.toggleReelCollection(item.id, collection: customCollectionName)
                                customCollectionName = ""
                            }
                            .buttonStyle(NeonPrimaryButtonStyle())
                        }
                        Section("Manage collections") {
                            TextField("Rename from", text: $renameSourceCollection)
                            TextField("Rename to", text: $renameTargetCollection)
                            Button("Rename collection") {
                                appState.renameReelCollection(from: renameSourceCollection, to: renameTargetCollection)
                                renameSourceCollection = ""
                                renameTargetCollection = ""
                            }
                            .buttonStyle(.borderedProminent)
                            if !appState.reelCollectionNames.isEmpty {
                                ForEach(appState.reelCollectionNames, id: \.self) { name in
                                    Button("Delete \(name.capitalized)", role: .destructive) {
                                        appState.removeReelCollection(name)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Collections")
                }
                .presentationDetents([.fraction(0.45), .large])
            }
            .sheet(item: $audioTarget) { item in
                NavigationStack {
                    Form {
                        Section("Audio Attribution") {
                            Text("Track: \(item.audioTitle)")
                            Text("Source creator: \(item.authorHandle)")
                            Button("Copy Audio Credit") {
                                UIPasteboard.general.string = "Audio: \(item.audioTitle) • \(item.authorHandle)"
                                showToast("Audio credit copied")
                            }
                            .buttonStyle(.bordered)
                        }
                        Section("Create with this audio") {
                            Button("Use Audio in New Reel") {
                                _ = appState.publishPost(
                                    caption: "Created with audio: \(item.audioTitle)",
                                    type: .reel,
                                    imageData: item.imageData,
                                    videoData: item.videoData,
                                    storyAudience: .public,
                                    audience: .public,
                                    isCollab: false,
                                    areLikesHidden: appState.hideLikeCountsByDefault,
                                    areCommentsHidden: appState.hideCommentCountsByDefault,
                                    blockNudity: true,
                                    surfaceStyle: .chit
                                )
                                showToast("Audio attached to draft reel.")
                                audioTarget = nil
                            }
                            .buttonStyle(NeonPrimaryButtonStyle())
                        }
                    }
                    .navigationTitle("Use Audio")
                }
                .presentationDetents([.fraction(0.36), .medium])
            }
            .sheet(item: $editingReelComment) { comment in
                NavigationStack {
                    Form {
                        Section("Edit Comment") {
                            TextField("Comment", text: $editReelCommentDraft, axis: .vertical)
                                .lineLimit(2...6)
                            Button("Save Changes") {
                                guard let item = inlineCommentsTarget else { return }
                                appState.updateComment(postID: item.id, commentID: comment.id, text: editReelCommentDraft)
                                editingReelComment = nil
                            }
                            .buttonStyle(NeonPrimaryButtonStyle())
                        }
                    }
                    .navigationTitle("Comment")
                }
            }
            .ignoresSafeArea(.container, edges: .all)
        }
    }

    @ViewBuilder
    private func inlineCommentsDrawer(for item: ReelDemoItem, bottomInset: CGFloat) -> some View {
        VStack {
            Spacer()
            VStack(spacing: 0) {
                Capsule()
                    .fill(.white.opacity(0.42))
                    .frame(width: 44, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                HStack {
                    Text("Comments")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Menu {
                        ForEach(ReelCommentSortMode.allCases) { mode in
                            Button(mode.rawValue) {
                                reelCommentSortMode = mode
                            }
                        }
                        if !pinnedReelCommentIDs.isEmpty {
                            Button("Clear pinned", role: .destructive) {
                                pinnedReelCommentIDs.removeAll()
                            }
                        }
                    } label: {
                        Label(reelCommentSortMode.rawValue, systemImage: "arrow.up.arrow.down.circle")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.86))
                    }
                    .buttonStyle(.plain)
                    Button {
                        closeInlineComments()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.82))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        let rows = sortedReelComments(
                            appState.posts.contains(where: { $0.id == item.id }) ? appState.comments(for: item.id) : []
                        )
                        if rows.isEmpty {
                            Text("No comments yet. Be first to add one.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.76))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(rows) { comment in
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(comment.authorHandle)
                                            .font(.caption.bold())
                                            .foregroundStyle(BrandPalette.neonBlue)
                                        if pinnedReelCommentIDs.contains(comment.id) {
                                            Image(systemName: "pin.fill")
                                                .font(.caption2)
                                                .foregroundStyle(BrandPalette.neonGreen)
                                        }
                                        Spacer()
                                        Text(comment.createdAt.formatted(date: .omitted, time: .shortened))
                                            .font(.caption2)
                                            .foregroundStyle(.white.opacity(0.62))
                                    }
                                    Text(comment.text)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.92))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, CGFloat(commentNestingLevel(comment)) * 14)
                                .padding(.vertical, 2)
                                .overlay(alignment: .leading) {
                                    if commentNestingLevel(comment) > 0 {
                                        Capsule()
                                            .fill(.white.opacity(0.18))
                                            .frame(width: 2, height: 26)
                                            .offset(x: CGFloat(commentNestingLevel(comment)) * 10)
                                    }
                                }
                                .contextMenu {
                                    Button {
                                        replyingToComment = comment
                                        reelCommentDraft = "@\(comment.authorHandle.replacingOccurrences(of: "@", with: "")) "
                                    } label: {
                                        Label("Reply", systemImage: "arrowshape.turn.up.left")
                                    }
                                    Button {
                                        if pinnedReelCommentIDs.contains(comment.id) {
                                            pinnedReelCommentIDs.remove(comment.id)
                                        } else {
                                            pinnedReelCommentIDs.insert(comment.id)
                                        }
                                    } label: {
                                        Label(
                                            pinnedReelCommentIDs.contains(comment.id) ? "Unpin" : "Pin",
                                            systemImage: pinnedReelCommentIDs.contains(comment.id) ? "pin.slash" : "pin"
                                        )
                                    }
                                    if comment.authorHandle.caseInsensitiveCompare(appState.currentUser.handle) == .orderedSame {
                                        Button {
                                            editReelCommentDraft = comment.text
                                            editingReelComment = comment
                                        } label: {
                                            Label("Edit", systemImage: "square.and.pencil")
                                        }
                                        Button(role: .destructive) {
                                            appState.deleteComment(postID: item.id, commentID: comment.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                }
                .frame(maxHeight: 280)

                HStack(spacing: 8) {
                    if let replyingToComment {
                        Text("Replying to \(replyingToComment.authorHandle)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    TextField("Add comment...", text: $reelCommentDraft)
                        .textFieldStyle(EliteTextFieldStyle())
                    Button("Post") {
                        postInlineComment(for: item)
                    }
                    .buttonStyle(NeonPrimaryButtonStyle())
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, max(10, bottomInset))
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.86))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white.opacity(0.14), lineWidth: 1)
                    )
            )
            .offset(y: max(0, commentDrawerOffset + commentDrawerDrag))
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        if value.translation.height > 0 {
                            commentDrawerDrag = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 120 {
                            closeInlineComments()
                        } else {
                            withAnimation(MotionTokens.spring) {
                                commentDrawerDrag = 0
                            }
                        }
                    }
            )
        }
        .background(Color.black.opacity(0.18).ignoresSafeArea().onTapGesture { closeInlineComments() })
    }

    private var reelItems: [ReelDemoItem] {
        let source = appState.posts.filter { !$0.isArchived && ($0.type == .reel || $0.type == .shortVideo || $0.type == .story) }
        return source.map { post in
            let audioLabel: String = {
                let t = post.caption.trimmingCharacters(in: .whitespacesAndNewlines)
                if t.isEmpty { return "Original audio" }
                if t.count <= 42 { return t }
                return String(t.prefix(39)) + "…"
            }()
            return ReelDemoItem(
                id: post.id,
                authorHandle: post.authorHandle,
                caption: post.caption,
                audioTitle: audioLabel,
                likeCount: post.likeCount,
                commentCount: post.commentCount,
                shareCount: post.repostCount,
                imageData: post.imageData ?? appState.generatedMediaImageData(seed: "\(post.authorHandle)-\(post.id.uuidString)", isReel: true),
                videoData: post.videoData,
                remoteImageURL: nil,
                remoteVideoURL: nil,
                violenceWarningRequired: post.violenceWarningRequired
            )
        }
    }

    @ViewBuilder
    private func reelBackground(for item: ReelDemoItem) -> some View {
        if let vData = item.videoData, !vData.isEmpty {
            LoopingVideoDataView(videoData: vData, postID: item.id, isMuted: $reelsMuted)
                .ignoresSafeArea()
                .id(item.id)
        } else if let remoteVideoURL = item.remoteVideoURL {
            LoopingVideoView(url: remoteVideoURL, isMuted: $reelsMuted)
                .ignoresSafeArea()
                .id(item.id)
        } else if let remoteImageURL = item.remoteImageURL {
            AsyncImage(url: remoteImageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Color.black
                case .empty:
                    ProgressView()
                        .tint(.white)
                @unknown default:
                    Color.black
                }
            }
            .ignoresSafeArea()
        } else if let data = item.imageData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .scaleEffect(1.02 + (animationPhase * 0.03))
        } else {
            LinearGradient(
                colors: [BrandPalette.bgMid, BrandPalette.accentPurple.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(.white.opacity(0.88))
                        .shadow(color: .black.opacity(0.28), radius: 10)
                    Text("AI reel preview")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.92))
                }
                .scaleEffect(1.0 + (animationPhase * 0.04))
            )
        }
    }

    @ViewBuilder
    private func progressHeader(for item: ReelDemoItem, isActive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Capsule()
                .fill(.white.opacity(0.24))
                .frame(height: 4)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(BrandPalette.neonBlue)
                        .frame(width: isActive ? 220 * animationPhase : 220, height: 4)
                }
            Text("Reel • \(item.audioTitle)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.82))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func metricButton(icon: String, value: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 4) {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.title3.bold())
                    .padding(10)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.35))
                            .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
            .buttonStyle(SnappyScaleButtonStyle())
            Text(value)
                .font(.caption.bold())
        }
        .foregroundStyle(.white)
    }

    @ViewBuilder
    private func rightRail(for item: ReelDemoItem) -> some View {
        VStack(spacing: 14) {
            Button {
                reelsMuted.toggle()
            } label: {
                Image(systemName: reelsMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title3.bold())
                    .padding(10)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.35))
                            .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .accessibilityLabel(reelsMuted ? "Unmute reels" : "Mute reels")
            metricButton(icon: isReelLiked(item) ? "heart.fill" : "heart", value: formatMetric(effectiveLikeCount(for: item))) {
                toggleLike(item)
            }
            metricButton(icon: "bubble.right.fill", value: formatMetric(effectiveCommentCount(for: item))) {
                openInlineComments(for: item)
            }
            metricButton(icon: "arrowshape.turn.up.right.fill", value: formatMetric(effectiveShareCount(for: item))) {
                toggleShare(item)
            }
            Button {
                remixTarget = item
            } label: {
                Label("Remix", systemImage: "sparkles.rectangle.stack.fill")
                    .font(.caption.bold())
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(BrandPalette.cardBg.opacity(0.7))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .buttonStyle(SnappyScaleButtonStyle())
            Button {
                saveTarget = item
            } label: {
                Label("Save", systemImage: "bookmark.fill")
                    .font(.caption2.bold())
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(BrandPalette.cardBg.opacity(0.7))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .buttonStyle(SnappyScaleButtonStyle())
            Button {
                appState.toggleReelCollection(item.id, collection: "favorites")
                showToast("Saved to Favorites")
            } label: {
                Label("Fav", systemImage: "star.fill")
                    .font(.caption2.bold())
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(BrandPalette.cardBg.opacity(0.7))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .buttonStyle(SnappyScaleButtonStyle())
            Button {
                audioTarget = item
            } label: {
                Label("Use Audio", systemImage: "music.note")
                    .font(.caption2.bold())
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(BrandPalette.cardBg.opacity(0.7))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .buttonStyle(SnappyScaleButtonStyle())
            Divider().overlay(.white.opacity(0.35))
            followerStack(for: item)
        }
    }

    @ViewBuilder
    private func reelInfoPanel(for item: ReelDemoItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(item.authorHandle)
                    .font(.headline.bold())
                Button(isCreatorFollowed(item.authorHandle) ? "Following" : "Follow") {
                    toggleQuickFollow(item.authorHandle)
                }
                .buttonStyle(.plain)
                .buttonStyle(SnappyScaleButtonStyle())
                .font(.caption.bold())
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(isCreatorFollowed(item.authorHandle) ? Color.white.opacity(0.22) : BrandPalette.neonBlue.opacity(0.28))
                )
            }
            Text(item.caption)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(3)
            HStack(spacing: 8) {
                Label(item.audioTitle, systemImage: "music.note")
                    .font(.caption)
                    .foregroundStyle(BrandPalette.neonGreen.opacity(0.95))
                Spacer(minLength: 0)
                Label("AI Enhanced", systemImage: "sparkles")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.36))
                    .clipShape(Capsule())
            }
            .padding(.top, 2)
            HStack(spacing: 8) {
                actionChip("Comment", "bubble.right.fill") { openInlineComments(for: item) }
                actionChip("Save", "bookmark.fill") { saveTarget = item }
                actionChip("Remix", "sparkles.rectangle.stack.fill") { remixTarget = item }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func actionChip(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.14))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .buttonStyle(SnappyScaleButtonStyle())
        .foregroundStyle(.white)
    }

    @ViewBuilder
    private func followerStack(for item: ReelDemoItem) -> some View {
        VStack(spacing: 8) {
            ForEach(suggestedCreators(for: item)) { creator in
                VStack(spacing: 4) {
                    creatorAvatar(for: creator)
                    Text(formatMetric(creator.followers))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Button(isCreatorFollowed(creator.handle) ? "Following" : "Follow") {
                        toggleQuickFollow(creator.handle)
                    }
                    .buttonStyle(.plain)
                    .buttonStyle(SnappyScaleButtonStyle())
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(
                                isCreatorFollowed(creator.handle)
                                    ? Color.white.opacity(0.18)
                                    : BrandPalette.neonBlue.opacity(0.24)
                            )
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func creatorAvatar(for creator: ReelCreatorBadge) -> some View {
        if let data = appState.profilePhoto(for: creator.handle), let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 38, height: 38)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.65), lineWidth: 1))
                .overlay(alignment: .bottomTrailing) {
                    Circle()
                        .fill(BrandPalette.neonGreen)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(.black.opacity(0.7), lineWidth: 1))
                }
        } else {
            let initial = String(creator.handle.replacingOccurrences(of: "@", with: "").prefix(1)).uppercased()
            Circle()
                .fill(LinearGradient(
                    colors: [BrandPalette.neonBlue, BrandPalette.accentPurple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 38, height: 38)
                .overlay(
                    Text(initial.isEmpty ? "C" : initial)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                )
                .overlay(Circle().stroke(.white.opacity(0.65), lineWidth: 1))
        }
    }

    private func suggestedCreators(for item: ReelDemoItem) -> [ReelCreatorBadge] {
        var candidates = appState.suggestedConnections(limit: 24)
            .map {
                ReelCreatorBadge(
                    id: $0.user.id,
                    handle: $0.user.handle,
                    followers: max($0.user.followers, 1200)
                )
            }
            .filter { $0.handle != item.authorHandle && $0.handle != appState.currentUser.handle }

        if candidates.isEmpty {
            candidates = [
                ReelCreatorBadge(id: UUID(), handle: "@creatorone", followers: 12400),
                ReelCreatorBadge(id: UUID(), handle: "@reelqueen", followers: 19800),
                ReelCreatorBadge(id: UUID(), handle: "@djmike", followers: 8700),
                ReelCreatorBadge(id: UUID(), handle: "@futurelabs", followers: 25200),
                ReelCreatorBadge(id: UUID(), handle: "@alphaframe", followers: 14300),
                ReelCreatorBadge(id: UUID(), handle: "@citypulse", followers: 9100)
            ]
        }

        guard !candidates.isEmpty else { return Array(candidates.prefix(3)) }
        let start = (selectedIndex * 2) % candidates.count
        let rotated = Array(candidates[start...]) + Array(candidates[..<start])
        return Array(rotated.prefix(3))
    }

    private func openInlineComments(for item: ReelDemoItem) {
        HapticTokens.light()
        inlineCommentsTarget = item
        withAnimation(MotionTokens.spring) {
            commentDrawerOffset = 0
            commentDrawerDrag = 0
        }
    }

    private func closeInlineComments() {
        withAnimation(MotionTokens.spring) {
            commentDrawerDrag = 0
            commentDrawerOffset = 420
        }
        replyingToComment = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            inlineCommentsTarget = nil
        }
    }

    private func postInlineComment(for item: ReelDemoItem) {
        let trimmed = reelCommentDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let payload: String
        if let replyingToComment {
            payload = "@\(replyingToComment.authorHandle.replacingOccurrences(of: "@", with: "")) \(trimmed)"
        } else {
            payload = trimmed
        }
        if appState.posts.contains(where: { $0.id == item.id }) {
            _ = appState.addComment(to: item.id, text: payload)
        }
        reelCommentDraft = ""
        replyingToComment = nil
        showToast("Comment posted")
    }

    private func isReelLiked(_ item: ReelDemoItem) -> Bool {
        if appState.posts.contains(where: { $0.id == item.id }) {
            return appState.usersForLikes(postID: item.id).contains {
                $0.handle.caseInsensitiveCompare(appState.currentUser.handle) == .orderedSame
            }
        }
        return likedReelIDs.contains(item.id)
    }

    private func effectiveLikeCount(for item: ReelDemoItem) -> Int {
        if let livePost = appState.posts.first(where: { $0.id == item.id }) {
            return max(0, livePost.likeCount)
        }
        return isReelLiked(item) ? item.likeCount + 1 : item.likeCount
    }

    private func effectiveCommentCount(for item: ReelDemoItem) -> Int {
        if appState.posts.contains(where: { $0.id == item.id }) {
            return appState.comments(for: item.id).count
        }
        return item.commentCount
    }

    private func effectiveShareCount(for item: ReelDemoItem) -> Int {
        sharedReelIDs.contains(item.id) ? item.shareCount + 1 : item.shareCount
    }

    private func toggleLike(_ item: ReelDemoItem) {
        HapticTokens.light()
        if appState.posts.contains(where: { $0.id == item.id }) {
            appState.addLike(to: item.id)
        } else {
            if likedReelIDs.contains(item.id) {
                likedReelIDs.remove(item.id)
            } else {
                likedReelIDs.insert(item.id)
            }
        }
    }

    private func toggleShare(_ item: ReelDemoItem) {
        HapticTokens.medium()
        if sharedReelIDs.contains(item.id) {
            sharedReelIDs.remove(item.id)
        } else {
            sharedReelIDs.insert(item.id)
        }
        if appState.posts.contains(where: { $0.id == item.id }) {
            appState.repostPost(item.id)
        }
        showToast("Shared \(item.authorHandle) reel")
    }

    private func isCreatorFollowed(_ handle: String) -> Bool {
        appState.isFollowing(handle) || quickFollowedHandles.contains(handle.lowercased())
    }

    private func toggleQuickFollow(_ handle: String) {
        let key = handle.lowercased()
        if appState.isFollowing(handle) || quickFollowedHandles.contains(key) {
            appState.unfollow(handle)
            quickFollowedHandles.remove(key)
            showToast("Unfollowed \(handle)")
        } else {
            appState.follow(handle)
            quickFollowedHandles.insert(key)
            showToast("Following \(handle)")
        }
    }

    private func triggerDoubleTapLike(_ item: ReelDemoItem) {
        toggleLike(item)
        withAnimation(.spring(response: 0.26, dampingFraction: 0.78)) {
            heartPulseReelID = item.id
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(.easeOut(duration: 0.22)) {
                if heartPulseReelID == item.id {
                    heartPulseReelID = nil
                }
            }
        }
    }

    private func showToast(_ message: String) {
        withAnimation(.easeInOut(duration: 0.18)) {
            toastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeInOut(duration: 0.2)) {
                if toastMessage == message {
                    toastMessage = ""
                }
            }
        }
    }

    private func canDeleteReel(_ item: ReelDemoItem) -> Bool {
        appState.posts.contains {
            $0.id == item.id && $0.authorHandle.caseInsensitiveCompare(appState.currentUser.handle) == .orderedSame
        }
    }

    private func sortedReelComments(_ rows: [PostComment]) -> [PostComment] {
        switch reelCommentSortMode {
        case .newest:
            return rows.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return rows.sorted { $0.createdAt < $1.createdAt }
        case .pinnedFirst:
            return rows.sorted { lhs, rhs in
                let lPinned = pinnedReelCommentIDs.contains(lhs.id)
                let rPinned = pinnedReelCommentIDs.contains(rhs.id)
                if lPinned != rPinned {
                    return lPinned && !rPinned
                }
                return lhs.createdAt > rhs.createdAt
            }
        }
    }

    private func commentNestingLevel(_ comment: PostComment) -> Int {
        let trimmed = comment.text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("@") ? 1 : 0
    }

    private func formatMetric(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        }
        if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        }
        return "\(value)"
    }
}

private struct ReelDemoItem: Identifiable {
    let id: UUID
    let authorHandle: String
    let caption: String
    let audioTitle: String
    let likeCount: Int
    let commentCount: Int
    let shareCount: Int
    let imageData: Data?
    let videoData: Data?
    let remoteImageURL: URL?
    let remoteVideoURL: URL?
    var violenceWarningRequired: Bool = false
}

private struct ReelCreatorBadge: Identifiable {
    let id: UUID
    let handle: String
    let followers: Int
}

