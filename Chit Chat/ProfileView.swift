//
//  ProfileView.swift
//  Chit Chat
//
//  Created by Brian Bruce on 2025-06-24.
//

import SwiftUI
import PhotosUI
import AVKit

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = "Chit"
    @State private var showBadgeInfo = false
    @State private var showAccountTools = false
    @State private var showCreatorTools = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPost: PostItem?
    @State private var showInsights = false
    @State private var showFollowersSheet = false
    @State private var showFollowingSheet = false
    @State private var showAvatarStory = false
    @State private var showMediaOptions = false
    @State private var showPhotoPicker = false
    @State private var showStoryPhotoPicker = false
    @State private var showAvatarVideoPicker = false
    @State private var showStoryVideoPicker = false
    @State private var avatarVideoSourceItem: PhotosPickerItem?
    @State private var selectedStoryPhotoItem: PhotosPickerItem?
    @State private var selectedStoryVideoItem: PhotosPickerItem?
    @State private var isConvertingAvatarVideo = false
    @State private var conversionStatusMessage = ""
    @State private var quoteDraft = ""
    @State private var showQuoteEditor = false
    @State private var aliasDraft = ""
    @State private var displayNameDraft = ""
    @State private var showIdentityEditor = false
    @State private var profileLinkDraft = ""
    @State private var showVideoBubbleDialog = false
    private let tabs = ["Chit", "Chat", "Reposts", "Combined", "Reels", "Tagged"]
    private var primaryText: Color { BrandPalette.adaptiveTextPrimary(for: colorScheme) }
    private var secondaryText: Color { BrandPalette.adaptiveTextSecondary(for: colorScheme) }

    var body: some View {
        NavigationStack {
            ZStack {
                EliteBackground()
                ScrollView {
                VStack(spacing: 12) {
                    profileHeroCard
                    if appState.shouldShowProfileQuoteBubble {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "bubble.left.fill")
                                .foregroundStyle(BrandPalette.neonBlue)
                            Text(appState.currentUser.profileQuote)
                                .font(.subheadline)
                                .foregroundStyle(primaryText)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.92))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(BrandPalette.adaptiveGlassStroke(for: colorScheme), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                    VStack(spacing: 8) {
                        Toggle("Show profile quote bubble", isOn: Binding(
                            get: { appState.currentUser.isProfileQuoteVisible },
                            set: { appState.setProfileQuoteVisibility($0) }
                        ))
                        .foregroundStyle(primaryText)
                        .padding(.horizontal)
                        Button(showQuoteEditor ? "Save quote" : "Edit quote bubble") {
                            if showQuoteEditor {
                                appState.setProfileQuote(quoteDraft)
                            }
                            showQuoteEditor.toggle()
                        }
                        .buttonStyle(.bordered)
                        Button("Delete quote", role: .destructive) {
                            quoteDraft = ""
                            appState.setProfileQuote("")
                            appState.setProfileQuoteVisibility(false)
                        }
                        .buttonStyle(.bordered)
                        if showQuoteEditor {
                            TextField("Write your quote (if empty, bubble is hidden)", text: $quoteDraft, axis: .vertical)
                                .lineLimit(2...5)
                                .textFieldStyle(EliteTextFieldStyle())
                                .padding(.horizontal)
                        }
                    }
                    if !conversionStatusMessage.isEmpty {
                        Text(conversionStatusMessage)
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                    if appState.canUndoPostDeletion {
                        HStack(spacing: 8) {
                            Label("Post deleted", systemImage: "trash")
                                .font(.caption)
                                .foregroundStyle(secondaryText)
                            Spacer()
                            Button("Undo") {
                                _ = appState.undoLastDeletedPost()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.horizontal)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(tabs, id: \.self) { tab in
                                Button(tab) {
                                    withAnimation(MotionTokens.spring) {
                                        selectedTab = tab
                                    }
                                }
                                .buttonStyle(.plain)
                                .font(.caption.bold())
                                .padding(.horizontal, 11)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(selectedTab == tab ? BrandPalette.neonBlue.opacity(0.28) : BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.86))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(BrandPalette.adaptiveGlassStroke(for: colorScheme).opacity(selectedTab == tab ? 0.8 : 0.5), lineWidth: 1)
                                )
                                .foregroundStyle(primaryText)
                            }
                        }
                        .padding(.horizontal)
                    }

                    HStack {
                        Spacer()
                        statChip(title: "Posts", value: "\(appState.posts.count)")
                        Spacer()
                    }
                    .padding(.top, 6)

                    HStack(spacing: 8) {
                        quickActionButton("Edit profile", system: "square.and.pencil") {
                            showIdentityEditor = true
                            showQuoteEditor = true
                        }
                        quickActionButton("Share profile", system: "square.and.arrow.up") {
                            conversionStatusMessage = "Profile share card prepared. Use your native share flow from this screen."
                        }
                        quickActionButton("Dashboard", system: "chart.xyaxis.line") {
                            showInsights = true
                        }
                    }
                    .padding(.horizontal)

                    storyBubbleSections

                    EliteSectionCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Profile Modes")
                                    .font(.headline)
                                    .foregroundStyle(primaryText)
                                Spacer()
                                Text(appState.mode == .social ? "Social Active" : "Corporate Active")
                                    .font(.caption2.bold())
                                    .foregroundStyle(BrandPalette.neonGreen)
                            }
                            HStack(spacing: 8) {
                                Button("Social") {
                                    appState.setMode(.social)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(!appState.hasSocialProfile)
                                Button("Corporate") {
                                    appState.setMode(.enterprise)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(!appState.hasCorporateProfile)
                            }
                            Text("Social: \(appState.profileAvailabilityLabel(.social)) • Corporate: \(appState.profileAvailabilityLabel(.enterprise))")
                                .font(.caption2)
                                .foregroundStyle(secondaryText)
                        }
                    }
                    .padding(.horizontal)

                    EliteSectionCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Identity")
                                    .font(.headline)
                                    .foregroundStyle(primaryText)
                                Spacer()
                                Button(showIdentityEditor ? "Save" : "Edit") {
                                    if showIdentityEditor {
                                        appState.updateCurrentIdentity(
                                            enterpriseAlias: aliasDraft,
                                            displayName: displayNameDraft
                                        )
                                    }
                                    showIdentityEditor.toggle()
                                }
                                .buttonStyle(.bordered)
                            }
                            if showIdentityEditor {
                                TextField("Corporate alias", text: $aliasDraft)
                                    .textFieldStyle(EliteTextFieldStyle())
                                TextField("Display name", text: $displayNameDraft)
                                    .textFieldStyle(EliteTextFieldStyle())
                                TextField("Profile link (https://...)", text: $profileLinkDraft)
                                    .textFieldStyle(EliteTextFieldStyle())
                                HStack(spacing: 8) {
                                    Button("Save profile link") {
                                        appState.setProfileLink(profileLinkDraft)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    Button("Delete link", role: .destructive) {
                                        profileLinkDraft = ""
                                        appState.setProfileLink("")
                                    }
                                    .buttonStyle(.bordered)
                                }
                            } else {
                                Text("Alias: \(appState.currentUser.enterpriseAlias)")
                                    .font(.caption)
                                    .foregroundStyle(secondaryText)
                                Text("Display: \(appState.currentUser.displayName)")
                                    .font(.caption)
                                    .foregroundStyle(secondaryText)
                                if !appState.currentUser.profileLinkURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                                   let url = URL(string: appState.currentUser.profileLinkURL) {
                                    Link(destination: url) {
                                        Label(appState.currentUser.profileLinkURL, systemImage: "link")
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    NavigationLink(destination: ConnectionsView().environmentObject(appState)) {
                        Label("Followers, following, suggested, contacts", systemImage: "person.2.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)

                    if appState.mode == .enterprise {
                        NavigationLink(destination: CorporateHubView().environmentObject(appState)) {
                            Label("Corporate Hub: Network, Resume, Jobs, AI", systemImage: "building.2.crop.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal)
                    }

                    TabView(selection: $selectedTab) {
                        postsGrid(Array(chitPosts.prefix(9))).tag("Chit")
                        postsGrid(chatPosts).tag("Chat")
                        postsGrid(repostPosts).tag("Reposts")
                        listContainer {
                            combinedPostSection
                        }.tag("Combined")
                        postsGrid(reelPosts).tag("Reels")
                        postsGrid(taggedPosts).tag("Tagged")
                    }
                    .frame(height: 420)
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    if selectedTab == "Tagged", !appState.hiddenTaggedPostIDs.isEmpty {
                        HStack {
                            Text("\(appState.hiddenTaggedPostIDs.count) tagged posts hidden")
                                .font(.caption2)
                                .foregroundStyle(secondaryText)
                            Spacer()
                            Button("Restore all") {
                                appState.unhideAllTaggedPosts()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.horizontal)
                    }

                    Toggle(
                        "Allow enterprise side to reveal social @username",
                        isOn: Binding(
                            get: { appState.currentUser.allowEnterpriseReveal },
                            set: { appState.setEnterpriseReveal($0) }
                        )
                    )
                    .padding(.horizontal)
                    .foregroundStyle(primaryText)

                    Toggle("Hide likes count by default on new posts", isOn: $appState.hideLikeCountsByDefault)
                        .padding(.horizontal)
                        .foregroundStyle(primaryText)

                    Toggle("Hide comments count by default on new posts", isOn: $appState.hideCommentCountsByDefault)
                        .padding(.horizontal)
                        .foregroundStyle(primaryText)

                    EliteSectionCard {
                        DisclosureGroup("Account Tools", isExpanded: $showAccountTools) {
                            VStack(spacing: 8) {
                                NavigationLink(destination: VerificationView().environmentObject(appState)) {
                                    Label("Verification request", systemImage: "checkmark.seal")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                NavigationLink(destination: LaunchSettingsView().environmentObject(appState)) {
                                    Label("Launch settings center", systemImage: "gearshape.2.fill")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                NavigationLink(destination: SafetySettingsView().environmentObject(appState)) {
                                    Label("Safety settings", systemImage: "checkmark.shield.fill")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                NavigationLink(destination: NotificationSettingsView().environmentObject(appState)) {
                                    Label("Notification settings", systemImage: "bell.badge.fill")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                NavigationLink(destination: PrivacyControlView().environmentObject(appState)) {
                                    Label("Privacy controls", systemImage: "hand.raised.fill")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                NavigationLink(destination: SocialLinksView().environmentObject(appState)) {
                                    Label("Connected platforms", systemImage: "link")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                if appState.canAccessInternalDashboard {
                                    NavigationLink(destination: AdminDashboardView().environmentObject(appState)) {
                                        Label("Internal verification dashboard", systemImage: "person.badge.shield.checkmark")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                        .tint(.white)
                        .foregroundStyle(primaryText)
                    }
                    .padding(.horizontal)

                    EliteSectionCard {
                        DisclosureGroup("Creator & Business Tools", isExpanded: $showCreatorTools) {
                            VStack(spacing: 8) {
                                NavigationLink(destination: ResumeEnterpriseView().environmentObject(appState)) {
                                    Label("Resume & enterprise profile", systemImage: "doc.text.fill")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                NavigationLink(destination: CommunitiesHubView().environmentObject(appState)) {
                                    Label("Groups & communities", systemImage: "person.3.fill")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                NavigationLink(destination: ShopHubView().environmentObject(appState)) {
                                    Label("Shop & live selling", systemImage: "bag.fill")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                NavigationLink(destination: PulseBoardView().environmentObject(appState)) {
                                    Label("Pulse public feed", systemImage: "bolt.bubble.fill")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                NavigationLink(destination: MusicHubView().environmentObject(appState)) {
                                    Label("Music hub", systemImage: "music.note")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .tint(.white)
                        .foregroundStyle(primaryText)
                    }
                    .padding(.horizontal)

                    if appState.emailVerificationSent {
                        Text("Verification email sent. Update emails: \(appState.wantsProductUpdateEmails ? "On" : "Off")")
                            .font(.footnote)
                            .foregroundStyle(secondaryText)
                            .padding(.horizontal)
                    }

                    Button("Log out") {
                        appState.endSession()
                    }
                    .buttonStyle(.bordered)
                    .padding(.bottom)
                }
                .padding(.top, 4)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(displayHandle)
                        .font(.headline.bold())
                        .foregroundStyle(primaryText)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            appState.setProfilePhoto(data: data)
                        }
                    }
                }
            }
            .onChange(of: selectedStoryPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            appState.setProfileStoryImage(data: data)
                            showAvatarStory = true
                        }
                    }
                }
            }
            .onChange(of: selectedStoryVideoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let sourceData = try? await newItem.loadTransferable(type: Data.self) {
                        do {
                            let trimmedVideo = try await MediaConversionService.createFiveSecondLoopVideo(from: sourceData)
                            await MainActor.run {
                                appState.setProfileStoryVideo(data: trimmedVideo)
                                showAvatarStory = true
                            }
                        } catch {
                            await MainActor.run {
                                conversionStatusMessage = "Story video conversion failed."
                            }
                        }
                    }
                }
            }
            .onChange(of: avatarVideoSourceItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    await MainActor.run {
                        isConvertingAvatarVideo = true
                        conversionStatusMessage = "Converting video to GIF and 5s loop..."
                    }
                    defer {
                        Task { @MainActor in
                            isConvertingAvatarVideo = false
                        }
                    }
                    guard let sourceData = try? await newItem.loadTransferable(type: Data.self) else { return }
                    do {
                        async let gifTask = MediaConversionService.createGIF(from: sourceData, maxDuration: 5.0, fps: 10)
                        async let loopTask = MediaConversionService.createFiveSecondLoopVideo(from: sourceData)
                        let (gifData, loopVideoData) = try await (gifTask, loopTask)
                        await MainActor.run {
                            appState.setProfileGIF(data: gifData)
                            appState.setProfileLoopVideo(data: loopVideoData)
                            appState.setProfileStoryGIF(data: gifData)
                            appState.setProfileStoryVideo(data: loopVideoData)
                            conversionStatusMessage = "Avatar video + GIF ready."
                        }
                    } catch {
                        await MainActor.run {
                            conversionStatusMessage = "Video conversion failed. Try another clip."
                        }
                    }
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .photosPicker(isPresented: $showStoryPhotoPicker, selection: $selectedStoryPhotoItem, matching: .images)
            .photosPicker(isPresented: $showAvatarVideoPicker, selection: $avatarVideoSourceItem, matching: .videos)
            .photosPicker(isPresented: $showStoryVideoPicker, selection: $selectedStoryVideoItem, matching: .videos)
            .alert("Verification badge info", isPresented: $showBadgeInfo) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(badgeInfoMessage)
            }
            .confirmationDialog("Profile Media Options", isPresented: $showMediaOptions, titleVisibility: .visible) {
                Button("Change profile photo") { showPhotoPicker = true }
                Button("Add story photo") { showStoryPhotoPicker = true }
                Button("Add story video (5 sec loop)") { showStoryVideoPicker = true }
                Button("Set profile video + GIF") { showAvatarVideoPicker = true }
                Button("View current story") { showAvatarStory = true }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $selectedPost) { post in
                NavigationStack {
                    ZStack {
                        EliteBackground()
                        ScrollView {
                            VStack(alignment: .leading, spacing: 14) {
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
                    .navigationTitle("Post")
                }
            }
            .sheet(isPresented: $showInsights) {
                NavigationStack {
                    CreatorInsightsView()
                        .environmentObject(appState)
                }
            }
            .sheet(isPresented: $showFollowingSheet) {
                NavigationStack {
                    ConnectionsView(initialTab: 0)
                        .environmentObject(appState)
                }
            }
            .sheet(isPresented: $showFollowersSheet) {
                NavigationStack {
                    ConnectionsView(initialTab: 1)
                        .environmentObject(appState)
                }
            }
            .sheet(isPresented: $showAvatarStory) {
                AvatarStoryView()
                    .environmentObject(appState)
            }
            .confirmationDialog("Create video bubble from old stories", isPresented: $showVideoBubbleDialog, titleVisibility: .visible) {
                Button("Moments section") {
                    conversionStatusMessage = appState.createVideoBubbleFromLatestStory(sectionTitle: "Moments")
                        ? "Video bubble added to Moments."
                        : "No old stories available yet."
                }
                Button("Highlights section") {
                    conversionStatusMessage = appState.createVideoBubbleFromLatestStory(sectionTitle: "Highlights")
                        ? "Video bubble added to Highlights."
                        : "No old stories available yet."
                }
                Button("Behind the scenes") {
                    conversionStatusMessage = appState.createVideoBubbleFromLatestStory(sectionTitle: "Behind the scenes")
                        ? "Video bubble added to Behind the scenes."
                        : "No old stories available yet."
                }
                Button("Cancel", role: .cancel) {}
            }
            .onAppear {
                quoteDraft = appState.currentUser.profileQuote
                aliasDraft = appState.currentUser.enterpriseAlias
                displayNameDraft = appState.currentUser.displayName
                profileLinkDraft = appState.currentUser.profileLinkURL
            }
            .onChange(of: appState.currentUser.username) { _, _ in
                quoteDraft = appState.currentUser.profileQuote
                aliasDraft = appState.currentUser.enterpriseAlias
                displayNameDraft = appState.currentUser.displayName
                profileLinkDraft = appState.currentUser.profileLinkURL
                showQuoteEditor = false
                showIdentityEditor = false
            }
        }
    }

    private var verificationLabel: String {
        switch appState.currentUser.verificationStatus {
        case .verifiedInternal: return "Official Verified"
        case .paid: return "Paid Verification"
        case .pending: return "Verification in progress"
        case .unverified: return "Not verified"
        }
    }

    private var badgeIcon: String {
        switch appState.currentUser.verificationStatus {
        case .verifiedInternal: return "checkmark.seal.fill"
        case .paid: return "dollarsign.seal.fill"
        case .pending, .unverified: return "checkmark.seal"
        }
    }

    private var badgeColor: Color {
        switch appState.currentUser.verificationStatus {
        case .verifiedInternal: return BrandPalette.neonBlue
        case .paid: return .yellow
        case .pending, .unverified: return .gray
        }
    }

    private var badgeInfoMessage: String {
        switch appState.currentUser.verificationStatus {
        case .verifiedInternal:
            return "Official verification is internally approved by your admin team."
        case .paid:
            return "This is a paid verification badge. It is public and marked as paid."
        case .pending:
            return "Verification is pending internal review."
        case .unverified:
            return "No badge yet. You can request paid or official verification."
        }
    }

    private var chitPosts: [PostItem] {
        appState.posts.filter { !$0.isArchived && $0.type == .post && $0.surfaceStyle == .chit }
    }

    private var chatPosts: [PostItem] {
        appState.posts.filter { !$0.isArchived && $0.type == .post && $0.surfaceStyle == .chat }
    }

    private var repostPosts: [PostItem] {
        appState.posts.filter { !$0.isArchived && ($0.caption.hasPrefix("Reposted from") || $0.caption.hasPrefix("Re-shared from") || $0.caption.hasPrefix("Quote repost")) }
    }

    private var reelPosts: [PostItem] {
        appState.posts.filter { !$0.isArchived && ($0.type == .reel || $0.type == .shortVideo) }
    }

    private var taggedPosts: [PostItem] {
        appState.posts.filter { post in
            post.taggedHandles.contains { $0.caseInsensitiveCompare(appState.currentUser.handle) == .orderedSame }
            && !appState.hiddenTaggedPostIDs.contains(post.id)
        }
    }

    @ViewBuilder
    private var combinedPostSection: some View {
        let incoming = appState.myIncomingCombinedPostRequests()
        if incoming.isEmpty {
            Text("No pending combined post requests.")
                .foregroundStyle(secondaryText)
        } else {
            Text("\(incoming.count) request\(incoming.count == 1 ? "" : "s") pending review")
                .font(.caption)
                .foregroundStyle(secondaryText)
            ForEach(incoming) { request in
                VStack(alignment: .leading, spacing: 6) {
                    Text("From \(request.fromHandle)")
                        .font(.caption.bold())
                        .foregroundStyle(BrandPalette.neonBlue)
                    Text(request.caption)
                        .foregroundStyle(primaryText)
                    HStack(spacing: 8) {
                        Button("Approve") {
                            appState.approveCombinedPostRequest(request.id)
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Decline", role: .destructive) {
                            appState.declineCombinedPostRequest(request.id)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private var storyBubbleSections: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                storyBubble(title: "Stories", system: "plus.circle.fill", tint: BrandPalette.neonBlue) {
                    showAvatarStory = true
                }
                storyBubble(title: "Highlights", system: "play.circle.fill", tint: BrandPalette.neonGreen) {
                    selectedTab = "Reels"
                }
                storyBubble(title: "Old Stories", system: "clock.arrow.circlepath", tint: BrandPalette.accentPurple) {
                    showVideoBubbleDialog = true
                }
                storyBubble(title: "Tagged", system: "at", tint: BrandPalette.accentPink) {
                    selectedTab = "Tagged"
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var profileHeroCard: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 10) {
                VStack(spacing: 8) {
                    profileAvatar
                    Text(identityTitle)
                        .font(.title3.bold())
                    Text(identitySubtitle)
                        .font(.caption)
                        .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                    Button {
                        showBadgeInfo = true
                    } label: {
                        Label(verificationLabel, systemImage: badgeIcon)
                            .font(.subheadline)
                            .foregroundStyle(badgeColor)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                HStack(alignment: .center) {
                    Button {
                        showFollowingSheet = true
                    } label: {
                        statChip(title: "Following", value: "\(appState.followingCount)")
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    quickActionButton("Story", system: "circle.dotted") {
                        showAvatarStory = true
                    }
                    Spacer()
                    Button {
                        showFollowersSheet = true
                    } label: {
                        statChip(title: "Followers", value: "\(appState.followersCount)")
                    }
                    .buttonStyle(.plain)
                }
                HStack {
                    Label("Momentum \(appState.creatorMomentumScore())", systemImage: "flame.fill")
                        .font(.caption.bold())
                        .foregroundStyle(BrandPalette.neonGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(BrandPalette.neonGreen.opacity(0.14))
                        .clipShape(Capsule())
                    Spacer()
                }
                Text("Building the elite social + corporate network. Posts, reels, partnerships, and growth.")
                    .font(.subheadline)
                    .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                HStack(spacing: 8) {
                    quickActionButton("Edit", system: "square.and.pencil") {
                        showIdentityEditor = true
                        showQuoteEditor = true
                    }
                    quickActionButton("Share", system: "square.and.arrow.up") {
                        conversionStatusMessage = "Profile share card prepared. Use your native share flow from this screen."
                    }
                    quickActionButton("Insights", system: "chart.line.uptrend.xyaxis") {
                        showInsights = true
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func statChip(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundStyle(primaryText)
            Text(title)
                .font(.caption)
                .foregroundStyle(secondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.9))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(BrandPalette.adaptiveGlassStroke(for: colorScheme), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func quickActionButton(_ title: String, system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: system)
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(BrandPalette.adaptiveGlassStroke(for: colorScheme), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(primaryText)
        }
        .buttonStyle(SnappyScaleButtonStyle())
    }

    @ViewBuilder
    private func storyBubble(title: String, system: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Circle()
                    .fill(tint.opacity(0.22))
                    .frame(width: 58, height: 58)
                    .overlay(
                        Image(systemName: system)
                            .font(.headline)
                            .foregroundStyle(.white)
                    )
                    .overlay(Circle().stroke(tint.opacity(0.7), lineWidth: 1.5))
                Text(title)
                    .font(.caption2.bold())
                    .foregroundStyle(primaryText.opacity(0.9))
            }
            .frame(width: 76)
        }
        .buttonStyle(SnappyScaleButtonStyle())
    }

    private var displayHandle: String {
        if appState.mode == .enterprise && !appState.currentUser.allowEnterpriseReveal {
            return appState.currentUser.enterpriseAlias
        }
        return appState.currentUser.handle
    }

    private var identityTitle: String {
        if appState.mode == .enterprise {
            return appState.currentUser.enterpriseAlias
        }
        return appState.currentUser.handle
    }

    private var identitySubtitle: String {
        if appState.mode == .enterprise {
            return appState.currentUser.displayName
        }
        return "Social profile"
    }

    @ViewBuilder
    private var profileAvatar: some View {
        Button {
            showAvatarStory = true
        } label: {
            avatarVisual
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(isConvertingAvatarVideo ? .orange : BrandPalette.neonGreen)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(.black.opacity(0.65), lineWidth: 1))
        }
        .contextMenu {
            Button("Media options") { showMediaOptions = true }
            Divider()
            if !appState.loggedInAccounts.isEmpty {
                ForEach(appState.loggedInAccounts) { account in
                    Button("Switch to \(account.handle)") {
                        _ = appState.switchToAccount(username: account.username)
                    }
                }
            }
            Divider()
            Button("Switch to Corporate View") {
                appState.setMode(.enterprise)
            }
            Button("Switch to Social View") {
                appState.setMode(.social)
            }
        }
    }

    @ViewBuilder
    private var avatarVisual: some View {
        if let loopVideo = appState.profileLoopVideoData, !loopVideo.isEmpty {
            LoopingAvatarView(videoData: loopVideo)
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .overlay(Circle().stroke(BrandPalette.neonBlue.opacity(0.7), lineWidth: 2))
        } else if let gifData = appState.profileGIFData, let image = UIImage(data: gifData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .overlay(Circle().stroke(BrandPalette.neonBlue.opacity(0.7), lineWidth: 2))
        } else if let data = appState.profilePhotoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .overlay(Circle().stroke(BrandPalette.neonBlue.opacity(0.6), lineWidth: 2))
        } else {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(BrandPalette.neonBlue)
        }
    }

    @ViewBuilder
    private func listContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BrandPalette.cardBg.opacity(0.75))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(BrandPalette.glassStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }

    @ViewBuilder
    private func postsGrid(_ posts: [PostItem]) -> some View {
        let columns = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(posts) { post in
                Button {
                    selectedPost = post
                } label: {
                    ZStack(alignment: .bottomLeading) {
                        if let data = post.imageData, let image = UIImage(data: data) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 118)
                                .frame(maxWidth: .infinity)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(BrandPalette.cardBg)
                                .frame(height: 118)
                                .overlay(
                                    Image(systemName: post.type == .reel || post.type == .shortVideo ? "play.fill" : "photo")
                                        .font(.title3)
                                        .foregroundStyle(.white.opacity(0.85))
                                )
                        }
                        LinearGradient(
                            colors: [.black.opacity(0.0), .black.opacity(0.45)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 40)
                        Text(post.caption)
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundStyle(.white)
                            .padding(4)
                    }
                }
                .buttonStyle(.plain)
                .contextMenu {
                    if post.authorHandle.caseInsensitiveCompare(appState.currentUser.handle) == .orderedSame {
                        Button(role: .destructive) {
                            appState.deletePostWithUndo(post.id)
                        } label: {
                            Label("Delete post", systemImage: "trash")
                        }
                    }
                    if post.taggedHandles.contains(where: { $0.caseInsensitiveCompare(appState.currentUser.handle) == .orderedSame }) {
                        Button(role: .destructive) {
                            appState.hideTaggedPost(post.id)
                        } label: {
                            Label("Hide from tagged", systemImage: "eye.slash")
                        }
                    }
                    Button {
                        selectedPost = post
                    } label: {
                        Label("Open post", systemImage: "eye")
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

private struct AvatarStoryView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                if let videoData = appState.profileStoryVideoData {
                    LoopingAvatarView(videoData: videoData)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .frame(maxWidth: .infinity, maxHeight: 520)
                } else if let gifData = appState.profileStoryGIFData, let image = UIImage(data: gifData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else if let imageData = appState.profileStoryImageData, let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else if let imageData = appState.profilePhotoData, let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: 58))
                            .foregroundStyle(.white.opacity(0.82))
                        Text("No story yet. Hold your avatar to add one.")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            .padding()
            .overlay(alignment: .topTrailing) {
                Button("Close") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
        }
    }
}

private struct LoopingAvatarView: View {
    let videoData: Data
    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                configurePlayerIfNeeded()
            }
            .onDisappear {
                player?.pause()
                player = nil
                looper = nil
            }
    }

    private func configurePlayerIfNeeded() {
        guard player == nil else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        do {
            try videoData.write(to: url, options: [.atomic])
            let item = AVPlayerItem(url: url)
            let queue = AVQueuePlayer()
            queue.isMuted = true
            looper = AVPlayerLooper(player: queue, templateItem: item)
            player = queue
            queue.play()
        } catch {
            player = nil
            looper = nil
        }
    }
}
