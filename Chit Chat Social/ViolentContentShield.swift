import SwiftUI

/// Opaque overlay for posts flagged as potentially violent or disturbing (incl. violent news).
struct ViolentContentShield: View {
    let postID: UUID
    @Binding var revealedPostIDs: Set<UUID>

    var body: some View {
        if !revealedPostIDs.contains(postID) {
            ZStack {
                Color.black.opacity(0.94)

                VStack(spacing: 18) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(.orange.opacity(0.95))
                        .shadow(color: .black.opacity(0.35), radius: 8, y: 4)

                    Text("Sensitive content")
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Text("AI monitoring: this post may include graphic violence, injury, or disturbing news. You can view or skip — your choice.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.88))
                        .padding(.horizontal, 8)

                    VStack(spacing: 10) {
                        Button {
                            revealedPostIDs.insert(postID)
                        } label: {
                            Text("View content")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(BrandPalette.neonBlue)
                                .foregroundStyle(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Text("Not now — scroll past to skip.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .padding(.top, 4)
                }
                .padding(22)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Sensitive violent or news content. View or skip.")
        }
    }
}
