//
//  ProfilePostsView.swift
//  Chit Chat Social
//

import SwiftUI

/// Isolated posts browser — kept out of the main Profile scroll to avoid review-time crashes.
struct ProfilePostsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = "Chit"
    @State private var selectedPost: PostItem?

    private let tabs = ["Chit", "Chat", "Reposts", "Combined", "Reels", "Tagged"]
    private var primaryText: Color { BrandPalette.adaptiveTextPrimary(for: colorScheme) }
    private var secondaryText: Color { BrandPalette.adaptiveTextSecondary(for: colorScheme) }

    var body: some View {
        ZStack {
            EliteBackground()
            ScrollView {
                VStack(spacing: 12) {
                    Picker("Section", selection: $selectedTab) {
                        ForEach(tabs, id: \.self) { tab in
                            Text(tab).tag(tab)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)

                    postsContent
                        .padding(.bottom, 24)
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle("My posts")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedPost) { post in
            NavigationStack {
                ZStack {
                    EliteBackground()
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            if let data = post.imageData, let image = ProfileImageSupport.uiImage(from: data) {
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
    }

    @ViewBuilder
    private var postsContent: some View {
        switch selectedTab {
        case "Chit":
            postsGrid(Array(chitPosts.prefix(12)))
        case "Chat":
            postsGrid(Array(chatPosts.prefix(12)))
        case "Reposts":
            postsGrid(Array(repostPosts.prefix(12)))
        case "Combined":
            combinedSection
        case "Reels":
            postsGrid(Array(reelPosts.prefix(12)))
        case "Tagged":
            postsGrid(Array(taggedPosts.prefix(12)))
        default:
            postsGrid(Array(chitPosts.prefix(12)))
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
    private var combinedSection: some View {
        let incoming = appState.myIncomingCombinedPostRequests()
        VStack(alignment: .leading, spacing: 8) {
            if incoming.isEmpty {
                Text("No pending combined post requests.")
                    .foregroundStyle(secondaryText)
            } else {
                ForEach(incoming) { request in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("From \(request.fromHandle)")
                            .font(.caption.bold())
                        Text(request.caption)
                        HStack {
                            Button("Approve") { appState.approveCombinedPostRequest(request.id) }
                            Button("Decline", role: .destructive) { appState.declineCombinedPostRequest(request.id) }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func postsGrid(_ posts: [PostItem]) -> some View {
        if posts.isEmpty {
            Text("No posts in this section yet.")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        } else {
            let columns = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(posts) { post in
                    Button {
                        selectedPost = post
                    } label: {
                        postCell(post)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func postCell(_ post: PostItem) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let data = post.imageData, let image = ProfileImageSupport.uiImage(from: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 110)
                    .frame(maxWidth: .infinity)
                    .clipped()
            } else {
                Rectangle()
                    .fill(BrandPalette.cardBg)
                    .frame(height: 110)
                    .overlay(
                        Image(systemName: post.type == .reel || post.type == .shortVideo ? "play.fill" : "photo")
                            .foregroundStyle(.white.opacity(0.85))
                    )
            }
            Text(post.caption)
                .font(.caption2)
                .lineLimit(1)
                .foregroundStyle(.white)
                .padding(4)
        }
    }
}

enum ProfileImageSupport {
    static func uiImage(from data: Data) -> UIImage? {
        guard !data.isEmpty, data.count < 12_000_000 else { return nil }
        return UIImage(data: data)
    }
}
