import Foundation
import UserNotifications

/// Schedules local notifications for trust & safety events (production also sends server email).
enum ModerationNotificationHelper {

    static func requestAuthorizationIfNeeded() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .notDetermined else { return }
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }
    }

    /// Immediate local alert (user must allow notifications in Settings).
    static func schedulePolicyAlert(title: String, body: String) {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.interruptionLevel = .timeSensitive
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
            let id = "chitchat.moderation.\(UUID().uuidString)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    /// Poster chose to publish content flagged as violent / disturbing news — viewers will see a warning first.
    static func scheduleViolencePostedNotice() {
        schedulePolicyAlert(
            title: "Post flagged — viewer warning",
            body: "AI monitoring marked this as potentially violent or disturbing news. Others will see an opaque warning before viewing."
        )
    }
}
