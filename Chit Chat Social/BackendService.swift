import Foundation

protocol BackendServicing {
    func syncUserProfile(_ profile: UserProfile) async throws
    func syncPost(_ post: PostItem) async throws
    func logModerationEvent(_ message: String) async throws
    /// Stub: production sends via SendGrid / SES / Firebase extension. Logs locally for QA.
    func sendModerationEmail(toEmail: String, subject: String, body: String) async throws
    /// Production: transactional email with one-time code. Local stub records the payload (no real SMTP from the app binary alone).
    func sendPasswordResetCode(toEmail: String, username: String, code: String, validMinutes: Int) async throws
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
                UserDefaults.standard.set(post.isSponsoredAd, forKey: "lastSyncedPostSponsored")
                UserDefaults.standard.set(post.sponsorBrandHandle, forKey: "lastSyncedSponsorBrandHandle")
                UserDefaults.standard.set(post.sponsorExternalURL, forKey: "lastSyncedSponsorExternalURL")
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

    func sendPasswordResetCode(toEmail: String, username: String, code: String, validMinutes: Int) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let stamp = ISO8601DateFormatter().string(from: Date())
                let subject = "Chit Chat Social password reset code"
                let body = """
                Username: \(username)

                Your one-time password reset code is: \(code)

                It expires in \(validMinutes) minutes. If you didn’t request this, ignore this message.

                (Local/dev builds store this text in UserDefaults under lastPasswordResetEmailPayload — wire production to your real mail provider.)
                """
                let payload = "[\(stamp)] To: \(toEmail)\nSubject: \(subject)\n\n\(body)"
                UserDefaults.standard.set(payload, forKey: "lastPasswordResetEmailPayload")
                if let data = payload.data(using: .utf8) {
                    UserDefaults.standard.set(data, forKey: "lastPasswordResetEmailData")
                }
                print("📧 Password reset email (local stub)\n\(payload)")
                continuation.resume(returning: ())
            }
        }
    }
}
