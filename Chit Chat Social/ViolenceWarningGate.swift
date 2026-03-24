import SwiftUI

/// Full-screen opaque overlay for posts flagged as violent news / graphic (viewer must opt in).
struct ViolenceWarningGate<Content: View>: View {
    let postID: UUID
    let isRequired: Bool
    @EnvironmentObject private var appState: AppState
    @AppStorage("requireViolenceConsent") private var requireViolenceConsent = true
    @ViewBuilder var content: () -> Content

    private var gateActive: Bool { isRequired && requireViolenceConsent }

    var body: some View {
        ZStack {
            content()

            if gateActive && appState.skipViolenceWarningActive(for: postID) {
                skippedCompactLayer
            }

            if gateActive && !appState.hasRevealedViolencePost(postID) && !appState.skipViolenceWarningActive(for: postID) {
                fullScreenWarningLayer
            }
        }
    }

    private var skippedCompactLayer: some View {
        VStack(spacing: 14) {
            Image(systemName: "eye.slash.fill")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.9))
            Text("Sensitive content hidden")
                .font(.headline)
                .foregroundStyle(.white)
            Text(
                "You chose not to view this. Violent or disturbing news stays behind this screen until you choose to open it."
            )
            .font(.caption)
            .multilineTextAlignment(.center)
            .foregroundStyle(.white.opacity(0.78))
            Button("View content") {
                appState.revealViolencePost(postID)
            }
            .buttonStyle(.borderedProminent)
            .tint(BrandPalette.neonBlue)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .padding(.horizontal, 12)
    }

    private var fullScreenWarningLayer: some View {
        ZStack {
            // Fully opaque — nothing visible behind. User must choose.
            Rectangle()
                .fill(Color.black)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(Color.orange)
                    .shadow(color: .black.opacity(0.5), radius: 8, y: 4)

                Text("Violent or disturbing content")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(
                    "AI monitoring flagged this as potentially graphic violence, injury, or violent news that may be upsetting. "
                        + "You can view it or skip — your choice."
                )
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.92))
                .padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 10) {
                    Label("May include real-world violence or casualties", systemImage: "exclamationmark.triangle.fill")
                    Label("You must choose to view or not", systemImage: "hand.raised.fill")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))

                HStack(spacing: 18) {
                    Button("Skip — don’t view") {
                        appState.skipViolenceWarningForPost(postID)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                    .font(.subheadline.weight(.medium))

                    Button("View content") {
                        appState.revealViolencePost(postID)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BrandPalette.neonBlue)
                    .font(.subheadline.weight(.semibold))
                }
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
        }
        .allowsHitTesting(true)
    }
}
