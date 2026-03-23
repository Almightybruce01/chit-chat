import SwiftUI
import Foundation

struct NotificationSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            EliteBackground()
            Form {
                Section("Delivery") {
                    Toggle("Push notifications", isOn: $appState.notificationsEnabled)
                    Toggle("Email alerts", isOn: $appState.emailAlertsEnabled)
                    Toggle("Quiet hours", isOn: $appState.quietHoursEnabled)
                    if appState.quietHoursEnabled {
                        Picker("Start hour", selection: $appState.quietHoursStart) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(label(hour)).tag(hour)
                            }
                        }
                        Picker("End hour", selection: $appState.quietHoursEnd) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(label(hour)).tag(hour)
                            }
                        }
                    }
                }

                Section("Mute activity types") {
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        Toggle(typeLabel(type), isOn: Binding(
                            get: { appState.mutedActivityTypes.contains(type) },
                            set: { _ in appState.toggleMutedActivityType(type) }
                        ))
                    }
                }

                Section("Unread") {
                    HStack {
                        Text("Unread count")
                        Spacer()
                        Text("\(appState.unreadActivityCount)")
                            .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                    }
                    Button("Mark all activity read") {
                        appState.markAllActivityRead()
                    }
                    .buttonStyle(NeonPrimaryButtonStyle())
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Notifications")
    }

    private func typeLabel(_ type: ActivityType) -> String {
        switch type {
        case .like: return "Likes"
        case .comment: return "Comments"
        case .follow: return "Follows"
        case .repost: return "Reposts"
        case .save: return "Saves"
        case .message: return "Messages"
        case .verification: return "Verification"
        }
    }

    private func label(_ hour: Int) -> String {
        String(format: "%02d:00", hour)
    }
}
