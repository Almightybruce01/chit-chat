import SwiftUI

enum SuperSourceApp: String, CaseIterable, Identifiable {
    case instagram, twitter, linkedin, facebook, snapchat, youtube, tiktok, discord, reddit, pinterest
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum SuperFeatureDomain: String, CaseIterable, Identifiable {
    case identity, feed, stories, reels, messaging, networking, jobs, commerce, ads, analytics
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum SuperFeatureTier: String, CaseIterable, Identifiable {
    case core, pro, enterprise, ai, automation, safety, growth, creator, team, global
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum SuperFeatureWave: String, CaseIterable, Identifiable {
    case prime
    case neo
    case ultra
    case apex
    case titan
    case omega
    case nova
    case quantum
    case infinity
    case singularity
    case omniverse
    case transcend
    case hypernova
    case ultranova
    case apexzero
    case ultimatum
    case godmode
    case aeon
    case zenith
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

struct SuperFeatureBlueprint: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let source: SuperSourceApp
    let domain: SuperFeatureDomain
    let tier: SuperFeatureTier
    let wave: SuperFeatureWave
    let score: Int
}

enum SuperFeatureCatalog {
    static func generateFeatures() -> [SuperFeatureBlueprint] {
        var items: [SuperFeatureBlueprint] = []
        items.reserveCapacity(19_000)
        for source in SuperSourceApp.allCases {
            for domain in SuperFeatureDomain.allCases {
                for tier in SuperFeatureTier.allCases {
                    for wave in SuperFeatureWave.allCases {
                        let id = "\(source.rawValue).\(domain.rawValue).\(tier.rawValue).\(wave.rawValue)"
                        let title = "\(source.label) \(domain.label) \(tier.label) \(wave.label) Stack"
                        let summary = summaryLine(source: source, domain: domain, tier: tier)
                        let bonus: Int = {
                            switch wave {
                            case .prime: return 0
                            case .neo: return 2
                            case .ultra: return 4
                            case .apex: return 6
                            case .titan: return 8
                            case .omega: return 10
                            case .nova: return 12
                            case .quantum: return 14
                            case .infinity: return 16
                            case .singularity: return 18
                            case .omniverse: return 20
                            case .transcend: return 22
                            case .hypernova: return 24
                            case .ultranova: return 26
                            case .apexzero: return 28
                            case .ultimatum: return 30
                            case .godmode: return 32
                            case .aeon: return 34
                            case .zenith: return 36
                            }
                        }()
                        let score = scoreValue(source: source, domain: domain, tier: tier) + bonus
                        items.append(
                            SuperFeatureBlueprint(
                                id: id,
                                title: title,
                                summary: summary,
                                source: source,
                                domain: domain,
                                tier: tier,
                                wave: wave,
                                score: score
                            )
                        )
                    }
                }
            }
        }
        return items
    }

    private static func summaryLine(source: SuperSourceApp, domain: SuperFeatureDomain, tier: SuperFeatureTier) -> String {
        "\(domain.label) flow inspired by \(source.label) with \(tier.label) capabilities for all-in-one operations."
    }

    private static func scoreValue(source: SuperSourceApp, domain: SuperFeatureDomain, tier: SuperFeatureTier) -> Int {
        let sourceBoost: [SuperSourceApp: Int] = [
            .instagram: 12, .twitter: 11, .linkedin: 10, .facebook: 9, .snapchat: 10,
            .youtube: 11, .tiktok: 12, .discord: 8, .reddit: 8, .pinterest: 7
        ]
        let domainBoost: [SuperFeatureDomain: Int] = [
            .identity: 8, .feed: 12, .stories: 11, .reels: 12, .messaging: 11,
            .networking: 10, .jobs: 9, .commerce: 10, .ads: 8, .analytics: 9
        ]
        let tierBoost: [SuperFeatureTier: Int] = [
            .core: 7, .pro: 8, .enterprise: 10, .ai: 11, .automation: 10,
            .safety: 9, .growth: 9, .creator: 8, .team: 8, .global: 8
        ]
        return (sourceBoost[source] ?? 0) + (domainBoost[domain] ?? 0) + (tierBoost[tier] ?? 0)
    }
}

struct SuperAppFeatureHubView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var query = ""
    @State private var selectedSource: SuperSourceApp?
    @State private var selectedDomain: SuperFeatureDomain?

    private var catalog: [SuperFeatureBlueprint] { appState.superFeatureCatalog }

    private var filtered: [SuperFeatureBlueprint] {
        catalog.filter { item in
            let searchPass: Bool
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                searchPass = true
            } else {
                searchPass = item.title.localizedCaseInsensitiveContains(query)
                    || item.summary.localizedCaseInsensitiveContains(query)
                    || item.id.localizedCaseInsensitiveContains(query)
            }

            let sourcePass = selectedSource == nil || item.source == selectedSource
            let domainPass = selectedDomain == nil || item.domain == selectedDomain
            return searchPass && sourcePass && domainPass
        }
        .sorted { lhs, rhs in
            if lhs.score == rhs.score { return lhs.title < rhs.title }
            return lhs.score > rhs.score
        }
    }

    var body: some View {
        ZStack {
            EliteBackground()
            VStack(spacing: 10) {
                topBar
                controls
                List {
                    Section("Active super-features: \(appState.enabledSuperFeatureCount) / \(catalog.count)") {
                        ForEach(filtered.prefix(200)) { feature in
                            featureRow(feature)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
        }
        .navigationTitle("Super Feature Engine")
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            TextField("Search modules", text: $query)
                .textFieldStyle(.roundedBorder)
            Button("Top 400") { appState.enableTopSuperFeatures(400) }
                .buttonStyle(.borderedProminent)
            Button("All \(catalog.count)") { appState.enableAllSuperFeatures() }
                .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private var controls: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip("All Apps", active: selectedSource == nil) { selectedSource = nil }
                    ForEach(SuperSourceApp.allCases) { source in
                        filterChip(source.label, active: selectedSource == source) { selectedSource = source }
                    }
                }
                .padding(.horizontal)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip("All Domains", active: selectedDomain == nil) { selectedDomain = nil }
                    ForEach(SuperFeatureDomain.allCases) { domain in
                        filterChip(domain.label, active: selectedDomain == domain) { selectedDomain = domain }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func featureRow(_ feature: SuperFeatureBlueprint) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(feature.title)
                    .font(.headline)
                    .foregroundStyle(primaryText)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { appState.isFeatureEnabled(feature.id) },
                    set: { _ in appState.toggleSuperFeature(feature.id) }
                ))
                .labelsHidden()
                .tint(BrandPalette.neonGreen)
            }
            Text(feature.summary)
                .font(.caption)
                .foregroundStyle(secondaryText)
            HStack(spacing: 8) {
                badge(feature.source.label)
                badge(feature.domain.label)
                badge(feature.tier.label)
                badge(feature.wave.label)
                badge("Score \(feature.score)")
            }
        }
        .listRowBackground(BrandPalette.cardBg.opacity(0.7))
    }

    @ViewBuilder
    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundStyle(primaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(BrandPalette.bgMid.opacity(0.65))
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func filterChip(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(active ? BrandPalette.neonBlue : secondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(active ? BrandPalette.neonBlue.opacity(0.16) : BrandPalette.cardBg.opacity(0.7))
                )
                .overlay(Capsule().stroke(BrandPalette.glassStroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var primaryText: Color {
        BrandPalette.adaptiveTextPrimary(for: colorScheme)
    }

    private var secondaryText: Color {
        BrandPalette.adaptiveTextSecondary(for: colorScheme)
    }
}
