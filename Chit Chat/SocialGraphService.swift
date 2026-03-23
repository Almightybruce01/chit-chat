import Foundation

struct SuggestedProfile: Identifiable {
    let id = UUID()
    let handle: String
    let reason: String
}

enum SocialGraphService {
    static func peopleYouMayKnow() -> [SuggestedProfile] {
        [
            .init(handle: "@djmike", reason: "Mutuals + live music interests"),
            .init(handle: "@hoopcreator", reason: "High school / college sports network"),
            .init(handle: "@brandstarter", reason: "Creator-business collaboration match")
        ]
    }
}
