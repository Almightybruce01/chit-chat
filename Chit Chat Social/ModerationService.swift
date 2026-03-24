import Foundation

enum ModerationLabel: String {
    case safe
    /// Nudity, sexual content, or explicit adult material — content must not be published.
    case blockedNudity
    /// Graphic violence or violent news — may publish with viewer consent overlay.
    case violenceNeedsConsent
    case manualReview
    /// Client-side validation (e.g. reel without video) — do not publish.
    case missingRequiredMedia
    /// Account is suspended (policy) — do not publish or send.
    case accountSuspended
}

struct ModerationResult {
    let label: ModerationLabel
    let reason: String
}

/// **AI monitoring**: text + media signals. Nudity/sex → content deleted, account banned (1 week, escalating).
/// Production adds vision / server classifiers for images & video.
enum ModerationService {

    // MARK: - Keyword sets

    private static let nudityKeywords: [String] = [
        "nude", "nudity", "nudes", "naked", "topless", "nsfw", "explicit", "bare skin", "undress", "strip tease",
        "striptease", "nipple", "no clothes", "unclothed", "lewd", "no underwear", "bare chest",
        "bikini reveal", "full nude", "fully nude", "nude pic", "nude photo", "no shirt", "exposed"
    ]

    private static let sexualKeywords: [String] = [
        "sexual", "porn", "porno", "erotic", "masturbat", "orgasm", "intercourse",
        "genital", "penis", "vagina", "onlyfans", "hookup", "escort", "fetish", "blow job", "blowjob",
        "deepfake", "deep fake", "child porn", "cp ", "rape", "molest", "incest", "hentai", "camgirl",
        "cam girl", "sugar daddy", "sugar baby", "xxx", "adult content", "sex tape", "sexting",
        "dm for nudes", "selling nudes", "nudes for sale", "dick pic", "dickpic", "pussy", "cum",
        "hardcore", "softcore", "xxx content", "adult only", "18+ only", "nsfw content"
    ]

    /// Whole-word / short-token patterns (avoids substring false positives where possible).
    private static let sexualRegexPatterns: [String] = [
        "\\bsex\\b",
        "\\bsexting\\b",
        "\\bporn\\b",
        "\\bnsfw\\b",
        "\\bxxx\\b",
        "\\bdm for nudes\\b",
        "\\bnudes?\\b"
    ]

    /// Violence + violent news / breaking coverage (text signals only in MVP).
    private static let violenceKeywords: [String] = [
        "violent", "violence", "gore", "gory", "blood", "bloody", "weapon", "shooting", "shooter",
        "murder", "massacre", "bombing", "terror", "behead", "casualties", "casualty", "killed",
        "attack", "assault", "execution", "graphic", "dismember", "torture", "war crime", "hostage",
        "genocide", "school shooting", "mass shooting", "IED", "decapitat", "mutilat"
    ]

    private static let newsViolenceHints: [String] = [
        "breaking", "reported dead", "fatal", "fatalities", "breaking news", "developing story",
        "live coverage", "death toll", "active shooter", "lockdown"
    ]

    private static let abuseRiskKeywords: [String] = [
        "hate", "kill yourself", "kys", "abuse", "lynch"
    ]

    // MARK: - Public API

    /// AI monitoring: **nudity and sexual content are always blocked** for publishing (ignore `blockNudity` for policy).
    /// `blockNudity` is kept for API compatibility; text policy is always strict.
    static func evaluate(caption: String, blockNudity: Bool = true) -> ModerationResult {
        _ = blockNudity // Reserved for future media / optional strictness; text policy is always strict.
        let lowered = caption.lowercased()

        if containsNudityOrSexual(lowered) {
            return ModerationResult(
                label: .blockedNudity,
                reason: "AI monitoring: sexual or nudity content is not allowed. Content deleted; account strike applied."
            )
        }

        if containsAny(lowered, abuseRiskKeywords) {
            return ModerationResult(
                label: .manualReview,
                reason: "Held for safety review (abuse risk)."
            )
        }

        let violenceHit = containsAny(lowered, violenceKeywords)
        let newsViolenceHit = containsAny(lowered, newsViolenceHints) && (
            containsAny(lowered, violenceKeywords) || lowered.contains("dead") || lowered.contains("shoot")
        )

        if violenceHit || newsViolenceHit {
            return ModerationResult(
                label: .violenceNeedsConsent,
                reason: "This post may show violent or disturbing news imagery. Viewers will see a warning."
            )
        }

        return ModerationResult(
            label: .safe,
            reason: "Content passed moderation."
        )
    }

    /// AI monitoring for images/video (MVP: always safe; production: wire to vision API).
    static func evaluateMedia(imageData: Data?, videoData: Data?) -> ModerationResult {
        // Production: send to cloud vision / on-device classifier for nudity/sex detection.
        // If flagged → return .blockedNudity.
        _ = imageData
        _ = videoData
        return ModerationResult(label: .safe, reason: "Media passed moderation.")
    }

    private static func containsNudityOrSexual(_ lowered: String) -> Bool {
        if containsAny(lowered, nudityKeywords) { return true }
        if containsAny(lowered, sexualKeywords) { return true }
        for pattern in sexualRegexPatterns {
            if lowered.range(of: pattern, options: .regularExpression) != nil { return true }
        }
        return false
    }

    private static func containsAny(_ text: String, _ keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
}
