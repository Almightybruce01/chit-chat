import SwiftUI

struct EnterpriseWorkspaceHomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ZStack {
                EnterpriseBackground()
                ScrollView {
                    VStack(spacing: 12) {
                        header
                        performanceRow
                        hiringPipeline
                        corporateFeed
                    }
                    .padding(.horizontal, LayoutTokens.screenHorizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 18)
                }
            }
            .navigationTitle("Executive")
        }
    }

    private var header: some View {
        EnterpriseCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("Corporate Command Center")
                    .font(.title3.bold())
                    .foregroundStyle(EnterprisePalette.textPrimary)
                Text("This workspace is intentionally separated from social mode: business-first controls, hiring metrics, and network workflow.")
                    .font(.caption)
                    .foregroundStyle(EnterprisePalette.textSecondary)
            }
        }
    }

    private var performanceRow: some View {
        EnterpriseCard {
            HStack(spacing: 8) {
                metric("Followers", "\(appState.enterpriseFollowerHandles.count)")
                metric("Following", "\(appState.enterpriseFollowingHandles.count)")
                metric("Open Roles", "\(appState.contracts.count)")
            }
        }
    }

    private var hiringPipeline: some View {
        EnterpriseCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Hiring Pipeline", systemImage: "person.crop.rectangle.stack.fill")
                    .foregroundStyle(EnterprisePalette.textPrimary)
                    .font(.headline)
                if appState.contracts.isEmpty {
                    Text("No active contracts yet.")
                        .foregroundStyle(EnterprisePalette.textSecondary)
                } else {
                    ForEach(appState.contracts.prefix(4)) { contract in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(contract.title)
                                    .foregroundStyle(EnterprisePalette.textPrimary)
                                Text("\(contract.location) • $\(contract.budgetUSD)")
                                    .font(.caption)
                                    .foregroundStyle(EnterprisePalette.textSecondary)
                            }
                            Spacer()
                            Text(contract.isLocalHire ? "Local" : "Remote")
                                .font(.caption2.bold())
                                .foregroundStyle(contract.isLocalHire ? EnterprisePalette.success : EnterprisePalette.action)
                        }
                    }
                }
            }
        }
    }

    private var corporateFeed: some View {
        EnterpriseCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Corporate Feed Snapshot", systemImage: "newspaper.fill")
                    .foregroundStyle(EnterprisePalette.textPrimary)
                    .font(.headline)
                let feed = appState.posts
                    .filter { !$0.isArchived && $0.surfaceStyle == .chat }
                    .prefix(4)
                if feed.isEmpty {
                    Text("No corporate feed entries yet.")
                        .foregroundStyle(EnterprisePalette.textSecondary)
                } else {
                    ForEach(Array(feed), id: \.id) { post in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(post.authorHandle)
                                .font(.caption.bold())
                                .foregroundStyle(EnterprisePalette.action)
                            Text(post.caption)
                                .font(.subheadline)
                                .foregroundStyle(EnterprisePalette.textPrimary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundStyle(EnterprisePalette.textPrimary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(EnterprisePalette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct EnterpriseTalentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var query = ""

    var body: some View {
        NavigationStack {
            ZStack {
                EnterpriseBackground()
                ScrollView {
                    VStack(spacing: 12) {
                        EnterpriseCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Talent Discovery")
                                    .font(.headline)
                                    .foregroundStyle(EnterprisePalette.textPrimary)
                                TextField("Search enterprise handle or name", text: $query)
                                    .textFieldStyle(EliteTextFieldStyle())
                            }
                        }
                        EnterpriseCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Recommended Profiles")
                                    .font(.headline)
                                    .foregroundStyle(EnterprisePalette.textPrimary)
                                ForEach(filteredUsers) { user in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(user.enterpriseAlias)
                                                .foregroundStyle(EnterprisePalette.textPrimary)
                                            Text(user.handle)
                                                .font(.caption)
                                                .foregroundStyle(EnterprisePalette.textSecondary)
                                        }
                                        Spacer()
                                        Text("\(user.followers)")
                                            .font(.caption.bold())
                                            .foregroundStyle(EnterprisePalette.action)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, LayoutTokens.screenHorizontal)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Talent")
        }
    }

    private var filteredUsers: [UserProfile] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return appState.internalUsers
        }
        return appState.internalUsers.filter {
            $0.enterpriseAlias.localizedCaseInsensitiveContains(trimmed)
                || $0.handle.localizedCaseInsensitiveContains(trimmed)
                || $0.displayName.localizedCaseInsensitiveContains(trimmed)
        }
    }
}

struct EnterpriseComposerView: View {
    @EnvironmentObject private var appState: AppState
    @State private var updateText = ""
    @State private var selectedType: ComposerType = .update
    @State private var status = ""

    var body: some View {
        NavigationStack {
            ZStack {
                EnterpriseBackground()
                ScrollView {
                    VStack(spacing: 12) {
                        EnterpriseCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Corporate Composer")
                                    .font(.headline)
                                    .foregroundStyle(EnterprisePalette.textPrimary)
                                Picker("Type", selection: $selectedType) {
                                    ForEach(ComposerType.allCases, id: \.self) { item in
                                        Text(item.rawValue).tag(item)
                                    }
                                }
                                .pickerStyle(.segmented)
                                TextField("Write company update, hiring note, or leadership memo", text: $updateText, axis: .vertical)
                                    .lineLimit(3...8)
                                    .textFieldStyle(EliteTextFieldStyle())
                                Button("Publish to Corporate Feed") {
                                    publish()
                                }
                                .buttonStyle(EnterprisePrimaryButtonStyle())
                                if !status.isEmpty {
                                    Text(status)
                                        .font(.caption)
                                        .foregroundStyle(EnterprisePalette.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, LayoutTokens.screenHorizontal)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Compose")
        }
    }

    private func publish() {
        let base = updateText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !base.isEmpty else {
            status = "Add text before publishing."
            return
        }
        let prefix = selectedType.rawValue.uppercased()
        _ = appState.publishPost(
            caption: "[\(prefix)] \(base)",
            type: .post,
            imageData: nil,
            storyAudience: .public,
            audience: .public,
            isCollab: false,
            areLikesHidden: false,
            areCommentsHidden: false,
            blockNudity: true,
            surfaceStyle: .chat
        )
        status = "Published to corporate feed."
        updateText = ""
    }

    private enum ComposerType: String, CaseIterable {
        case update = "Update"
        case hiring = "Hiring"
        case leadership = "Leadership"
    }
}

struct EnterpriseInboxView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showChat = false

    var body: some View {
        NavigationStack {
            ZStack {
                EnterpriseBackground()
                ScrollView {
                    VStack(spacing: 12) {
                        EnterpriseCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Business Messaging")
                                    .font(.headline)
                                    .foregroundStyle(EnterprisePalette.textPrimary)
                                Text("Use structured, role-aware communication flows for candidates, collaborators, and internal ops.")
                                    .font(.caption)
                                    .foregroundStyle(EnterprisePalette.textSecondary)
                                Button("Open Full Messaging Workspace") {
                                    showChat = true
                                }
                                .buttonStyle(EnterprisePrimaryButtonStyle())
                            }
                        }
                        EnterpriseCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Message Requests")
                                    .font(.headline)
                                    .foregroundStyle(EnterprisePalette.textPrimary)
                                if appState.dmRequests.isEmpty {
                                    Text("No pending requests.")
                                        .foregroundStyle(EnterprisePalette.textSecondary)
                                } else {
                                    ForEach(appState.dmRequests.prefix(6)) { request in
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(request.fromHandle)
                                                .foregroundStyle(EnterprisePalette.textPrimary)
                                            Text(request.previewText)
                                                .font(.caption)
                                                .foregroundStyle(EnterprisePalette.textSecondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, LayoutTokens.screenHorizontal)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Inbox")
            .sheet(isPresented: $showChat) {
                NavigationStack {
                    ChatView()
                        .environmentObject(appState)
                }
            }
        }
    }
}

struct EnterpriseProfileView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            CorporateHubView()
                .environmentObject(appState)
        }
    }
}
