import SwiftUI

struct IconHubView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("chitchat.appearance") private var appearanceRaw = AppAppearance.auto.rawValue
    @State private var showMusic = false
    @State private var showLive = false
    @State private var showShop = false
    @State private var showGroups = false
    @State private var showMarket = false
    @State private var showPulse = false
    @State private var showVerify = false
    @State private var showSafety = false
    @State private var showExecutionQueue = false
    @State private var showSuperEngine = false
    @State private var showAIStudio = false
    @State private var showLaunchSettings = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                EliteBackground()
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        hubButton("Music", "music.note", BrandPalette.neonBlue) { showMusic = true }
                        hubButton("Go Live", "dot.radiowaves.left.and.right", .orange) { showLive = true }
                        hubButton("Shop", "bag.fill", BrandPalette.neonGreen) { showShop = true }
                        hubButton("Groups", "person.3.fill", BrandPalette.accentPurple) { showGroups = true }
                        hubButton("Market", "storefront.fill", .mint) { showMarket = true }
                        hubButton("Pulse", "bolt.bubble.fill", .cyan) { showPulse = true }
                        hubButton("Verify", "checkmark.seal.fill", .yellow) { showVerify = true }
                        hubButton("Safety", "checkmark.shield.fill", .pink) { showSafety = true }
                        hubButton("1000 Queue", "checklist.unchecked", .teal) { showExecutionQueue = true }
                        hubButton("AI Studio", "sparkles.rectangle.stack.fill", .cyan) { showAIStudio = true }
                        hubButton("Settings", "gearshape.2.fill", .gray) { showLaunchSettings = true }
                        hubButton("Theme: \(appearanceLabel)", "circle.lefthalf.filled", .white) {
                            cycleAppearance()
                        }
                        hubButton("19000 Features", "infinity.circle.fill", .purple) { showSuperEngine = true }
                        hubButton(appState.mode == .social ? "Enterprise" : "Social", "arrow.triangle.2.circlepath.circle.fill", .indigo) {
                            appState.setMode(appState.mode == .social ? .enterprise : .social)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("All Features")
            .sheet(isPresented: $showMusic) { MusicHubView().environmentObject(appState) }
            .sheet(isPresented: $showLive) { NavigationStack { LiveStudioView().environmentObject(appState) } }
            .sheet(isPresented: $showShop) { NavigationStack { ShopHubView().environmentObject(appState) } }
            .sheet(isPresented: $showGroups) { NavigationStack { CommunitiesHubView().environmentObject(appState) } }
            .sheet(isPresented: $showMarket) { NavigationStack { SearchView().environmentObject(appState) } }
            .sheet(isPresented: $showPulse) { NavigationStack { PulseBoardView().environmentObject(appState) } }
            .sheet(isPresented: $showVerify) { NavigationStack { VerificationView().environmentObject(appState) } }
            .sheet(isPresented: $showSafety) { NavigationStack { SafetySettingsView().environmentObject(appState) } }
            .sheet(isPresented: $showExecutionQueue) { NavigationStack { ExecutionQueueView().environmentObject(appState) } }
            .sheet(isPresented: $showSuperEngine) { NavigationStack { SuperAppFeatureHubView().environmentObject(appState) } }
            .sheet(isPresented: $showAIStudio) { NavigationStack { AIStudioSetupView() } }
            .sheet(isPresented: $showLaunchSettings) { NavigationStack { LaunchSettingsView().environmentObject(appState) } }
        }
    }

    @ViewBuilder
    private func hubButton(_ title: String, _ icon: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 96)
            .background(BrandPalette.adaptiveCardBg(for: colorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(BrandPalette.adaptiveGlassStroke(for: colorScheme), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var appearanceLabel: String {
        switch AppAppearance(rawValue: appearanceRaw) ?? .system {
        case .system: return "System"
        case .auto: return "Auto Day/Night"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    private func cycleAppearance() {
        let order: [AppAppearance] = [.auto, .light, .dark, .system]
        let current = AppAppearance(rawValue: appearanceRaw) ?? .system
        let index = order.firstIndex(of: current) ?? 0
        let next = order[(index + 1) % order.count]
        appearanceRaw = next.rawValue
    }
}
