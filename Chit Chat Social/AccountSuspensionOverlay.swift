import SwiftUI

/// Blocks the app when the account is under an automatic policy suspension.
struct AccountSuspensionOverlay: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            Color.black.opacity(0.96).ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.orange)

                Text("Account suspended")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("Repeated policy violations (nude or sexual content) triggered an automatic suspension. First strike: 1 week ban. Escalation: 7 days → 14 → 30 → 90 → 180 days.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal)

                Text("Strike count: \(appState.moderationStrikeCount)")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(.white.opacity(0.75))

                if let remaining = appState.policySuspensionRemainingDescription {
                    Text(remaining)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(BrandPalette.neonBlue)
                }

                Text("Check your email for details. If this is a mistake, use in-app Support after the suspension lifts.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(24)
        }
    }
}
