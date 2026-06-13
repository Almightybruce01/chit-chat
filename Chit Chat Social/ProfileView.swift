//
//  ProfileView.swift
//  Chit Chat Social
//
//  Created by Brian Bruce on 2025-06-24.
//

import SwiftUI
import PhotosUI
import AVKit

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.storeKit) private var storeKit
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openURL) private var openURL
    @State private var profileContentReady = false
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
    @State private var profileQuoteModerationMessage = ""
    @State private var aliasDraft = ""
    @State private var displayNameDraft = ""
    @State private var showIdentityEditor = false
    @State private var profileLinkDraft = ""
    @State private var showVideoBubbleDialog = false
    @State private var showContactInfoSheet = false
    @State private var contactEmailDraft = ""
    @State private var contactPhoneDraft = ""
    @State private var contactInfoMessage = ""
    private let tabs = ["Chit", "Chat", "Reposts", "Combined", "Reels", "Tagged"]
    private var primaryText: Color { BrandPalette.adaptiveTextPrimary(for: colorScheme) }
    private var secondaryText: Color { BrandPalette.adaptiveTextSecondary(for: colorScheme) }

    var body: some View {
        NavigationStack {
            ZStack {
                EliteBackground()
                ScrollView {
                    Group {
                        if profileContentReady {
                            profileMainColumn
                        } else {
                            ProgressView("Loading profile…")
                                .padding(.top, 80)
                                .frame(maxWidth: .infinity)
                        }
                    }
                        .padding(.top, 4)
                        .frame(maxWidth: LayoutTokens.readableMaxWidth)
                        .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.visible)
                .contentMargins(.bottom, 28, for: .scrollContent)
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
            .sheet(isPresented: $showContactInfoSheet) {
                NavigationStack {
                    Form {
                        Section {
                            Text("Use a real email and mobile number so you can recover your password and receive account notices.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Section("Your details") {
                            TextField("Email", text: $contactEmailDraft)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                            TextField("Phone (optional)", text: $contactPhoneDraft)
                                .keyboardType(.phonePad)
                        }
                        if !contactInfoMessage.isEmpty {
                            Section {
                                Text(contactInfoMessage)
                                    .font(.caption)
                                    .foregroundStyle(contactInfoMessage == "Saved." ? .green : .orange)
                            }
                        }
                    }
                    .navigationTitle("Contact info")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showContactInfoSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                contactInfoMessage = ""
                                if let err = appState.updateAccountContactInfo(email: contactEmailDraft, phone: contactPhoneDraft) {
                                    contactInfoMessage = err
                                } else {
                                    contactInfoMessage = "Saved."
                                }
                            }
                        }
                    }
                }
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
                if !profileContentReady {
                    profileContentReady = true
                }
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
            return "Paid verification badge — purchased via App Store In-App Purchase. Separate from free official verification."
        case .pending:
            return "Verification is pending internal review."
        case .unverified:
            return "No badge yet. You can request paid or official verification."
        }
    }

    @ViewBuilder
    private var selectedProfilePostsContent: some View {
        // Single static container — avoids paged TabView inside ScrollView (iPad crash during review).
        switch selectedTab {
        case "Chit":
            postsGrid(Array(chitPosts.prefix(9)))
        case "Chat":
            postsGrid(chatPosts)
        case "Reposts":
            postsGrid(repostPosts)
        case "Combined":
            listContainer {
                combinedPostSection
            }
        case "Reels":
            postsGrid(reelPosts)
        case "Tagged":
            postsGrid(taggedPosts)
        default:
            postsGrid(Array(chitPosts.prefix(9)))
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

    /// Split out main column to keep `body` type-checking fast.
    @ViewBuilder
    private var profileMainColumn: some View {
            LazyVStack(spacing: 12) {
                profileHeroCard

                if appState.session?.isAuthenticated == true && appState.needsContactInfoUpdate {
                    Button {
                        contactEmailDraft = appState.currentUser.accountEmail
                        contactPhoneDraft = appState.currentUser.accountPhone
                        contactInfoMessage = ""
                        showContactInfoSheet = true
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Update your email and phone")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(primaryText)
                                Text(
                                    "Sign in with Apple/Google may have started with placeholders. Add real contact info for account recovery and notifications."
                                )
                                .font(.caption)
                                .foregroundStyle(secondaryText)
                                .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(secondaryText)
                        }
                        .padding(12)
                        .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.45), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
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
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
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

                NavigationLink {
                    ProfilePostsView()
                        .environmentObject(appState)
                } label: {
                    Label("My posts (\(appState.posts.count))", systemImage: "square.grid.3x3.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

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

                storyBubbleSections

                NavigationLink {
                    ProfileToolsHubView()
                        .environmentObject(appState)
                } label: {
                    Label("Settings & account tools", systemImage: "gearshape.2.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)

                NavigationLink {
                    VerificationView()
                        .environmentObject(appState)
                } label: {
                    Label("Verification & paid badge (IAP)", systemImage: "checkmark.seal")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                if appState.currentUser.isBusinessAccount {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(BrandPalette.neonGreen)
                        Text("Business verified — job posts require approval before going live.")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }
                    .padding(.horizontal)
                }

                if appState.emailVerificationSent {
                    Text("Verification email sent. Update emails: \(appState.wantsProductUpdateEmails ? "On" : "Off")")
                        .font(.footnote)
                        .foregroundStyle(secondaryText)
                        .padding(.horizontal)
                }

                Button("Log out") {
                    appState.endSession()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red.opacity(0.85))
                .padding(.bottom, 24)

                Color.clear
                    .frame(height: 120)
                    .accessibilityHidden(true)
            }
    }

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

    @ViewBuilder
    private var profileTabSelector: some View {
        if horizontalSizeClass == .regular {
            Picker("Posts section", selection: $selectedTab) {
                ForEach(tabs, id: \.self) { tab in
                    Text(tab).tag(tab)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)
        } else {
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
        }
    }

    private func safeUIImage(from data: Data) -> UIImage? {
        guard !data.isEmpty else { return nil }
        return UIImage(data: data)
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
                .overlay(alignment: .bottom) {
                    if appState.isHandleLive(appState.currentUser.handle) {
                        LiveStoryBadge()
                            .scaleEffect(0.9)
                            .offset(y: 12)
                    }
                }
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
        if let gifData = appState.profileGIFData, let image = ProfileImageSupport.uiImage(from: gifData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .overlay(Circle().stroke(BrandPalette.neonBlue.opacity(0.7), lineWidth: 2))
        } else if let data = appState.profilePhotoData, let image = ProfileImageSupport.uiImage(from: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .overlay(Circle().stroke(BrandPalette.neonBlue.opacity(0.6), lineWidth: 2))
        } else if let loopVideo = appState.profileLoopVideoData, !loopVideo.isEmpty {
            ZStack {
                Circle()
                    .fill(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.9))
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(BrandPalette.neonBlue)
            }
            .frame(width: 56, height: 56)
            .overlay(Circle().stroke(BrandPalette.neonBlue.opacity(0.7), lineWidth: 2))
            .accessibilityLabel("Profile video — open story to play")
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
        let capped = Array(posts.prefix(15))
        let columns = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(capped) { post in
                Button {
                    selectedPost = post
                } label: {
                    ZStack(alignment: .bottomLeading) {
                        if let data = post.imageData, let image = safeUIImage(from: data) {
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
                if let videoData = appState.profileStoryVideoData, !videoData.isEmpty {
                    SafeLoopingVideoView(videoData: videoData)
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

private struct SafeLoopingVideoView: View {
    let videoData: Data
    @State private var isPlayable = false
    @State private var loadFailed = false

    var body: some View {
        Group {
            if isPlayable {
                SafeLoopingVideoPlayerRepresentable(videoData: videoData)
            } else if loadFailed {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text("Could not play this video.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .task(id: videoData.count) {
            await validateVideo()
        }
    }

    private func validateVideo() async {
        loadFailed = false
        isPlayable = false
        guard !videoData.isEmpty else {
            loadFailed = true
            return
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("story-preview-\(UUID().uuidString).mp4")
        do {
            try videoData.write(to: url, options: [.atomic])
            let asset = AVURLAsset(url: url)
            let tracks = try await asset.load(.tracks)
            let hasVideo = tracks.contains { $0.mediaType == .video }
            await MainActor.run {
                isPlayable = hasVideo
                loadFailed = !hasVideo
            }
        } catch {
            await MainActor.run {
                loadFailed = true
            }
        }
    }
}

private struct SafeLoopingVideoPlayerRepresentable: UIViewRepresentable {
    let videoData: Data

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SafeLoopingPlayerUIView {
        let view = SafeLoopingPlayerUIView()
        context.coordinator.attach(to: view, videoData: videoData)
        return view
    }

    func updateUIView(_ uiView: SafeLoopingPlayerUIView, context: Context) {}

    static func dismantleUIView(_ uiView: SafeLoopingPlayerUIView, coordinator: Coordinator) {
        coordinator.teardown()
    }

    final class Coordinator {
        private weak var host: SafeLoopingPlayerUIView?

        func attach(to view: SafeLoopingPlayerUIView, videoData: Data) {
            host = view
            view.configure(with: videoData)
        }

        func teardown() {
            host?.teardown()
            host = nil
        }
    }
}

private final class SafeLoopingPlayerUIView: UIView {
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var tempFileURL: URL?

    override static var layerClass: AnyClass { AVPlayerLayer.self }

    private var playerLayer: AVPlayerLayer? {
        layer as? AVPlayerLayer
    }

    func configure(with data: Data) {
        guard player == nil, !data.isEmpty else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("story-loop-\(UUID().uuidString).mp4")
        do {
            try data.write(to: url, options: [.atomic])
            tempFileURL = url
            let item = AVPlayerItem(url: url)
            let queue = AVQueuePlayer()
            queue.isMuted = true
            queue.automaticallyWaitsToMinimizeStalling = true
            looper = AVPlayerLooper(player: queue, templateItem: item)
            player = queue
            playerLayer?.player = queue
            playerLayer?.videoGravity = .resizeAspectFill
            queue.play()
        } catch {
            teardown()
        }
    }

    func teardown() {
        player?.pause()
        playerLayer?.player = nil
        player = nil
        looper = nil
        if let tempFileURL {
            try? FileManager.default.removeItem(at: tempFileURL)
        }
        tempFileURL = nil
    }

    deinit {
        if Thread.isMainThread {
            teardown()
        }
    }
}
