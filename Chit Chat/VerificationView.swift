import SwiftUI

struct VerificationView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var note = ""
    @State private var hasInstagramVerification = false
    @State private var wantPaidBadge = false
    @State private var submitted = false

    var body: some View {
        ZStack {
            EliteBackground()
            Form {
                Section("Requirements") {
                    Text("Official verification is internal-only and reviewed by your team.")
                    Text("Paid verification is public and marked as paid when tapped.")
                }
                .font(.footnote)
                .foregroundStyle(secondaryText)

                Section("Request") {
                    Toggle("Already verified on Instagram", isOn: $hasInstagramVerification)
                    Toggle("Buy paid verification badge", isOn: $wantPaidBadge)
                    TextField("Add profile details", text: $note, axis: .vertical)
                        .lineLimit(3...5)

                    Button("Submit verification request") {
                        if wantPaidBadge {
                            appState.requestPaidVerification()
                        }
                        appState.requestVerification(
                            note: note.isEmpty ? "No additional note" : note,
                            hasInstagramVerification: hasInstagramVerification
                        )
                        submitted = true
                        note = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BrandPalette.neonGreen)
                }

                Section("Current Status") {
                    Text(statusLine)
                        .foregroundStyle(primaryText)
                    Text("Request queue size: \(appState.verificationRequests.filter { $0.status == .pending }.count)")
                        .foregroundStyle(secondaryText)
                        .font(.caption)
                }

                if submitted {
                    Section {
                        Text("Request submitted. Paid badge updates instantly, official badge requires internal approval.")
                            .foregroundStyle(colorScheme == .light ? .green.opacity(0.85) : .green)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Verification")
    }

    private var primaryText: Color {
        colorScheme == .light ? .black : .white
    }

    private var secondaryText: Color {
        colorScheme == .light ? .black.opacity(0.72) : .white.opacity(0.82)
    }

    private var statusLine: String {
        switch appState.currentUser.verificationStatus {
        case .unverified:
            return "Status: Unverified"
        case .pending:
            return "Status: Pending review"
        case .paid:
            return "Status: Paid verification"
        case .verifiedInternal:
            return "Status: Officially verified"
        }
    }
}
