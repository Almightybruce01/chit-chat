import SwiftUI

/// Shown once after sign-in so users agree to community rules before accessing UGC (App Store Guideline 1.2).
struct CommunityTermsGateView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var didAccept: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                EliteBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Community standards")
                            .font(.title2.bold())
                            .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                        Text(
                            """
                            Chit Chat Social includes user-generated content. By continuing, you agree to our Terms of Use and Community Guidelines.

                            • There is zero tolerance for objectionable content, harassment, illegal activity, or abusive behavior.
                            • You can report posts and block users. Reported content is reviewed and we aim to act within 24 hours.
                            • Automated filters help block some harmful text before it is published; not all content can be caught automatically.
                            """
                        )
                        .font(.body)
                        .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                        if let terms = URL(string: "https://chitchat.app/terms") {
                            Link("Terms of Use", destination: terms)
                                .font(.subheadline.weight(.semibold))
                        }
                        if let privacy = URL(string: "https://chitchat.app/privacy") {
                            Link("Privacy Policy", destination: privacy)
                                .font(.subheadline.weight(.semibold))
                        }
                        Button {
                            didAccept = true
                        } label: {
                            Text("I agree — continue")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(NeonPrimaryButtonStyle())
                        .padding(.top, 8)
                    }
                    .padding(22)
                }
            }
            .navigationTitle("Before you continue")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
