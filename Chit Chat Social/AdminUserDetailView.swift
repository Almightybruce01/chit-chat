import SwiftUI

/// Per-user admin controls: official vs paid badge, handoff email, rename, delete.
struct AdminUserDetailView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let profile: UserProfile

    @State private var renameDraft: String
    @State private var handoffEmailDraft: String
    @State private var feedback: String?
    @State private var pendingDelete = false

    init(profile: UserProfile) {
        self.profile = profile
        _renameDraft = State(initialValue: profile.username)
        _handoffEmailDraft = State(initialValue: ReservedHandles.handoffEmail(forUsername: profile.username) ?? "")
    }

    private var live: UserProfile {
        appState.internalUsers.first(where: { $0.id == profile.id }) ?? profile
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(live.displayName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(primary)
                    Text(live.handle)
                        .font(.subheadline)
                        .foregroundStyle(secondary)
                    Text(badgeExplanation(for: live))
                        .font(.caption)
                        .foregroundStyle(secondary)
                }
                .listRowBackground(Color.clear)
            }

            if let feedback {
                Section {
                    Text(feedback)
                        .font(.caption)
                        .foregroundStyle(primary)
                }
            }

            Section("Official verification (real internal badge)") {
                Text("Official verified is the only badge that should represent your in-app trust team approval. Paid badge is labeled separately in the profile.")
                    .font(.caption)
                    .foregroundStyle(secondary)
                Button("Grant official verified") {
                    appState.grantInternalVerification(userID: profile.id)
                    feedback = "Granted official verified."
                }
                .buttonStyle(.borderedProminent)
                .disabled(live.verificationStatus == .verifiedInternal)

                Button("Remove official / clear to unverified") {
                    appState.adminSetVerificationForUser(userID: profile.id, status: .unverified)
                    feedback = "Cleared verification state."
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }

            Section("Paid badge (separate from official)") {
                Button("Set paid badge") {
                    appState.adminSetVerificationForUser(userID: profile.id, status: .paid)
                    feedback = "Set to paid badge."
                }
                .buttonStyle(.bordered)
                Button("Remove paid badge") {
                    appState.adminSetVerificationForUser(userID: profile.id, status: .unverified)
                    feedback = "Removed paid badge."
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            }

            Section("Username & takeover note") {
                TextField("Username", text: $renameDraft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Save username") {
                    if let err = appState.adminRenameUser(userID: profile.id, rawUsername: renameDraft) {
                        feedback = err
                    } else {
                        feedback = "Username updated."
                    }
                }
                .buttonStyle(.borderedProminent)

                Text("Optional: intended owner email (local note only — not legal ID proof).")
                    .font(.caption)
                    .foregroundStyle(secondary)
                TextField("Email for handoff", text: $handoffEmailDraft)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                Button("Save handoff email") {
                    ReservedHandles.setHandoffEmail(forUsername: live.username, email: handoffEmailDraft)
                    feedback = "Handoff note saved."
                }
                .buttonStyle(.bordered)
            }

            Section {
                Button("Delete user from directory", role: .destructive) {
                    pendingDelete = true
                }
                .disabled(profile.id == appState.currentUser.id)
            } footer: {
                Text("Deletes local profile, login, holds, and handoff note for this username. Does not delete Firebase Auth.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(EliteBackground())
        .navigationTitle(live.username)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let u = appState.internalUsers.first(where: { $0.id == profile.id }) {
                renameDraft = u.username
                handoffEmailDraft = ReservedHandles.handoffEmail(forUsername: u.username) ?? ""
            }
        }
        .confirmationDialog("Delete \(profile.handle)?", isPresented: $pendingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                appState.adminDeleteInternalUser(id: profile.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Removes this account from the local directory.")
        }
    }

    private func badgeExplanation(for user: UserProfile) -> String {
        switch user.verificationStatus {
        case .verifiedInternal:
            return "Current: Official verified (internal trust badge)"
        case .paid:
            return "Current: Paid badge (not the same as official)"
        case .pending:
            return "Current: Pending verification"
        case .unverified:
            return "Current: Not verified"
        }
    }

    private var primary: Color {
        colorScheme == .light ? .black : .white
    }

    private var secondary: Color {
        colorScheme == .light ? .black.opacity(0.72) : .white.opacity(0.78)
    }
}
