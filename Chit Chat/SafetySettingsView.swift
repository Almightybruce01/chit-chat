import SwiftUI

struct SafetySettingsView: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage("blockNudityContent") private var blockNudityContent = true
    @AppStorage("requireViolenceConsent") private var requireViolenceConsent = true
    @AppStorage("animatedUIEnabled") private var animatedUIEnabled = true
    @AppStorage("chitchat.appearance") private var appearanceRaw = AppAppearance.auto.rawValue

    var body: some View {
        ZStack {
            EliteBackground()
            Form {
                Section("Content Safety") {
                    Toggle("Block all nudity", isOn: $blockNudityContent)
                    Toggle("Violence requires consent warning", isOn: $requireViolenceConsent)
                }

                Section("Experience") {
                    Toggle("Extra animations", isOn: $animatedUIEnabled)
                    Picker("Appearance", selection: $appearanceRaw) {
                        Text("Auto Day/Night").tag(AppAppearance.auto.rawValue)
                        Text("Light").tag(AppAppearance.light.rawValue)
                        Text("Dark").tag(AppAppearance.dark.rawValue)
                        Text("System").tag(AppAppearance.system.rawValue)
                    }
                    Text("Auto uses light from 7AM-7PM and dark after sunset hours.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.72))
                }

                Section("Moderation AI") {
                    Text("Uploads are scanned for nudity, extreme violence, and abuse risk.")
                    Text("Flagged content is blocked or sent for human review.")
                }
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.82))

                Section("Recent moderation events") {
                    if appState.moderationEvents.isEmpty {
                        Text("No recent moderation events.")
                            .foregroundStyle(.white.opacity(0.72))
                    } else {
                        ForEach(appState.moderationEvents.prefix(6), id: \.self) { event in
                            Text(event)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Safety")
    }
}
