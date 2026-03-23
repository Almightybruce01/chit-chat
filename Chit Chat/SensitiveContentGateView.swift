import SwiftUI

struct SensitiveContentGateView: View {
    @AppStorage("requireViolenceConsent") private var requireViolenceConsent = true
    @State private var hasConsented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sensitive Content")
                .font(.headline)
            Text("This content may include violence. Tap consent to continue.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !requireViolenceConsent || hasConsented {
                Text("Content unlocked for this session.")
                    .foregroundStyle(.green)
            } else {
                Button("I Consent to View") {
                    hasConsented = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
