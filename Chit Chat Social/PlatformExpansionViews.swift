import SwiftUI
import UIKit

struct AdminDashboardView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("chitchat.dashboard.autoVerifyIG") private var autoVerifyIGSignals = false
    @State private var query = ""
    @State private var reviewerNote = ""
    @State private var selectedSection: DashboardSection = .verificationQueue
    @State private var adminFeedback: String?
    @State private var newHoldUsername = ""
    @State private var placeholderUsername = ""
    @State private var placeholderDisplay = ""
    @State private var placeholderPassword = ""
    @State private var placeholderOfficial = true
    @State private var assistantProblem = ""

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
                    Section("Dashboard area") {
                        Picker("Area", selection: $selectedSection) {
                            ForEach(DashboardSection.allCases, id: \.self) { section in
                                Text(section.rawValue).tag(section)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    if let adminFeedback {
                        Section {
                            Text(adminFeedback)
                                .font(.caption)
                                .foregroundStyle(primaryText)
                        }
                    }

                    if selectedSection == .verificationQueue {
                        Section("Auto verification (Chit Chat Social)") {
                            Toggle("Auto-approve when IG signal is attached", isOn: $autoVerifyIGSignals)
                            Text("Pending requests that include the Instagram verification signal can be approved automatically. Tap below to run a pass anytime.")
                                .font(.caption)
                                .foregroundStyle(secondaryText)
                            Button("Run auto-verify now") {
                                adminFeedback = nil
                                appState.autoApproveIGSignalVerificationRequests()
                                adminFeedback = "Auto-verify pass complete."
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        Section("Bulk queue (careful)") {
                            Text("Approves every pending request with an admin note. Use when you trust the whole batch.")
                                .font(.caption)
                                .foregroundStyle(secondaryText)
                            Button("Approve all pending requests now") {
                                adminFeedback = nil
                                appState.approveAllPendingVerificationRequests()
                                adminFeedback = "All pending requests approved."
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        }
                    }

                    if selectedSection == .verificationQueue || selectedSection == .users {
                        Section("User Search") {
                            TextField("Search username, display name, or handle", text: $query)
                        }
                    }

                    if selectedSection == .jobApprovals {
                        Section("Pending job posts (business accounts)") {
                            let pending = appState.contracts.filter { $0.isPendingApproval }
                            if pending.isEmpty {
                                Text("No pending job posts.")
                                    .foregroundStyle(secondaryText)
                            } else {
                                ForEach(pending) { deal in
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(deal.title)
                                            .font(.headline)
                                            .foregroundStyle(primaryText)
                                        Text("\(deal.authorHandle) • $\(deal.budgetUSD) • \(deal.location)")
                                            .font(.caption)
                                            .foregroundStyle(secondaryText)
                                        Button("Approve") {
                                            appState.approveJobPost(contractID: deal.id)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.green)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
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
                                        Text("Category: \(request.category.displayName)")
                                            .font(.caption)
                                            .foregroundStyle(secondaryText)
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
                        let matches = appState.filteredInternalUsers(query: query)
                        Section("All users (\(matches.count))") {
                            if matches.isEmpty {
                                Text("No users match this search.")
                                    .foregroundStyle(secondaryText)
                            } else {
                                ForEach(matches) { user in
                                    NavigationLink {
                                        AdminUserDetailView(profile: user)
                                            .environmentObject(appState)
                                    } label: {
                                        adminUserRowLabel(user)
                                    }
                                }
                            }
                        }
                    }

                    if selectedSection == .holds {
                        Section("Username holds (you add manually)") {
                            Text("Chit Chat Social does not scrape Instagram or league rosters. Add VIP handles yourself after you confirm the rightful owner. Holds block new signups for that username.")
                                .font(.caption)
                                .foregroundStyle(secondaryText)
                            TextField("username to hold", text: $newHoldUsername)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            Button("Add hold") {
                                if let err = ReservedHandles.addAdminHeldUsername(newHoldUsername) {
                                    adminFeedback = err
                                } else {
                                    adminFeedback = "Hold added."
                                    newHoldUsername = ""
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        Section("Active holds (\(ReservedHandles.adminHeldUsernamesSorted().count))") {
                            if ReservedHandles.adminHeldUsernamesSorted().isEmpty {
                                Text("No extra holds. System brand list still applies.")
                                    .foregroundStyle(secondaryText)
                            } else {
                                ForEach(ReservedHandles.adminHeldUsernamesSorted(), id: \.self) { name in
                                    HStack {
                                        Text("@\(name)")
                                            .foregroundStyle(primaryText)
                                        Spacer()
                                        Button("Release") {
                                            ReservedHandles.removeAdminHeldUsername(name)
                                            adminFeedback = "Released @\(name)."
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(.cyan)
                                    }
                                }
                            }
                        }
                        Section("Placeholder account (login + profile)") {
                            Text("Creates a local account with password. Share credentials securely. Optional official badge. Handoff email: open the user after creation.")
                                .font(.caption)
                                .foregroundStyle(secondaryText)
                            TextField("Username", text: $placeholderUsername)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            TextField("Display name", text: $placeholderDisplay)
                            SecureField("Password (8+ chars)", text: $placeholderPassword)
                            Toggle("Grant official verified badge", isOn: $placeholderOfficial)
                            Button("Create placeholder") {
                                if let err = appState.adminCreatePlaceholderLocalAccount(
                                    username: placeholderUsername,
                                    displayName: placeholderDisplay,
                                    password: placeholderPassword,
                                    grantOfficialVerifiedBadge: placeholderOfficial
                                ) {
                                    adminFeedback = err
                                } else {
                                    adminFeedback = "Placeholder created."
                                    placeholderUsername = ""
                                    placeholderDisplay = ""
                                    placeholderPassword = ""
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                    }

                    if selectedSection == .guide {
                        Section("Every admin feature") {
                            adminFeatureBullet("Queue — Approve/decline verification requests; auto-verify IG signal; bulk-approve all pending.")
                            adminFeatureBullet("Jobs — Approve pending business job posts.")
                            adminFeatureBullet("Users — Search directory; tap a person for official verify, paid badge, rename, handoff email, delete.")
                            adminFeatureBullet("Holds — Block usernames without a profile; release when ready; create placeholder accounts with password.")
                            adminFeatureBullet("Help — Describe a problem; copy a prompt for ChatGPT / Cursor with exact dashboard context.")
                        }
                        Section("Badges") {
                            adminFeatureBullet("Official verified — internal trust badge (use for real approvals).")
                            adminFeatureBullet("Paid — separate monetized badge; not the same as official.")
                        }
                    }

                    if selectedSection == .assistant {
                        Section("Describe your problem") {
                            TextEditor(text: $assistantProblem)
                                .frame(minHeight: 120)
                                .foregroundStyle(primaryText)
                            Button("Copy steps prompt for AI") {
                                UIPasteboard.general.string = adminAssistantPromptBody
                                adminFeedback = "Prompt copied. Paste into ChatGPT or Cursor."
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        Section("Included in the prompt") {
                            Text(adminAssistantPromptBody)
                                .font(.caption2)
                                .foregroundStyle(secondaryText)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .onChange(of: selectedSection) { _, newSection in
                if newSection == .verificationQueue, autoVerifyIGSignals {
                    appState.autoApproveIGSignalVerificationRequests()
                }
            }
            .onAppear {
                if selectedSection == .verificationQueue, autoVerifyIGSignals {
                    appState.autoApproveIGSignalVerificationRequests()
                }
            }
        }
        .navigationTitle("Chit Chat Social Admin")
    }

    private var adminAssistantPromptBody: String {
        let problem = assistantProblem.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = problem.isEmpty ? "(describe your issue above first)" : problem
        return """
        I am the admin of the Chit Chat Social iOS app (local MVP + Firebase stubs).

        My problem: \(p)

        The in-app admin dashboard has these areas (menu at top):
        - Queue: verification approve/decline, IG auto-verify, bulk approve all pending.
        - Jobs: approve business job posts.
        - Users: search users; tap opens detail for official verified badge, paid badge, clear badges, rename, optional handoff email note, delete.
        - Holds: manually add/release username holds (no scraping); create placeholder accounts with password + optional official badge.
        - Help: this list.

        Official verified is the internal trust badge; paid is separate.

        Give numbered, exact steps I should tap in the app, and mention if something needs Xcode, Firebase Console, or GitHub instead. Be concise.
        """
    }

    @ViewBuilder
    private func adminUserRowLabel(_ user: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(user.displayName)
                .font(.headline)
                .foregroundStyle(primaryText)
            Text("\(user.handle) · \(statusLabel(user.verificationStatus))")
                .font(.caption)
                .foregroundStyle(secondaryText)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func adminFeatureBullet(_ text: String) -> some View {
        Text("• \(text)")
            .font(.subheadline)
            .foregroundStyle(secondaryText)
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
        case .verifiedInternal: return "Official verified"
        }
    }

    private enum DashboardSection: String, CaseIterable {
        case verificationQueue = "Queue"
        case jobApprovals = "Jobs"
        case users = "Users"
        case holds = "Holds"
        case guide = "Guide"
        case assistant = "Help"
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
