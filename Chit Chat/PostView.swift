//
//  PostView.swift
//  Chit Chat
//
//  Created by Brian Bruce on 2025-06-24.
//

import SwiftUI
import PhotosUI
import AVFoundation
import UniformTypeIdentifiers

struct PostView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("blockNudityContent") private var blockNudityContent = true

    private enum CreateStep: Int, CaseIterable {
        case media
        case settings
        case review

        var title: String {
            switch self {
            case .media: return "Media"
            case .settings: return "Settings"
            case .review: return "Review"
            }
        }
    }

    @State private var isCollabEnabled = true
    @State private var caption = ""
    @State private var selectedType: ContentType = .post
    @State private var publishStatus = ""
    @State private var contractTitle = ""
    @State private var contractBudget = ""
    @State private var contractLocation = ""
    @State private var isLocalHire = true
    @State private var selectedMediaItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var selectedVideoData: Data?
    @State private var selectedMediaName = ""
    @State private var isLoadingMedia = false
    @State private var uploadProgress: Double = 0
    @State private var isUploading = false
    @State private var hideLikesForPost = false
    @State private var hideCommentsForPost = false
    @State private var storyAudience: StoryAudience = .public
    @State private var postAudience: PostAudience = .public
    @State private var showMoreOptions = false
    @State private var surfaceStyle: PostSurfaceStyle = .chit
    @State private var currentStep: CreateStep = .media
    @State private var tagHandlesInput = ""
    @State private var combinedTargetHandle = ""
    @State private var requestCombinedPosting = false

    private var primaryText: Color { BrandPalette.adaptiveTextPrimary(for: colorScheme) }
    private var secondaryText: Color { BrandPalette.adaptiveTextSecondary(for: colorScheme) }
    private var hasMediaSelected: Bool { selectedPhotoData != nil || selectedVideoData != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                EliteBackground()
                if appState.mode == .social {
                    ScrollView {
                        VStack(spacing: 14) {
                            FuturisticSectionHeader(
                                title: "New post",
                                subtitle: "Multi-step publishing with media, audience, and upload progress."
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)

                            stepRail

                            Picker("Post Surface", selection: $surfaceStyle) {
                                Text("Chit").tag(PostSurfaceStyle.chit)
                                Text("Chat").tag(PostSurfaceStyle.chat)
                            }
                            .pickerStyle(.segmented)

                            if currentStep == .media {
                                mediaStepCard
                            } else if currentStep == .settings {
                                settingsStepCard
                            } else {
                                reviewStepCard
                            }

                            EliteSectionCard {
                                DisclosureGroup("More options", isExpanded: $showMoreOptions) {
                                    VStack(spacing: 10) {
                                        Picker("Post visibility", selection: $postAudience) {
                                            ForEach(PostAudience.allCases, id: \.self) { audience in
                                                Text(audience.rawValue).tag(audience)
                                            }
                                        }
                                        if selectedType == .story {
                                            Picker("Story audience", selection: $storyAudience) {
                                                ForEach(StoryAudience.allCases, id: \.self) { audience in
                                                    Text(audience.rawValue).tag(audience)
                                                }
                                            }
                                        }
                                        Toggle("Hide likes on this post", isOn: $hideLikesForPost)
                                            .foregroundStyle(primaryText)
                                        Toggle("Hide comments on this post", isOn: $hideCommentsForPost)
                                            .foregroundStyle(primaryText)
                                        Toggle("Block nudity", isOn: $blockNudityContent)
                                            .foregroundStyle(primaryText)
                                    }
                                }
                                .tint(primaryText)
                                .foregroundStyle(primaryText)
                            }

                            if isUploading {
                                EliteSectionCard {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Uploading...")
                                                .foregroundStyle(.white)
                                            Spacer()
                                            Text("\(Int(uploadProgress * 100))%")
                                                .foregroundStyle(.white.opacity(0.8))
                                                .font(.caption)
                                        }
                                        ProgressView(value: uploadProgress)
                                            .tint(BrandPalette.neonBlue)
                                    }
                                }
                            }

                            if !publishStatus.isEmpty {
                                EliteSectionCard {
                                    Text(publishStatus)
                                        .foregroundStyle(.white.opacity(0.88))
                                }
                            }

                            HStack(spacing: 10) {
                                Button("Reset") {
                                    resetDraft()
                                }
                                .buttonStyle(.bordered)
                                .disabled(isUploading)

                                Button {
                                    previousStep()
                                } label: {
                                    Text("Back")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .disabled(currentStep == .media || isUploading)

                                if currentStep != .review {
                                    Button {
                                        nextStep()
                                    } label: {
                                        Text("Next")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.borderedProminent)
                                } else {
                                    Button {
                                        publishPost()
                                    } label: {
                                        Text(isUploading ? "Uploading..." : "Share")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(NeonPrimaryButtonStyle())
                                    .disabled(isUploading)
                                }
                            }
                            .padding(.top, 4)
                        }
                        .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                        .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 22)
                    }
                } else {
                    Form {
                        Section("Create Contract") {
                            TextField("Contract title", text: $contractTitle)
                            TextField("Budget (USD)", text: $contractBudget)
                                .keyboardType(.numberPad)
                            TextField("Location", text: $contractLocation)
                            Toggle("Local hire", isOn: $isLocalHire)
                            Button("Publish Contract") {
                                let budget = Int(contractBudget) ?? 0
                                appState.addContract(
                                    title: contractTitle.isEmpty ? "Untitled Contract" : contractTitle,
                                    budgetUSD: budget,
                                    location: contractLocation.isEmpty ? "Remote" : contractLocation,
                                    isLocalHire: isLocalHire
                                )
                                contractTitle = ""
                                contractBudget = ""
                                contractLocation = ""
                            }
                        }

                        Section("Quick Deals") {
                            ForEach(appState.contracts.prefix(5)) { deal in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(deal.title).font(.headline)
                                    Text("$\(deal.budgetUSD) - \(deal.location)")
                                    Text(deal.isLocalHire ? "Local hire" : "Remote contract")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(appState.mode == .social ? "Create" : "Contracts")
            .onChange(of: selectedMediaItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    await loadSelectedMedia(item: newItem)
                }
            }
            .onAppear {
                postAudience = appState.defaultPostAudience
                storyAudience = appState.defaultStoryAudience
            }
        }
    }

    @ViewBuilder
    private var stepRail: some View {
        HStack(spacing: 8) {
            ForEach(CreateStep.allCases, id: \.rawValue) { step in
                Button {
                    if !isUploading {
                        currentStep = step
                    }
                } label: {
                    Text("\(step.rawValue + 1). \(step.title)")
                        .font(.caption.bold())
                        .foregroundStyle(currentStep == step ? .black : .white.opacity(0.86))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(currentStep == step ? BrandPalette.neonBlue : BrandPalette.cardBg.opacity(0.9))
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var mediaStepCard: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Content Type", selection: $selectedType) {
                    Text("Post").tag(ContentType.post)
                    Text("Story").tag(ContentType.story)
                    Text("Reel").tag(ContentType.reel)
                }
                .pickerStyle(.segmented)

                PhotosPicker(selection: $selectedMediaItem, matching: .any(of: [.images, .videos])) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(BrandPalette.cardBg.opacity(0.95))
                            .frame(height: 300)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(BrandPalette.glassStroke, lineWidth: 1)
                            )
                        if let selectedPhotoData, let image = UIImage(data: selectedPhotoData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 36, weight: .medium))
                                Text("Tap to add photo or video")
                                    .font(.subheadline.weight(.medium))
                                Text("Reels + Stories can be video.")
                                    .font(.caption)
                                    .foregroundStyle(secondaryText)
                            }
                            .foregroundStyle(primaryText)
                        }
                    }
                }
                .buttonStyle(.plain)

                if isLoadingMedia {
                    ProgressView("Preparing media...")
                        .tint(BrandPalette.neonBlue)
                }
                if !selectedMediaName.isEmpty {
                    Text(selectedMediaName)
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                }

                HStack(spacing: 8) {
                    Button("AI Caption") {
                        caption = appState.aiPolishCaption(caption, surfaceStyle: surfaceStyle)
                    }
                    .buttonStyle(.bordered)
                    Button("Clear Caption") {
                        caption = ""
                    }
                    .buttonStyle(.bordered)
                    Button("Remove Media", role: .destructive) {
                        selectedPhotoData = nil
                        selectedVideoData = nil
                        selectedMediaName = ""
                    }
                    .buttonStyle(.bordered)
                    .disabled(!hasMediaSelected)
                }

                TextField(
                    selectedType == .story ? "Story caption..." : "Write a caption...",
                    text: $caption,
                    axis: .vertical
                )
                .lineLimit(2...5)
                .textFieldStyle(EliteTextFieldStyle())

                HStack {
                    Text(hasMediaSelected ? "Media ready" : "No media selected")
                        .font(.caption2)
                        .foregroundStyle(secondaryText)
                    Spacer()
                    Text("\(caption.count) chars")
                        .font(.caption2)
                        .foregroundStyle(secondaryText)
                }
            }
        }
    }

    @ViewBuilder
    private var settingsStepCard: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    audienceChip(title: "Audience", value: postAudience.rawValue)
                    if selectedType == .story {
                        audienceChip(title: "Story", value: storyAudience.rawValue)
                    }
                    Spacer()
                    Toggle("", isOn: $isCollabEnabled)
                        .labelsHidden()
                    Text("Collab")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
                Toggle("Hide likes on this post", isOn: $hideLikesForPost)
                    .foregroundStyle(primaryText)
                Toggle("Hide comments on this post", isOn: $hideCommentsForPost)
                    .foregroundStyle(primaryText)
                Toggle("Block nudity", isOn: $blockNudityContent)
                    .foregroundStyle(primaryText)
                TextField("Tag users (e.g. @user1 @user2)", text: $tagHandlesInput)
                    .textFieldStyle(EliteTextFieldStyle())
                Toggle("Request combined post", isOn: $requestCombinedPosting)
                    .foregroundStyle(primaryText)
                if requestCombinedPosting {
                    TextField("Combined target handle (@username)", text: $combinedTargetHandle)
                        .textFieldStyle(EliteTextFieldStyle())
                }
            }
        }
    }

    @ViewBuilder
    private var reviewStepCard: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Review")
                    .font(.headline)
                    .foregroundStyle(primaryText)
                Text("Type: \(selectedType.rawValue.capitalized)")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
                Text("Surface: \(surfaceStyle.rawValue.capitalized)")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
                Text("Audience: \(postAudience.rawValue)")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
                if selectedType == .story {
                    Text("Story audience: \(storyAudience.rawValue)")
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                }
                if !tagHandlesInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Tags: \(tagHandlesInput)")
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                }
                if requestCombinedPosting {
                    Text("Combined request: \(combinedTargetHandle.isEmpty ? "No target yet" : combinedTargetHandle)")
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                }
                if let selectedPhotoData, let image = UIImage(data: selectedPhotoData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Text(caption.isEmpty ? "No caption" : caption)
                    .foregroundStyle(primaryText)
            }
        }
    }

    private func publishPost() {
        guard !isUploading else { return }
        Task {
            isUploading = true
            uploadProgress = 0
            for step in 1...10 {
                try? await Task.sleep(nanoseconds: 140_000_000)
                uploadProgress = Double(step) / 10.0
            }
            let defaultCaption: String
            switch selectedType {
            case .story: defaultCaption = "New story"
            case .reel, .shortVideo: defaultCaption = "New reel"
            default: defaultCaption = "Untitled post"
            }
            let result = appState.publishPost(
                caption: caption.isEmpty ? defaultCaption : caption,
                type: selectedType,
                imageData: selectedPhotoData,
                storyAudience: storyAudience,
                audience: postAudience,
                isCollab: isCollabEnabled,
                areLikesHidden: hideLikesForPost || appState.hideLikeCountsByDefault,
                areCommentsHidden: hideCommentsForPost || appState.hideCommentCountsByDefault,
                blockNudity: blockNudityContent,
                surfaceStyle: selectedType == .story ? .chit : surfaceStyle,
                taggedHandles: appState.parseTaggedHandles(from: tagHandlesInput)
            )
            if requestCombinedPosting && !combinedTargetHandle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let combinedOK = appState.requestCombinedPost(
                    targetHandle: combinedTargetHandle,
                    caption: caption.isEmpty ? defaultCaption : caption,
                    imageData: selectedPhotoData,
                    surfaceStyle: selectedType == .story ? .chit : surfaceStyle,
                    taggedHandles: appState.parseTaggedHandles(from: tagHandlesInput)
                )
                publishStatus = combinedOK
                    ? "Upload complete - combined request sent."
                    : "Upload complete - combined request failed (check handle)."
            } else {
                publishStatus = "Upload complete - \(result.reason)"
            }
            isUploading = false
            if result.label != .blockedNudity {
                caption = ""
                selectedPhotoData = nil
                selectedVideoData = nil
                selectedMediaName = ""
                hideLikesForPost = false
                hideCommentsForPost = false
                storyAudience = appState.defaultStoryAudience
                postAudience = appState.defaultPostAudience
                tagHandlesInput = ""
                combinedTargetHandle = ""
                requestCombinedPosting = false
                currentStep = .media
            }
        }
    }

    private func nextStep() {
        if let next = CreateStep(rawValue: min(currentStep.rawValue + 1, CreateStep.review.rawValue)) {
            currentStep = next
        }
    }

    private func previousStep() {
        if let prev = CreateStep(rawValue: max(currentStep.rawValue - 1, CreateStep.media.rawValue)) {
            currentStep = prev
        }
    }

    private func resetDraft() {
        caption = ""
        selectedPhotoData = nil
        selectedVideoData = nil
        selectedMediaName = ""
        hideLikesForPost = false
        hideCommentsForPost = false
        storyAudience = appState.defaultStoryAudience
        postAudience = appState.defaultPostAudience
        tagHandlesInput = ""
        combinedTargetHandle = ""
        requestCombinedPosting = false
        isCollabEnabled = true
        publishStatus = ""
        currentStep = .media
    }

    private func loadSelectedMedia(item: PhotosPickerItem) async {
        await MainActor.run {
            isLoadingMedia = true
            selectedMediaName = ""
        }
        let isVideo = item.supportedContentTypes.contains { $0.conforms(to: .movie) || $0.conforms(to: .video) }
        if let rawData = try? await item.loadTransferable(type: Data.self) {
            if isVideo {
                let thumbnail = await makeVideoThumbnailData(from: rawData)
                await MainActor.run {
                    selectedVideoData = rawData
                    selectedPhotoData = thumbnail
                    selectedMediaName = "Video selected - ready for \(selectedType == .story ? "story" : "reel/post") upload"
                    isLoadingMedia = false
                }
            } else {
                await MainActor.run {
                    selectedPhotoData = rawData
                    selectedVideoData = nil
                    selectedMediaName = "Photo selected"
                    isLoadingMedia = false
                }
            }
        } else {
            await MainActor.run {
                selectedMediaName = "Could not load selected media."
                isLoadingMedia = false
            }
        }
    }

    private func makeVideoThumbnailData(from videoData: Data) async -> Data? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("preview-\(UUID().uuidString)")
            .appendingPathExtension("mp4")
        do {
            try videoData.write(to: url, options: [.atomic])
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            let image = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UIImage, Error>) in
                generator.generateCGImageAsynchronously(for: CMTime(seconds: 0.15, preferredTimescale: 600)) { cgImage, _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let cgImage {
                        continuation.resume(returning: UIImage(cgImage: cgImage))
                    } else {
                        continuation.resume(throwing: NSError(domain: "PostView.VideoThumb", code: -1))
                    }
                }
            }
            try? FileManager.default.removeItem(at: url)
            return image.jpegData(compressionQuality: 0.78)
        } catch {
            try? FileManager.default.removeItem(at: url)
            return nil
        }
    }

    @ViewBuilder
    private func audienceChip(title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(secondaryText)
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(primaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.9))
        .clipShape(Capsule())
    }
}
