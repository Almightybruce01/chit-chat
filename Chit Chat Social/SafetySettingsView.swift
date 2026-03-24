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
                    Toggle("Violence / violent news — opaque warning before viewing", isOn: $requireViolenceConsent)
                }

                Section("Policy alerts email") {
                    TextField("Email for suspension & flags", text: Binding(
                        get: { appState.accountRecoveryEmail },
                        set: { appState.setAccountRecoveryEmail($0) }
                    ))
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    Text("Used for local stubs (see console) and future server sends. Turn on Email alerts in Activity settings.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.72))
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

                Section("AI monitoring") {
                    Text("Nude and sexual content: deleted immediately, account banned. First strike: 1 week. Escalation: 7 → 14 → 30 → 90 → 180 days.")
                    Text("Violent or disturbing news: viewers see an opaque full-screen warning. You can view or skip — your choice.")
                    Text("Policy actions trigger an email and in-app notification. Abuse-risk text may be held for review.")
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
