//
//  DeleteAccountView.swift
//  Chit Chat Social
//

import SwiftUI

/// In-app account deletion (Guideline 5.1.1(v)) — permanent, not deactivation.
struct DeleteAccountView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss

    @State private var confirmText = ""
    @State private var password = ""
    @State private var isDeleting = false
    @State private var errorMessage = ""
    @State private var showFinalConfirm = false

    private var needsPassword: Bool {
        appState.currentAccountUsesPasswordProvider
    }

    private var canSubmit: Bool {
        confirmText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "DELETE"
        && (!needsPassword || password.count >= 8)
        && !isDeleting
    }

    var body: some View {
        ZStack {
            EliteBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Label("Permanent account deletion", systemImage: "person.crop.circle.badge.minus")
                        .font(.title3.bold())
                        .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))

                    Text("This permanently deletes your Chit Chat Social account and removes your profile, posts saved on this device, and linked sign-in from our servers. This cannot be undone.")
                        .font(.subheadline)
                        .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("What will be deleted")
                            .font(.headline)
                        bullet("Profile, @handle, and contact info")
                        bullet("Device-stored posts, saves, and profile media")
                        bullet("Firebase sign-in for this account")
                    }
                    .padding(14)
                    .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    if needsPassword {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Confirm with your password")
                                .font(.subheadline.bold())
                            SecureField("Account password", text: $password)
                                .textContentType(.password)
                                .padding(12)
                                .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    } else {
                        Text("If you use Sign in with Apple or Google, you may need to sign out, sign in again, then return here if deletion asks for a recent login.")
                            .font(.caption)
                            .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Type DELETE to confirm")
                            .font(.subheadline.bold())
                        TextField("DELETE", text: $confirmText)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .padding(12)
                            .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    Button(role: .destructive) {
                        showFinalConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            if isDeleting {
                                ProgressView()
                            } else {
                                Text("Delete my account permanently")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(!canSubmit)
                }
                .padding(LayoutTokens.cardPadding)
                .frame(maxWidth: horizontalSizeClass == .regular ? LayoutTokens.iPadReadableMaxWidth : LayoutTokens.readableMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, horizontalSizeClass == .regular ? LayoutTokens.iPadScreenHorizontal : LayoutTokens.screenHorizontal)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Delete account")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete account permanently?",
            isPresented: $showFinalConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete permanently", role: .destructive) {
                Task { await performDeletion() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your account and associated data will be removed. This action cannot be undone.")
        }
    }

    @ViewBuilder
    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
                .font(.subheadline)
        }
        .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
    }

    private func performDeletion() async {
        errorMessage = ""
        isDeleting = true
        defer { isDeleting = false }
        let result = await appState.deleteCurrentAccount(password: password.isEmpty ? nil : password)
        if let result {
            errorMessage = result
        } else {
            dismiss()
        }
    }
}
