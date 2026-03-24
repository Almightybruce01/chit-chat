import Foundation

protocol BackendServicing {
    func syncUserProfile(_ profile: UserProfile) async throws
    func syncPost(_ post: PostItem) async throws
    func logModerationEvent(_ message: String) async throws
    /// Stub: production sends via SendGrid / SES / Firebase extension. Logs locally for QA.
    func sendModerationEmail(toEmail: String, subject: String, body: String) async throws
}

final class LocalBackendService: BackendServicing {
    private let queue = DispatchQueue(label: "LocalBackendService.queue")

    func syncUserProfile(_ profile: UserProfile) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                UserDefaults.standard.set(profile.username, forKey: "lastSyncedUsername")
                UserDefaults.standard.set(profile.handle, forKey: "lastSyncedHandle")
                UserDefaults.standard.set(profile.displayName, forKey: "lastSyncedDisplayName")
                UserDefaults.standard.set(profile.followers, forKey: "lastSyncedFollowers")
                UserDefaults.standard.set(profile.verificationStatus.rawValue, forKey: "lastSyncedVerificationStatus")
                continuation.resume(returning: ())
            }
        }
    }

    func syncPost(_ post: PostItem) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                UserDefaults.standard.set(post.caption, forKey: "lastSyncedPostCaption")
                UserDefaults.standard.set(post.type.rawValue, forKey: "lastSyncedPostType")
                UserDefaults.standard.set(post.authorHandle, forKey: "lastSyncedPostAuthor")
                continuation.resume(returning: ())
            }
        }
    }

    func logModerationEvent(_ message: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                UserDefaults.standard.set(message, forKey: "lastModerationEvent")
                continuation.resume(returning: ())
            }
        }
    }

    func sendModerationEmail(toEmail: String, subject: String, body: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let stamp = ISO8601DateFormatter().string(from: Date())
                let payload = "[\(stamp)] To: \(toEmail)\nSubject: \(subject)\n\n\(body)"
                UserDefaults.standard.set(payload, forKey: "lastModerationEmailPayload")
                if let data = payload.data(using: .utf8) {
                    UserDefaults.standard.set(data, forKey: "lastModerationEmailData")
                }
                print("📧 Moderation email (local stub)\n\(payload)")
                continuation.resume(returning: ())
            }
        }
    }
}
