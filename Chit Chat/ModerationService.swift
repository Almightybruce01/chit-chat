import Foundation

enum ModerationLabel: String {
    case safe
    case blockedNudity
    case violenceNeedsConsent
    case manualReview
}

struct ModerationResult {
    let label: ModerationLabel
    let reason: String
}

enum ModerationService {
    static func evaluate(caption: String, blockNudity: Bool) -> ModerationResult {
        let lowered = caption.lowercased()

        let nudityKeywords = ["nude", "nudity", "explicit", "nsfw"]
        let violenceKeywords = ["violent", "gore", "blood", "fight", "weapon"]
        let abuseRiskKeywords = ["hate", "kill", "abuse"]

        if blockNudity, nudityKeywords.contains(where: lowered.contains) {
            return ModerationResult(
                label: .blockedNudity,
                reason: "Blocked due to nudity safety policy."
            )
        }

        if violenceKeywords.contains(where: lowered.contains) {
            return ModerationResult(
                label: .violenceNeedsConsent,
                reason: "Marked as violent; consent warning required."
            )
        }

        if abuseRiskKeywords.contains(where: lowered.contains) {
            return ModerationResult(
                label: .manualReview,
                reason: "Sent to moderation queue for review."
            )
        }

        return ModerationResult(
            label: .safe,
            reason: "Content passed moderation."
        )
    }
}
