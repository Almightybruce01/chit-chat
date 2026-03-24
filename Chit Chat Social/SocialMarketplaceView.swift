import SwiftUI

private enum SocialCommerceTab: String, CaseIterable, Identifiable {
    case marketplace = "Marketplace"
    case shipNow = "Ship Now"
    case meetUp = "Meet Up"
    case live = "Live Shop"
    case discover = "Discover"
    var id: String { rawValue }
}

struct SocialMarketplaceView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var tab: SocialCommerceTab = .marketplace
    @State private var liveCommentDraft = ""
    @State private var roomNameDraft = ""
    @State private var hostRoleHandle = ""
    @State private var selectedRole: CorporateCallRole = .host
    @State private var conciergeTip = "Tap AI Concierge for a smarter bundle."

    var body: some View {
        NavigationStack {
            ZStack {
                EliteBackground()
                ScrollView {
                    VStack(spacing: 12) {
                        FuturisticSectionHeader(
                            title: "Marketplace + Commerce",
                            subtitle: "Shop, ship, local meetups, and live commerce."
                        )
                        tabRail

                        switch tab {
                        case .marketplace:
                            marketplacePanel
                        case .shipNow:
                            shipNowPanel
                        case .meetUp:
                            meetUpPanel
                        case .live:
                            livePanel
                        case .discover:
                            discoverPanel
                        }
                    }
                    .padding(.horizontal, LayoutTokens.screenHorizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 98)
                }
            }
            .navigationTitle("Market")
        }
    }

    private var tabRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SocialCommerceTab.allCases) { item in
                    Button(item.rawValue) {
                        withAnimation(MotionTokens.spring) {
                            tab = item
                        }
                    }
                    .buttonStyle(SnappyScaleButtonStyle())
                    .font(.caption.bold())
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(item == tab ? BrandPalette.neonBlue.opacity(0.25) : BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.82))
                    .overlay(
                        Capsule().stroke(item == tab ? BrandPalette.neonBlue.opacity(0.8) : BrandPalette.adaptiveGlassStroke(for: colorScheme), lineWidth: 1)
                    )
                    .clipShape(Capsule())
                    .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                }
            }
        }
    }

    private var marketplacePanel: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Top Listings")
                    .font(.headline)
                    .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                ForEach(appState.shopProducts.prefix(8)) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.imageSystemName)
                            .font(.title3)
                            .foregroundStyle(BrandPalette.neonBlue)
                            .frame(width: 34, height: 34)
                            .background(BrandPalette.neonBlue.opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline.bold())
                            Text(item.description)
                                .font(.caption)
                                .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                        }
                        Spacer()
                        Text("$\(item.priceUSD)")
                            .font(.subheadline.bold())
                            .foregroundStyle(BrandPalette.neonGreen)
                    }
                }
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("AI Concierge")
                        .font(.subheadline.bold())
                    Text(conciergeTip)
                        .font(.caption)
                        .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                    Button("Generate Smart Bundle") {
                        let picks = appState.shopProducts.prefix(2)
                        let names = picks.map(\.title).joined(separator: " + ")
                        let total = picks.reduce(0) { $0 + $1.priceUSD }
                        let discounted = max(1, Int(Double(total) * 0.88))
                        conciergeTip = "Bundle suggestion: \(names) • Save 12% • $\(discounted)"
                    }
                    .buttonStyle(NeonPrimaryButtonStyle())
                }
            }
        }
    }

    private var shipNowPanel: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Ship Now (TikTok-shop style)")
                    .font(.headline)
                Text("Instant checkout, auto labels, and seller auto-reply templates.")
                    .font(.caption)
                    .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                ForEach(appState.marketListings.prefix(8)) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline.bold())
                            Text("\(item.category) • Seller \(item.seller)")
                                .font(.caption2)
                                .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                        }
                        Spacer()
                        Text("$\(item.priceUSD)")
                            .font(.subheadline.bold())
                            .foregroundStyle(BrandPalette.neonGreen)
                    }
                }
            }
        }
    }

    private var meetUpPanel: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Meet Up (Marketplace local)")
                    .font(.headline)
                Text("Create safe pickup plans and share meetup location details.")
                    .font(.caption)
                    .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))

                ForEach(appState.marketListings.prefix(6)) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.subheadline.bold())
                        Text("Pickup near \(appState.localCity) • Seller \(item.seller)")
                            .font(.caption)
                            .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                        Button("Create meetup plan") {}
                            .buttonStyle(NeonPrimaryButtonStyle())
                    }
                }
            }
        }
    }

    private var livePanel: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(appState.isLiveNow ? "LIVE" : "Offline", systemImage: appState.isLiveNow ? "dot.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                        .font(.headline)
                        .foregroundStyle(appState.isLiveNow ? .red : BrandPalette.adaptiveTextSecondary(for: colorScheme))
                    Spacer()
                    Text("\(appState.liveViewerCount) viewers")
                        .font(.caption.bold())
                        .foregroundStyle(BrandPalette.neonGreen)
                }
                HStack(spacing: 8) {
                    Button(appState.isLiveNow ? "End Live" : "Go Live") {
                        if appState.isLiveNow {
                            appState.endLiveSession()
                        } else {
                            appState.startLiveSession(headline: "Marketplace Live")
                        }
                    }
                    .buttonStyle(NeonPrimaryButtonStyle())
                    Button("Emoji Face Mask \(appState.socialFaceEmojiMask)") {
                        let options = ["😎", "🤖", "🔥", "😈", "👽", "🎭"]
                        appState.applySocialFaceEmojiMask(options.randomElement() ?? "😎")
                    }
                    .buttonStyle(.bordered)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Live comments")
                        .font(.caption.bold())
                    if appState.liveComments.isEmpty {
                        Text("No comments yet.")
                            .font(.caption)
                            .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                    } else {
                        ForEach(appState.liveComments.prefix(8)) { item in
                            Text("\(item.authorHandle): \(item.text)")
                                .font(.caption)
                        }
                    }
                }
                HStack(spacing: 8) {
                    TextField("Add live comment...", text: $liveCommentDraft)
                        .textFieldStyle(EliteTextFieldStyle())
                    Button("Send") {
                        appState.postLiveComment(liveCommentDraft)
                        liveCommentDraft = ""
                    }
                    .buttonStyle(NeonPrimaryButtonStyle())
                    .disabled(liveCommentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var discoverPanel: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Discovery + Call Controls")
                    .font(.headline)
                NavigationLink {
                    SearchView()
                        .environmentObject(appState)
                } label: {
                    Label("Open full Search/Discover", systemImage: "magnifyingglass")
                        .font(.subheadline.bold())
                }

                Divider()
                Text("Corporate meeting rooms")
                    .font(.subheadline.bold())
                HStack(spacing: 8) {
                    TextField("Room title", text: $roomNameDraft)
                        .textFieldStyle(EliteTextFieldStyle())
                    Button("Add Room") {
                        appState.addCorporateMeetingRoom(title: roomNameDraft, participants: [appState.currentUser.handle])
                        roomNameDraft = ""
                    }
                    .buttonStyle(.borderedProminent)
                }
                Button("Split into breakout rooms") {
                    appState.splitCorporateMeetingRooms()
                }
                .buttonStyle(.bordered)

                HStack(spacing: 8) {
                    TextField("Assign role handle", text: $hostRoleHandle)
                        .textFieldStyle(EliteTextFieldStyle())
                    Picker("Role", selection: $selectedRole) {
                        ForEach(CorporateCallRole.allCases) { role in
                            Text(role.rawValue.capitalized).tag(role)
                        }
                    }
                    .pickerStyle(.menu)
                    Button("Assign") {
                        appState.assignCorporateRole(handle: hostRoleHandle, role: selectedRole)
                        hostRoleHandle = ""
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

// MARK: - Full Store (from Home)
struct FullStoreView: View {
    var onBack: () -> Void
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var tab: SocialCommerceTab = .marketplace
    @State private var liveCommentDraft = ""
    @State private var roomNameDraft = ""
    @State private var hostRoleHandle = ""
    @State private var selectedRole: CorporateCallRole = .host
    @State private var conciergeTip = "Tap AI Concierge for a smarter bundle."

    var body: some View {
        ZStack {
            storeBackground
            VStack(spacing: 0) {
                storeHeader
                ScrollView {
                    VStack(spacing: 12) {
                        storeTabRail
                        storeContent
                    }
                    .padding(.horizontal, LayoutTokens.screenHorizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 98)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var storeBackground: some View {
        LinearGradient(
            colors: colorScheme == .light
                ? [Color(red: 0.98, green: 0.96, blue: 0.92), Color(red: 0.94, green: 0.90, blue: 0.86)]
                : [Color(red: 0.08, green: 0.06, blue: 0.04), Color(red: 0.12, green: 0.08, blue: 0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var storeHeader: some View {
        HStack(spacing: 12) {
            Button {
                onBack()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.body.bold())
                    Text("Back")
                        .font(.headline)
                }
                .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.9))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            Text("Store")
                .font(.title2.bold())
                .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
            Spacer()
        }
        .padding(.horizontal, LayoutTokens.screenHorizontal)
        .padding(.vertical, 12)
        .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.6))
    }

    private var storeTabRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SocialCommerceTab.allCases) { item in
                    Button(item.rawValue) {
                        withAnimation(MotionTokens.spring) { tab = item }
                    }
                    .buttonStyle(SnappyScaleButtonStyle())
                    .font(.caption.bold())
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(tab == item ? Color.orange.opacity(0.25) : BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.82))
                    .overlay(Capsule().stroke(tab == item ? Color.orange.opacity(0.8) : BrandPalette.adaptiveGlassStroke(for: colorScheme), lineWidth: 1))
                    .clipShape(Capsule())
                    .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                }
            }
        }
    }

    @ViewBuilder
    private var storeContent: some View {
        switch tab {
        case .marketplace: storeMarketplacePanel
        case .shipNow: storeShipPanel
        case .meetUp: storeMeetUpPanel
        case .live: storeLivePanel
        case .discover: storeDiscoverPanel
        }
    }

    private var storeMarketplacePanel: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Top Listings")
                    .font(.headline)
                    .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                ForEach(appState.shopProducts.prefix(8)) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.imageSystemName)
                            .font(.title3)
                            .foregroundStyle(.orange)
                            .frame(width: 34, height: 34)
                            .background(Color.orange.opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title).font(.subheadline.bold())
                            Text(item.description).font(.caption)
                                .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                        }
                        Spacer()
                        Text("$\(item.priceUSD)")
                            .font(.subheadline.bold())
                            .foregroundStyle(BrandPalette.neonGreen)
                    }
                }
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("AI Concierge").font(.subheadline.bold())
                    Text(conciergeTip).font(.caption)
                        .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                    Button("Generate Smart Bundle") {
                        let picks = appState.shopProducts.prefix(2)
                        let names = picks.map(\.title).joined(separator: " + ")
                        let total = picks.reduce(0) { $0 + $1.priceUSD }
                        let discounted = max(1, Int(Double(total) * 0.88))
                        conciergeTip = "Bundle: \(names) • Save 12% • $\(discounted)"
                    }
                    .buttonStyle(NeonPrimaryButtonStyle())
                }
            }
        }
    }

    private var storeShipPanel: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Ship Now")
                    .font(.headline)
                Text("Instant checkout, auto labels, seller templates.")
                    .font(.caption)
                    .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                ForEach(appState.marketListings.prefix(8)) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title).font(.subheadline.bold())
                            Text("\(item.category) • \(item.seller)")
                                .font(.caption2)
                                .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                        }
                        Spacer()
                        Text("$\(item.priceUSD)")
                            .font(.subheadline.bold())
                            .foregroundStyle(BrandPalette.neonGreen)
                    }
                }
            }
        }
    }

    private var storeMeetUpPanel: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Meet Up")
                    .font(.headline)
                Text("Safe pickup plans, local meetups.")
                    .font(.caption)
                    .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                ForEach(appState.marketListings.prefix(6)) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title).font(.subheadline.bold())
                        Text("Pickup near \(appState.localCity) • \(item.seller)")
                            .font(.caption)
                            .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                        Button("Create meetup plan") {}
                            .buttonStyle(NeonPrimaryButtonStyle())
                    }
                }
            }
        }
    }

    private var storeLivePanel: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(appState.isLiveNow ? "LIVE" : "Offline",
                          systemImage: appState.isLiveNow ? "dot.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                        .font(.headline)
                        .foregroundStyle(appState.isLiveNow ? .red : BrandPalette.adaptiveTextSecondary(for: colorScheme))
                    Spacer()
                    Text("\(appState.liveViewerCount) viewers")
                        .font(.caption.bold())
                        .foregroundStyle(BrandPalette.neonGreen)
                }
                HStack(spacing: 8) {
                    Button(appState.isLiveNow ? "End Live" : "Go Live") {
                        if appState.isLiveNow { appState.endLiveSession() }
                        else { appState.startLiveSession(headline: "Store Live") }
                    }
                    .buttonStyle(NeonPrimaryButtonStyle())
                }
                if !appState.liveComments.isEmpty {
                    ForEach(appState.liveComments.prefix(8)) { c in
                        Text("\(c.authorHandle): \(c.text)").font(.caption)
                    }
                }
                HStack(spacing: 8) {
                    TextField("Add comment...", text: $liveCommentDraft)
                        .textFieldStyle(EliteTextFieldStyle())
                    Button("Send") {
                        appState.postLiveComment(liveCommentDraft)
                        liveCommentDraft = ""
                    }
                    .buttonStyle(NeonPrimaryButtonStyle())
                    .disabled(liveCommentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var storeDiscoverPanel: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Discover & more")
                    .font(.headline)
                Text("Explore products and local deals.")
                    .font(.caption)
                    .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
            }
        }
    }
}
