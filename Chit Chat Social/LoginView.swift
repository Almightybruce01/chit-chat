//
//  LoginView.swift
//  Chit Chat Social
//
//  Created by Brian Bruce on 2025-06-24.
//

import SwiftUI
import UIKit
import AuthenticationServices
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import CryptoKit

private enum AuthMode: String, CaseIterable {
    case signUp = "Sign Up"
    case logIn = "Log In"
}

private enum AccountPortal: String, CaseIterable, Identifiable {
    case social = "Social"
    case business = "Business"
    var id: String { rawValue }
}

private enum ForgotPasswordPhase {
    case requestCode
    case enterNewPassword
}

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingProviderAlert = false
    @State private var providerMessage = ""
    @State private var username = ""
    @State private var password = ""
    @State private var wantsUpdateEmails = true
    @State private var showMoreOptions = false
    @State private var authMode: AuthMode = .logIn
    @State private var currentNonce: String?
    @State private var accountPortal: AccountPortal = .social
    /// Shown for creator sign-up; corporate mode still uses real name for jobs / EIN flow.
    @State private var personalRealName = ""
    // Business registration (required for business sign-up)
    @State private var businessEIN = ""
    @State private var businessLegalName = ""
    @State private var businessDBA = ""
    @State private var businessAddress = ""
    @State private var businessCity = ""
    @State private var businessState = ""
    @State private var businessZIP = ""
    @State private var businessPhone = ""
    @State private var businessWebsite = ""
    @State private var signUpEmail = ""
    @State private var loginEmail = ""
    @State private var signUpPhone = ""
    @State private var showForgotPassword = false
    @State private var forgotUsername = ""
    @State private var forgotEmail = ""
    @State private var forgotNewPassword = ""
    @State private var forgotConfirmPassword = ""
    @State private var forgotStatus = ""
    @State private var forgotPhase = ForgotPasswordPhase.requestCode
    @State private var forgotCode = ""
    @State private var forgotSendingCode = false

    var body: some View {
        ZStack {
            EliteBackground()
            ScrollView {
                VStack(spacing: 16) {
                    AppLogoView(size: 150, cornerRadius: 20)
                        .padding(.top, 30)

                    Text(accountPortal == .social ? "Chit Chat Social" : "Chit Chat Corporate")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(portalAccent)

                    Text(portalSubtitle)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(secondaryText)
                        .padding(.horizontal, 8)

                    accountPortalToggle
                        .padding(.vertical, 4)

                    launchQualityStrip

                    EliteCard {
                        VStack(alignment: .leading, spacing: 12) {
                            FuturisticSectionHeader(
                                title: authMode == .signUp ? portalSignUpTitle : portalLoginTitle,
                                subtitle: portalCardSubtitle
                            )
                            Picker("Auth mode", selection: $authMode) {
                                ForEach(AuthMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)

                            Group {
                                if authMode == .logIn {
                                    Text("Email (password sign-in)")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(primaryText)
                                    TextField("you@email.com", text: $loginEmail)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .keyboardType(.emailAddress)
                                        .padding(10)
                                        .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.8))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .foregroundStyle(primaryText)
                                }
                                Text(authMode == .logIn ? "Username — required for Google / Apple" : "Username — your @handle on the social side")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(primaryText)
                                TextField(authMode == .logIn ? "Your @handle" : "Unique username (required)", text: $username)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .padding(10)
                                    .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.8))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .foregroundStyle(primaryText)
                                SecureField("Password (8+ characters)", text: $password)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .padding(10)
                                    .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.8))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .foregroundStyle(primaryText)
                            }

                            if authMode == .signUp {
                                Text("Email (required)")
                                    .font(.caption.bold())
                                    .foregroundStyle(secondaryText)
                                TextField("you@email.com", text: $signUpEmail)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.emailAddress)
                                    .padding(10)
                                    .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.85))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .foregroundStyle(primaryText)
                                if accountPortal == .social {
                                    Text("Mobile phone (optional)")
                                        .font(.caption.bold())
                                        .foregroundStyle(secondaryText)
                                    TextField("Add for recovery, or leave blank", text: $signUpPhone)
                                        .keyboardType(.phonePad)
                                        .padding(10)
                                        .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.85))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .foregroundStyle(primaryText)
                                } else {
                                    Text("Business phone is required in the entity section below; it becomes your account phone.")
                                        .font(.caption2)
                                        .foregroundStyle(secondaryText)
                                }
                            }

                            if authMode == .signUp && accountPortal == .social {
                                Text("Real name (optional)")
                                    .font(.caption.bold())
                                    .foregroundStyle(secondaryText)
                                TextField("How you appear in Corporate / jobs", text: $personalRealName)
                                    .textInputAutocapitalization(.words)
                                    .padding(10)
                                    .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.85))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .foregroundStyle(primaryText)
                                Text("You get both Social and Corporate workspaces. Social shows your username; Corporate uses this name when you browse jobs.")
                                    .font(.caption2)
                                    .foregroundStyle(secondaryText)
                            }

                            if authMode == .signUp && accountPortal == .business {
                                Text("Business & tax identity")
                                    .font(.headline)
                                    .foregroundStyle(primaryText)
                                TextField("EIN — 9 digits (e.g. 12-3456789)", text: $businessEIN)
                                    .keyboardType(.numbersAndPunctuation)
                                    .padding(10)
                                    .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.85))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .foregroundStyle(primaryText)
                                TextField("Legal entity name (required)", text: $businessLegalName)
                                    .textInputAutocapitalization(.words)
                                    .padding(10)
                                    .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.85))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .foregroundStyle(primaryText)
                                TextField("DBA / trade name (optional)", text: $businessDBA)
                                    .textInputAutocapitalization(.words)
                                    .padding(10)
                                    .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.85))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .foregroundStyle(primaryText)
                                TextField("Street address", text: $businessAddress)
                                    .textInputAutocapitalization(.words)
                                    .padding(10)
                                    .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.85))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .foregroundStyle(primaryText)
                                HStack(spacing: 8) {
                                    TextField("City", text: $businessCity)
                                        .textInputAutocapitalization(.words)
                                        .padding(10)
                                        .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.85))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .foregroundStyle(primaryText)
                                    TextField("ST", text: $businessState)
                                        .textInputAutocapitalization(.characters)
                                        .autocorrectionDisabled()
                                        .padding(10)
                                        .frame(width: 56)
                                        .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.85))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .foregroundStyle(primaryText)
                                    TextField("ZIP", text: $businessZIP)
                                        .keyboardType(.numbersAndPunctuation)
                                        .padding(10)
                                        .frame(minWidth: 72)
                                        .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.85))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .foregroundStyle(primaryText)
                                }
                                TextField("Business phone", text: $businessPhone)
                                    .keyboardType(.phonePad)
                                    .padding(10)
                                    .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.85))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .foregroundStyle(primaryText)
                                TextField("Website https://… (optional)", text: $businessWebsite)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .padding(10)
                                    .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.85))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .foregroundStyle(primaryText)
                                Text("Your username is still your public @handle for reels and DMs. Corporate surfaces use your legal / DBA name.")
                                    .font(.caption2)
                                    .foregroundStyle(secondaryText)
                            }

                            Toggle("Product update emails", isOn: $wantsUpdateEmails)
                                .foregroundStyle(primaryText)

                            Text("Everyone gets Social + Corporate. Switch modes anytime after sign-in.")
                                .font(.caption)
                                .foregroundStyle(secondaryText)

                            Button(authMode == .signUp ? "Create account" : "Log in") {
                                primaryAuthAction()
                            }
                            .buttonStyle(NeonPrimaryButtonStyle())
                            .frame(maxWidth: .infinity, alignment: .center)
                            if authMode == .logIn {
                                Button("Forgot password?") {
                                    forgotStatus = ""
                                    forgotPhase = .requestCode
                                    forgotCode = ""
                                    forgotUsername = username
                                    forgotEmail = loginEmail
                                    forgotNewPassword = ""
                                    forgotConfirmPassword = ""
                                    forgotSendingCode = false
                                    showForgotPassword = true
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(BrandPalette.neonBlue)
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }

                    Button(action: googleLogin) {
                        authButtonLabel(title: "Continue with Google", icon: "globe")
                    }
                    if !thirdPartyAuthDisabled {
                        Text("Google may share your email with Firebase. Phone stays a placeholder until you add it in Profile.")
                            .font(.caption2)
                            .foregroundStyle(secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }

                    ZStack {
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                                let nonce = randomNonceString()
                                currentNonce = nonce
                                request.nonce = sha256(nonce)
                            },
                            onCompletion: { result in
                                switch result {
                                case .success(let auth):
                                    handleAppleLogin(auth: auth)
                                case .failure(let error):
                                    presentAuthError("Apple sign-in failed: \(error.localizedDescription)")
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(10)
                        .allowsHitTesting(!thirdPartyAuthDisabled)
                        if thirdPartyAuthDisabled {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.001))
                                .frame(height: 50)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if usernameForOAuthUnset {
                                        presentAuthError("Enter a unique @handle above, then sign in with Apple.")
                                    } else if authMode == .signUp && accountPortal == .business {
                                        presentAuthError("Business registration requires email and password so we can store your EIN and business address securely.")
                                    }
                                }
                        }
                    }
                    if !thirdPartyAuthDisabled {
                        Text("Apple may hide your email—we save a placeholder and your real one if Apple shares it; add phone in Profile.")
                            .font(.caption2)
                            .foregroundStyle(secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }

                    if authMode == .signUp && accountPortal == .business {
                        Text("Business sign-up needs your EIN and entity details — use email & password above (not Google/Apple).")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }

                    Button(action: emailLogin) {
                        authButtonLabel(title: "Continue with Email", icon: "envelope.fill")
                    }
                    .disabled(emailPasswordShortcutDisabled)

                    DisclosureGroup(isExpanded: $showMoreOptions) {
                        VStack(spacing: 10) {
                            Button(action: phoneLogin) {
                                authButtonLabel(title: "Continue with Phone", icon: "phone.fill")
                            }
                            .disabled(usernameForOAuthUnset)

                            Button {
                                providerTapped("Facebook")
                            } label: {
                                authButtonLabel(title: "Continue with Facebook", icon: "person.2.fill")
                            }

                            Button {
                                providerTapped("Instagram")
                            } label: {
                                authButtonLabel(title: "Continue with Instagram", icon: "camera.fill")
                            }

                            Button {
                                providerTapped("Gmail")
                            } label: {
                                authButtonLabel(title: "Continue with Gmail", icon: "at")
                            }
                        }
                    } label: {
                        Text("More sign up options")
                            .font(.headline)
                            .foregroundStyle(primaryText)
                    }
                    .padding()
                    .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("Connect Threads, X/Twitter, Snapchat, YouTube, and LinkedIn after login.")
                        .font(.footnote)
                        .foregroundStyle(secondaryText)
                        .padding(.top, 4)
                }
                .padding()
            }
        }
        .alert("Provider setup", isPresented: $showingProviderAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(providerMessage)
        }
        .sheet(isPresented: $showForgotPassword) {
            NavigationStack {
                Form {
                    Section {
                        Text(
                            "We email a one-time code to the address saved on your profile. You’ll need that code and access to the inbox — passwords can’t be changed from email match alone."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    switch forgotPhase {
                    case .requestCode:
                        Section("Account") {
                            TextField("Username", text: $forgotUsername)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            TextField("Email on file", text: $forgotEmail)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                        }
                        Section {
                            Button(forgotSendingCode ? "Sending…" : "Email me a reset code") {
                                forgotStatus = ""
                                forgotSendingCode = true
                                Task {
                                    let err = await appState.requestPasswordResetCode(
                                        username: forgotUsername,
                                        email: forgotEmail
                                    )
                                    await MainActor.run {
                                        forgotSendingCode = false
                                        if let err {
                                            forgotStatus = err
                                        } else {
                                            forgotPhase = .enterNewPassword
                                            forgotStatus = "If your details matched, we sent a 6-digit code. Check your inbox and spam (valid ~15 min)."
                                        }
                                    }
                                }
                            }
                            .disabled(forgotSendingCode)
                        }
                    case .enterNewPassword:
                        Section("Code from email") {
                            TextField("6-digit code", text: $forgotCode)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                        }
                        Section("New password") {
                            SecureField("New password (8+ chars)", text: $forgotNewPassword)
                            SecureField("Confirm", text: $forgotConfirmPassword)
                        }
                        Section {
                            Button("Update password") {
                                guard forgotNewPassword == forgotConfirmPassword else {
                                    forgotStatus = "Passwords do not match."
                                    return
                                }
                                if let err = appState.completePasswordResetWithCode(
                                    username: forgotUsername,
                                    email: forgotEmail,
                                    code: forgotCode,
                                    newPassword: forgotNewPassword
                                ) {
                                    forgotStatus = err
                                } else {
                                    forgotStatus = "Updated. You can log in with your new password."
                                    showForgotPassword = false
                                }
                            }
                            Button("Start over", role: .cancel) {
                                forgotPhase = .requestCode
                                forgotCode = ""
                                forgotStatus = ""
                            }
                        }
                    }
                    if !forgotStatus.isEmpty {
                        Section {
                            Text(forgotStatus)
                                .font(.caption)
                                .foregroundStyle(forgotStatus.hasPrefix("Updated") ? .green : .orange)
                        }
                    }
                }
                .navigationTitle("Reset password")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { showForgotPassword = false }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func authButtonLabel(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(title)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(BrandPalette.adaptiveGlassStroke(for: colorScheme), lineWidth: 1)
        )
        .foregroundStyle(primaryText)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var launchQualityStrip: some View {
        HStack(spacing: 8) {
            launchChip("Fast onboarding", icon: "bolt.fill")
            launchChip("Dual profiles", icon: "person.2.fill")
            launchChip("Privacy first", icon: "lock.fill")
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func launchChip(_ text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(primaryText)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.86))
        .clipShape(Capsule())
    }

    private var primaryText: Color {
        BrandPalette.adaptiveTextPrimary(for: colorScheme)
    }

    private var secondaryText: Color {
        BrandPalette.adaptiveTextSecondary(for: colorScheme)
    }

    private var portalAccent: Color {
        accountPortal == .social ? BrandPalette.neonBlue : BrandPalette.accentPurple
    }

    private var portalSubtitle: String {
        accountPortal == .social
            ? "One login, two modes: scroll the feed, then switch to Corporate for jobs and hiring — same account."
            : "Register your business with EIN + entity details. Your @username still powers the social side; legal name powers hiring."
    }

    private var portalSignUpTitle: String {
        accountPortal == .social ? "Create your creator account" : "Register your business"
    }

    private var portalLoginTitle: String {
        accountPortal == .social ? "Welcome back, creator" : "Business login"
    }

    private var portalCardSubtitle: String {
        authMode == .signUp
            ? (accountPortal == .social
                ? "Email is required. Phone is optional. Username shows on the social app; you still get Corporate."
                : "Email plus full business registration (including phone) is required.")
            : (accountPortal == .social
                ? "Same password for both modes."
                : "Use the username and password you set at registration.")
    }

    private var thirdPartyAuthDisabled: Bool {
        usernameForOAuthUnset || (authMode == .signUp && accountPortal == .business)
    }

    private var usernameForOAuthUnset: Bool {
        username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var accountPortalToggle: some View {
        HStack(spacing: 0) {
            ForEach(AccountPortal.allCases) { portal in
                let selected = accountPortal == portal
                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                        accountPortal = portal
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: portal == .social ? "sparkles.rectangle.stack.fill" : "building.2.crop.circle.fill")
                            .font(.title2)
                        Text(portal == .social ? "Creator" : "Business")
                            .font(.caption.weight(.heavy))
                        Text(portal == .social ? "Social first" : "EIN & jobs")
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .opacity(0.88)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(selected ? Color.white : primaryText.opacity(0.92))
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(portalGradient(for: portal))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [portalAccent.opacity(0.5), BrandPalette.neonGreen.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
    }

    private func portalGradient(for portal: AccountPortal) -> LinearGradient {
        if portal == .social {
            return LinearGradient(
                colors: [BrandPalette.neonBlue, BrandPalette.neonGreen.opacity(0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [BrandPalette.accentPurple.opacity(0.95), BrandPalette.neonBlue.opacity(0.75)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func applyPortalProfileDefaults() {
        appState.configurePrimaryProfile(
            primaryMode: accountPortal == .business ? .enterprise : .social,
            socialVisible: true,
            corporateVisible: true,
            createSecondary: true
        )
    }

    func googleLogin() {
        if authMode == .signUp && accountPortal == .business {
            presentAuthError("Business registration requires email and password so we can store your EIN and business address securely.")
            return
        }
        guard applyUsernameFromInput() else { return }
        appState.wantsProductUpdateEmails = wantsUpdateEmails
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            presentAuthError("Missing Firebase client ID.")
            return
        }

        let config = GIDConfiguration(clientID: clientID)

        guard let rootVC = oauthTopViewController() else {
            presentAuthError("Could not open Google sign-in on this device. Close other sheets and try again, or use email login below.")
            return
        }

        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            if let error = error {
                presentAuthError("Google sign-in failed: \(error.localizedDescription)")
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                presentAuthError("Missing Google ID token.")
                return
            }

            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    presentAuthError("Firebase Google sign-in error: \(error.localizedDescription)")
                } else if let user = result?.user {
                    saveUserToFirestore(user: user, provider: "google.com")
                    Task { @MainActor in
                        appState.markVerificationEmailSent()
                        if let error = appState.completeProviderLogin(
                            username: username,
                            provider: "google.com",
                            accountEmailFromProvider: user.email
                        ) {
                            presentAuthError(error)
                        } else {
                            applyPortalProfileDefaults()
                        }
                    }
                }
            }
        }
    }

    func handleAppleLogin(auth: ASAuthorization) {
        if authMode == .signUp && accountPortal == .business {
            presentAuthError("Business registration requires email and password so we can store your EIN and business address securely.")
            return
        }
        guard applyUsernameFromInput() else { return }
        appState.wantsProductUpdateEmails = wantsUpdateEmails
        guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential else {
            presentAuthError("Invalid Apple credentials.")
            return
        }

        guard let tokenData = appleIDCredential.identityToken,
              let idTokenString = String(data: tokenData, encoding: .utf8) else {
            presentAuthError("Failed to get Apple ID token.")
            return
        }
        guard let nonce = currentNonce else {
            presentAuthError("Missing Apple sign-in nonce. Try again.")
            return
        }

        let credential = OAuthProvider.credential(
            providerID: AuthProviderID.apple,
            idToken: idTokenString,
            rawNonce: nonce
        )

        Auth.auth().signIn(with: credential) { result, error in
            if let error = error {
                presentAuthError("Apple Firebase sign-in error: \(error.localizedDescription)")
            } else if let user = result?.user {
                saveUserToFirestore(user: user, provider: "apple.com")
                Task { @MainActor in
                    appState.markVerificationEmailSent()
                    if let error = appState.completeProviderLogin(
                        username: username,
                        provider: "apple.com",
                        accountEmailFromProvider: user.email
                    ) {
                        presentAuthError(error)
                    } else {
                        applyPortalProfileDefaults()
                    }
                }
            }
        }
    }

    func phoneLogin() {
        appState.wantsProductUpdateEmails = wantsUpdateEmails
        providerTapped("Phone (coming soon)")
    }

    func emailLogin() {
        primaryAuthAction()
    }

    private func providerTapped(_ provider: String) {
        providerMessage = "\(provider) auth can be added by enabling this provider in Firebase Auth and wiring the SDK callback."
        showingProviderAlert = true
    }

    private func applyUsernameFromInput() -> Bool {
        if let err = appState.usernameValidationError(username) {
            providerMessage = err
            showingProviderAlert = true
            return false
        }
        let success = appState.setUsername(username)
        if !success {
            providerMessage = "Username already taken."
            showingProviderAlert = true
        }
        return success
    }

    private var emailPasswordShortcutDisabled: Bool {
        if authMode == .logIn {
            let e = loginEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return e || password.count < 8
        }
        return usernameForOAuthUnset || password.count < 8
    }

    private func primaryAuthAction() {
        appState.wantsProductUpdateEmails = wantsUpdateEmails
        Task {
            let error: String?
            switch authMode {
            case .signUp:
                if accountPortal == .business {
                    let registration = BusinessRegistration(
                        ein: businessEIN,
                        legalName: businessLegalName,
                        dba: businessDBA,
                        addressLine1: businessAddress,
                        city: businessCity,
                        state: businessState,
                        zip: businessZIP,
                        phone: businessPhone,
                        website: businessWebsite
                    )
                    error = await appState.signUpWithFirebase(
                        username: username,
                        password: password,
                        accountEmail: signUpEmail,
                        accountPhone: businessPhone,
                        personalDisplayName: nil,
                        business: registration
                    )
                } else {
                    let name = personalRealName.trimmingCharacters(in: .whitespacesAndNewlines)
                    error = await appState.signUpWithFirebase(
                        username: username,
                        password: password,
                        accountEmail: signUpEmail,
                        accountPhone: signUpPhone,
                        personalDisplayName: name.isEmpty ? nil : name,
                        business: nil
                    )
                }
            case .logIn:
                error = await appState.logInWithFirebase(email: loginEmail, password: password)
            }
            if let error {
                presentAuthError(error)
                return
            }
            appState.markVerificationEmailSent()
            if authMode == .signUp {
                signUpEmail = ""
                signUpPhone = ""
            }
            applyPortalProfileDefaults()
        }
    }

    private func presentAuthError(_ message: String) {
        Task { @MainActor in
            providerMessage = message
            showingProviderAlert = true
        }
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms: [UInt8] = (0..<16).map { _ in 0 }
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if errorCode != errSecSuccess {
                return UUID().uuidString.replacingOccurrences(of: "-", with: "")
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
}

// MARK: - OAuth presentation (iPad / multi-window)

private func oauthKeyWindow() -> UIWindow? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let foreground = scenes.filter { $0.activationState == .foregroundActive }
    if let win = foreground.flatMap(\.windows).first(where: { $0.isKeyWindow }) {
        return win
    }
    if let win = scenes.flatMap(\.windows).first(where: { $0.isKeyWindow }) {
        return win
    }
    return scenes.flatMap(\.windows).first
}

private func oauthTopMost(from root: UIViewController) -> UIViewController {
    if let presented = root.presentedViewController {
        return oauthTopMost(from: presented)
    }
    if let nav = root as? UINavigationController, let visible = nav.visibleViewController {
        return oauthTopMost(from: visible)
    }
    if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
        return oauthTopMost(from: selected)
    }
    if let split = root as? UISplitViewController {
        if let secondary = split.viewController(for: .secondary) {
            return oauthTopMost(from: secondary)
        }
        if let primary = split.viewController(for: .primary) {
            return oauthTopMost(from: primary)
        }
        if let first = split.viewControllers.first {
            return oauthTopMost(from: first)
        }
    }
    return root
}

private func oauthTopViewController() -> UIViewController? {
    guard let root = oauthKeyWindow()?.rootViewController else { return nil }
    return oauthTopMost(from: root)
}
