import SwiftUI

struct PrivacyControlView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            EliteBackground()
            Form {
                Section("Profile Modes") {
                    HStack {
                        Text("Social profile")
                        Spacer()
                        Text(appState.profileAvailabilityLabel(.social))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Corporate profile")
                        Spacer()
                        Text(appState.profileAvailabilityLabel(.enterprise))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Toggle("Social visible", isOn: Binding(
                        get: { appState.socialProfileVisible },
                        set: { _ in appState.toggleProfileVisibility(.social) }
                    ))
                    Toggle("Corporate visible", isOn: Binding(
                        get: { appState.corporateProfileVisible },
                        set: { _ in appState.toggleProfileVisibility(.enterprise) }
                    ))
                    if !appState.hasSocialProfile {
                        Button("Create Social profile") {
                            appState.addSecondaryProfile(.social)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    if !appState.hasCorporateProfile {
                        Button("Create Corporate profile") {
                            appState.addSecondaryProfile(.enterprise)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                Section("Default visibility") {
                    Picker("Post audience", selection: $appState.defaultPostAudience) {
                        ForEach(PostAudience.allCases, id: \.self) { audience in
                            Text(audience.rawValue).tag(audience)
                        }
                    }
                    Picker("Story audience", selection: $appState.defaultStoryAudience) {
                        ForEach(StoryAudience.allCases, id: \.self) { audience in
                            Text(audience.rawValue).tag(audience)
                        }
                    }
                }

                Section("Network controls") {
                    Toggle("Hide likes by default", isOn: $appState.hideLikeCountsByDefault)
                    Toggle("Hide comments by default", isOn: $appState.hideCommentCountsByDefault)
                }

                Section("Close friends") {
                    if appState.closeFriendsHandles.isEmpty {
                        Text("No close friends selected yet.")
                            .foregroundStyle(.white.opacity(0.75))
                    } else {
                        ForEach(Array(appState.closeFriendsHandles).sorted(), id: \.self) { handle in
                            HStack {
                                Text(handle)
                                Spacer()
                                Button("Remove") {
                                    appState.toggleCloseFriend(handle)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Privacy Controls")
    }
}
