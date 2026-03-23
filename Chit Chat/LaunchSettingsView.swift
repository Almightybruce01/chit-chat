import SwiftUI

struct LaunchSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("chitchat.appearance") private var appearanceRaw = AppAppearance.auto.rawValue
    @AppStorage("playStartupSounds") private var playStartupSounds = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true

    @State private var primaryMode: PlatformMode = .social

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                architectureCard
                visibilityCard
                dataSourceCard
                launchExperienceCard
                undoQueueCard
                linkedSettingsCard
            }
            .padding()
        }
        .background(EliteBackground())
        .navigationTitle("Launch Settings")
        .onAppear {
            primaryMode = appState.mode
        }
    }

    @ViewBuilder
    private var architectureCard: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Profile Architecture")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(primaryText)
                Text("Run social and corporate profiles independently. Keep one hidden or create a second profile later.")
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)

                Picker("Primary mode", selection: $primaryMode) {
                    Text("Social").tag(PlatformMode.social)
                    Text("Corporate").tag(PlatformMode.enterprise)
                }
                .pickerStyle(.segmented)
                .onChange(of: primaryMode) { _, newMode in
                    appState.setMode(newMode)
                }

                HStack(spacing: 10) {
                    Button("Add Social Profile") {
                        appState.addSecondaryProfile(.social)
                    }
                    .buttonStyle(.bordered)
                    .disabled(appState.hasSocialProfile)

                    Button("Add Corporate Profile") {
                        appState.addSecondaryProfile(.enterprise)
                    }
                    .buttonStyle(.bordered)
                    .disabled(appState.hasCorporateProfile)
                }
            }
        }
    }

    @ViewBuilder
    private var visibilityCard: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Profile Visibility")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(primaryText)
                Text("Control public visibility per profile, independent of active mode.")
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)

                visibilityRow(mode: .social, label: "Social Profile")
                visibilityRow(mode: .enterprise, label: "Corporate Profile")
            }
        }
    }

    @ViewBuilder
    private func visibilityRow(mode: PlatformMode, label: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryText)
                Text(appState.profileAvailabilityLabel(mode))
                    .font(.caption)
                    .foregroundStyle(secondaryText)
            }
            Spacer()
            Button(appState.isProfileVisible(mode) ? "Hide" : "Show") {
                appState.toggleProfileVisibility(mode)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!(mode == .social ? appState.hasSocialProfile : appState.hasCorporateProfile))
        }
        .padding(10)
        .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var dataSourceCard: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Data Source")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(primaryText)
                HStack {
                    Label(
                        appState.isUsingLiveDataBackend ? "Live sync enabled" : "Demo/local mode",
                        systemImage: appState.isUsingLiveDataBackend ? "dot.radiowaves.left.and.right" : "externaldrive.badge.clock"
                    )
                    .foregroundStyle(appState.isUsingLiveDataBackend ? BrandPalette.neonGreen : secondaryText)
                    Spacer()
                }
                Text(appState.backendStatusLabel)
                    .font(.caption)
                    .foregroundStyle(secondaryText)
                Text("Auth can use Firebase, but feed/chat/story data currently runs from local app state unless a live backend service is wired.")
                    .font(.caption2)
                    .foregroundStyle(secondaryText)
            }
        }
    }

    @ViewBuilder
    private var launchExperienceCard: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("First Impression")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(primaryText)
                Picker("Appearance", selection: $appearanceRaw) {
                    ForEach(AppAppearance.allCases, id: \.rawValue) { appearance in
                        Text(appearanceLabel(appearance)).tag(appearance.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Play startup sound", isOn: $playStartupSounds)
                    .foregroundStyle(primaryText)

                Button("Replay onboarding flow") {
                    hasSeenOnboarding = false
                }
                .buttonStyle(.bordered)
            }
        }
    }

    @ViewBuilder
    private var undoQueueCard: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Undo Queue")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(primaryText)
                Text("Global safety net for recent destructive actions.")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
                HStack {
                    Text("Queued actions: \(appState.undoQueueCount)")
                        .font(.subheadline)
                        .foregroundStyle(primaryText)
                    Spacer()
                    if appState.undoQueueCount > 0 {
                        Button("Undo Latest") {
                            _ = appState.undoLatestAction()
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Clear") {
                            appState.clearUndoQueue()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                if !appState.latestUndoLabel.isEmpty {
                    Text("Latest: \(appState.latestUndoLabel)")
                        .font(.caption2)
                        .foregroundStyle(secondaryText)
                }
            }
        }
    }

    @ViewBuilder
    private var linkedSettingsCard: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Deep Settings")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(primaryText)
                NavigationLink(destination: NotificationSettingsView().environmentObject(appState)) {
                    Label("Notification Settings", systemImage: "bell.badge.fill")
                        .foregroundStyle(primaryText)
                }
                NavigationLink(destination: PrivacyControlView().environmentObject(appState)) {
                    Label("Privacy Controls", systemImage: "hand.raised.fill")
                        .foregroundStyle(primaryText)
                }
                NavigationLink(destination: SafetySettingsView().environmentObject(appState)) {
                    Label("Safety Settings", systemImage: "checkmark.shield.fill")
                        .foregroundStyle(primaryText)
                }
                NavigationLink(destination: SocialLinksView().environmentObject(appState)) {
                    Label("Connected Platforms", systemImage: "link")
                        .foregroundStyle(primaryText)
                }
            }
        }
    }

    private func appearanceLabel(_ appearance: AppAppearance) -> String {
        switch appearance {
        case .system: return "System"
        case .auto: return "Auto"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    private var primaryText: Color {
        BrandPalette.adaptiveTextPrimary(for: colorScheme)
    }

    private var secondaryText: Color {
        BrandPalette.adaptiveTextSecondary(for: colorScheme)
    }
}
