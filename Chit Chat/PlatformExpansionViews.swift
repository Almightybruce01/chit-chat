import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var query = ""
    @State private var reviewerNote = ""
    @State private var selectedSection: DashboardSection = .verificationQueue

    var body: some View {
        ZStack {
            EliteBackground()
            List {
                if !appState.canAccessInternalDashboard {
                    Section {
                        Text("Internal dashboard access is restricted.")
                            .foregroundStyle(secondaryText)
                    }
                } else {
                    Section("Dashboard Sections") {
                        Picker("Sections", selection: $selectedSection) {
                            ForEach(DashboardSection.allCases, id: \.self) { section in
                                Text(section.rawValue).tag(section)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if selectedSection == .verificationQueue || selectedSection == .users {
                        Section("User Search") {
                            TextField("Search username or handle", text: $query)
                        }
                    }

                    if selectedSection == .verificationQueue {
                        Section("Verification Queue") {
                            let pending = appState.verificationRequests.filter { $0.status == .pending }
                            if pending.isEmpty {
                                Text("No pending verification requests.")
                                    .foregroundStyle(secondaryText)
                            } else {
                                ForEach(pending) { request in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("\(request.handle) • \(request.username)")
                                            .font(.headline)
                                            .foregroundStyle(primaryText)
                                        Text(request.note)
                                            .font(.subheadline)
                                            .foregroundStyle(secondaryText)
                                        Text(request.hasInstagramVerification ? "Signal: Instagram verified" : "Signal: No external verification attached")
                                            .font(.caption)
                                            .foregroundStyle(secondaryText)
                                        TextField("Reviewer note (optional)", text: $reviewerNote)
                                        HStack {
                                            Button("Approve") {
                                                appState.approveVerificationRequest(request.id, reviewerNote: reviewerNote)
                                                reviewerNote = ""
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .tint(.green)

                                            Button("Decline") {
                                                appState.declineVerificationRequest(request.id, reviewerNote: reviewerNote)
                                                reviewerNote = ""
                                            }
                                            .buttonStyle(.bordered)
                                            .tint(.red)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }

                        Section("Decision History") {
                            let reviewed = appState.verificationRequests
                                .filter { $0.status != .pending }
                                .prefix(20)
                            if reviewed.isEmpty {
                                Text("No completed verification decisions yet.")
                                    .foregroundStyle(secondaryText)
                            } else {
                                ForEach(Array(reviewed)) { request in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(request.handle) • \(request.status.rawValue.capitalized)")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(primaryText)
                                        if !request.reviewerNote.isEmpty {
                                            Text(request.reviewerNote)
                                                .font(.caption)
                                                .foregroundStyle(secondaryText)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if selectedSection == .users {
                        Section("Current Users") {
                            ForEach(appState.filteredInternalUsers(query: query)) { user in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("\(user.displayName) (\(user.handle))")
                                        .font(.headline)
                                        .foregroundStyle(primaryText)
                                    Text("Status: \(statusLabel(user.verificationStatus))")
                                        .font(.subheadline)
                                        .foregroundStyle(secondaryText)
                                    HStack {
                                        Button("Grant Real Verify") {
                                            appState.grantInternalVerification(userID: user.id)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        Button("Set Paid") {
                                            if appState.currentUser.id == user.id {
                                                appState.requestPaidVerification()
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    if selectedSection == .ai {
                        Section("AI Reviewer Assistant") {
                            Text("AI helper prompts:")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(primaryText)
                            Text("• High-trust signals: linked platforms, engagement consistency, impersonation checks")
                                .foregroundStyle(secondaryText)
                            Text("• Fast review path: prioritize IG-verified + high follower integrity profiles")
                                .foregroundStyle(secondaryText)
                            Text("• Fraud checks: recent username changes, suspicious growth spikes, duplicate bios")
                                .foregroundStyle(secondaryText)
                        }
                    }

                    if selectedSection == .settings {
                        Section("Review Settings") {
                            Text("Use Verification Queue for decisions, Users for manual override, AI section for guided checks.")
                                .foregroundStyle(secondaryText)
                            Text("This dashboard is optimized for approve/decline workflows in under 2 taps.")
                                .foregroundStyle(secondaryText)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Internal Verification")
    }

    private var primaryText: Color {
        colorScheme == .light ? .black : .white
    }

    private var secondaryText: Color {
        colorScheme == .light ? .black.opacity(0.72) : .white.opacity(0.78)
    }

    private func statusLabel(_ status: VerificationStatus) -> String {
        switch status {
        case .unverified: return "Unverified"
        case .pending: return "Pending"
        case .paid: return "Paid badge"
        case .verifiedInternal: return "Official internal verified"
        }
    }

    private enum DashboardSection: String, CaseIterable {
        case verificationQueue = "Queue"
        case users = "Users"
        case ai = "AI"
        case settings = "Settings"
    }
}

struct CommunitiesHubView: View {
    @EnvironmentObject private var appState: AppState
    @State private var name = ""
    @State private var summary = ""
    @State private var isPublic = true
    @State private var requiresPassword = false

    var body: some View {
        ZStack {
            EliteBackground()
            Form {
                Section("Create Community") {
                    TextField("Community name", text: $name)
                    TextField("What this community promotes", text: $summary, axis: .vertical)
                        .lineLimit(2...4)
                    Toggle("Public", isOn: $isPublic)
                    Toggle("Password required", isOn: $requiresPassword)
                    Button("Create") {
                        appState.createCommunity(
                            name: name.isEmpty ? "Untitled Community" : name,
                            summary: summary.isEmpty ? "No summary provided." : summary,
                            isPublic: isPublic,
                            requiresPassword: requiresPassword
                        )
                        name = ""
                        summary = ""
                        isPublic = true
                        requiresPassword = false
                    }
                }

                Section("Discover Communities") {
                    ForEach(appState.communities) { group in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(group.name).font(.headline)
                            Text(group.summary).font(.subheadline)
                            Text("Creator: \(group.creator) | Managers: \(group.managers.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.75))
                            Text(group.isPublic ? "Public searchable" : "Private searchable")
                                .font(.caption2)
                                .foregroundStyle(group.isPublic ? .green : .orange)
                            if group.requiresPassword {
                                Text("Requires password to join")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Groups & Communities")
    }
}

struct ShopHubView: View {
    @EnvironmentObject private var appState: AppState
    @State private var title = ""
    @State private var detail = ""
    @State private var price = ""
    @State private var dropship = false
    @State private var selectedView = 0

    var body: some View {
        VStack(spacing: 12) {
            Picker("Shop View", selection: $selectedView) {
                Text("Live Swipe").tag(0)
                Text("Products").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if selectedView == 0 {
                TabView {
                    ForEach(appState.liveShopSessions) { session in
                        EliteCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(session.headline)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text("Host: \(session.hostHandle) • \(session.viewerCount) watching")
                                    .foregroundStyle(.white.opacity(0.75))
                                if let product = appState.shopProducts.first(where: { $0.id == session.productID }) {
                                    Label(product.title, systemImage: product.imageSystemName)
                                        .foregroundStyle(BrandPalette.neonGreen)
                                    Text("$\(product.priceUSD)")
                                        .font(.title3.bold())
                                        .foregroundStyle(.white)
                                    Button("Direct product link") {}
                                        .buttonStyle(.borderedProminent)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 230)
            } else {
                List {
                    Section("Scrollable Products") {
                        ForEach(appState.shopProducts) { product in
                            VStack(alignment: .leading, spacing: 4) {
                                Label(product.title, systemImage: product.imageSystemName)
                                    .font(.headline)
                                Text(product.description)
                                    .font(.subheadline)
                                Text("$\(product.priceUSD) • Seller \(product.sellerHandle)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if product.isDropshipEnabled {
                                    Text("Dropshipping enabled")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }

            Form {
                Section("Add Product") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $detail)
                    TextField("Price", text: $price)
                        .keyboardType(.numberPad)
                    Toggle("Enable dropshipping", isOn: $dropship)
                    Button("Publish Product") {
                        appState.addShopProduct(
                            title: title.isEmpty ? "Untitled Product" : title,
                            description: detail.isEmpty ? "No description." : detail,
                            priceUSD: Int(price) ?? 0,
                            isDropshipEnabled: dropship
                        )
                        title = ""
                        detail = ""
                        price = ""
                        dropship = false
                    }
                }
            }
            .frame(maxHeight: 250)
        }
        .background(EliteBackground())
        .navigationTitle("Shop")
    }
}

struct PulseBoardView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showComposer = false
    @State private var postText = ""
    @State private var includePhoto = false

    var body: some View {
        ZStack {
            EliteBackground()
            List {
                Section("Posts") {
                    ForEach(appState.publicPulse) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.authorHandle)
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(item.text)
                                .foregroundStyle(.white.opacity(0.92))
                            if let imageSystemName = item.imageSystemName {
                                Label("Photo attached", systemImage: imageSystemName)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.74))
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Pulse")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showComposer = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(BrandPalette.neonBlue)
                }
                .accessibilityLabel("Create Pulse post")
            }
        }
        .sheet(isPresented: $showComposer) {
            NavigationStack {
                Form {
                    Section("Post to Pulse") {
                        TextField("What is happening?", text: $postText, axis: .vertical)
                            .lineLimit(2...4)
                        Toggle("Attach photo", isOn: $includePhoto)
                        Button("Post") {
                            appState.addPulsePost(
                                text: postText.isEmpty ? "Quick update from \(appState.currentUser.handle)" : postText,
                                imageSystemName: includePhoto ? "photo.fill" : nil
                            )
                            postText = ""
                            includePhoto = false
                            showComposer = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .navigationTitle("New Pulse")
            }
        }
    }
}

struct MusicHubView: View {
    @EnvironmentObject private var appState: AppState
    @State private var query = ""
    @State private var source: MusicSource? = nil

    var body: some View {
        ZStack {
            EliteBackground()
            List {
                Section("Search") {
                    TextField("Search songs or artist", text: $query)
                    Picker("Source", selection: Binding(
                        get: { source ?? .appleMusic },
                        set: { source = $0 }
                    )) {
                        ForEach(MusicSource.allCases, id: \.self) { item in
                            Text(item.displayName).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text(appState.musicStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.74))
                }

                if let now = appState.nowPlayingTrack {
                    Section("Now Playing") {
                        HStack(spacing: 10) {
                            Image(systemName: appState.isMusicPlaying ? "waveform.circle.fill" : "pause.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(BrandPalette.neonGreen)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(now.title).font(.headline)
                                Text("\(now.artist) • \(now.source.displayName)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.75))
                            }
                            Spacer()
                            Button {
                                appState.togglePlayback()
                            } label: {
                                Image(systemName: appState.isMusicPlaying ? "pause.fill" : "play.fill")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }

                Section("Results") {
                    ForEach(appState.searchMusic(query: query, source: source)) { track in
                        HStack(spacing: 10) {
                            Image(systemName: sourceIcon(track.source))
                                .foregroundStyle(BrandPalette.neonBlue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.title).font(.headline)
                                Text("\(track.artist) • \(track.source.displayName)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.75))
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
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Music")
    }

    private func sourceIcon(_ source: MusicSource) -> String {
        switch source {
        case .appleMusic: return "apple.logo"
        case .spotify: return "dot.radiowaves.left.and.right"
        case .youtube: return "play.rectangle.fill"
        }
    }
}
