//
//  LoginView.swift
//  Chit Chat
//
//  Created by Brian Bruce on 2025-06-24.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import CryptoKit

private enum AuthMode: String, CaseIterable {
    case signUp = "Sign Up"
    case logIn = "Log In"
}

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingProviderAlert = false
    @State private var providerMessage = ""
    @State private var username = "Almighty_Bruce_"
    @State private var password = "Yzesati01!"
    @State private var wantsUpdateEmails = true
    @State private var showMoreOptions = false
    @State private var authMode: AuthMode = .logIn
    @State private var currentNonce: String?
    @State private var primaryProfileMode: PlatformMode = .social
    @State private var createSecondaryProfile = false
    @State private var socialVisible = true
    @State private var corporateVisible = true

    var body: some View {
        ZStack {
            EliteBackground()
            ScrollView {
                VStack(spacing: 16) {
                    AppLogoView(size: 150, cornerRadius: 20)
                        .padding(.top, 30)

                    Text("Welcome to Chit Chat")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(primaryText)

                    Text("The statement platform for social and enterprise.")
                        .foregroundStyle(secondaryText)

                    launchQualityStrip

                    EliteCard {
                        VStack(alignment: .leading, spacing: 10) {
                            FuturisticSectionHeader(
                                title: "Sign in to your universe",
                                subtitle: "Social vibes + corporate power in one identity stack."
                            )
                            Picker("Auth mode", selection: $authMode) {
                                ForEach(AuthMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)

                            Text("Create your username")
                                .font(.headline)
                                .foregroundStyle(primaryText)
                            TextField("username (required)", text: $username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(10)
                                .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(primaryText)
                            SecureField("password (required)", text: $password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(10)
                                .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundStyle(primaryText)
                            Toggle("Get app update emails", isOn: $wantsUpdateEmails)
                                .foregroundStyle(primaryText)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Choose your primary profile")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(primaryText)
                                Picker("Primary profile", selection: $primaryProfileMode) {
                                    Text("Social").tag(PlatformMode.social)
                                    Text("Corporate").tag(PlatformMode.enterprise)
                                }
                                .pickerStyle(.segmented)
                                Toggle("Create optional second profile now", isOn: $createSecondaryProfile)
                                    .foregroundStyle(primaryText)
                                Toggle("Social profile visible", isOn: $socialVisible)
                                    .foregroundStyle(secondaryText)
                                Toggle("Corporate profile visible", isOn: $corporateVisible)
                                    .foregroundStyle(secondaryText)
                            }
                            Text("Everyone must have a unique username.")
                                .font(.caption)
                                .foregroundStyle(secondaryText)
                            Button(authMode == .signUp ? "Create account" : "Log in") {
                                primaryAuthAction()
                            }
                            .buttonStyle(NeonPrimaryButtonStyle())
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }

                    Button(action: googleLogin) {
                        authButtonLabel(title: "Continue with Google", icon: "globe")
                    }
                    .disabled(usernameIncomplete)

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
                    .disabled(usernameIncomplete)

                    Button(action: emailLogin) {
                        authButtonLabel(title: "Continue with Email", icon: "envelope.fill")
                    }
                    .disabled(usernameIncomplete)

                    DisclosureGroup(isExpanded: $showMoreOptions) {
                        VStack(spacing: 10) {
                            Button(action: phoneLogin) {
                                authButtonLabel(title: "Continue with Phone", icon: "phone.fill")
                            }
                            .disabled(usernameIncomplete)

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

    func googleLogin() {
        guard applyUsernameFromInput() else { return }
        appState.wantsProductUpdateEmails = wantsUpdateEmails
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            presentAuthError("Missing Firebase client ID.")
            return
        }

        let config = GIDConfiguration(clientID: clientID)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            presentAuthError("Could not find a root view controller.")
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
                        if let error = appState.completeProviderLogin(username: username, provider: "google.com") {
                            presentAuthError(error)
                        } else {
                            appState.configurePrimaryProfile(
                                primaryMode: primaryProfileMode,
                                socialVisible: socialVisible,
                                corporateVisible: corporateVisible,
                                createSecondary: createSecondaryProfile
                            )
                        }
                    }
                }
            }
        }
    }

    func handleAppleLogin(auth: ASAuthorization) {
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
                    if let error = appState.completeProviderLogin(username: username, provider: "apple.com") {
                        presentAuthError(error)
                    } else {
                        appState.configurePrimaryProfile(
                            primaryMode: primaryProfileMode,
                            socialVisible: socialVisible,
                            corporateVisible: corporateVisible,
                            createSecondary: createSecondaryProfile
                        )
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
        let success = appState.setUsername(username)
        if !success {
            providerMessage = "Enter a valid unique username (3+ chars, letters/numbers/._)."
            showingProviderAlert = true
        }
        return success
    }

    private var usernameIncomplete: Bool {
        username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func primaryAuthAction() {
        appState.wantsProductUpdateEmails = wantsUpdateEmails
        let error: String?
        switch authMode {
        case .signUp:
            error = appState.signUp(username: username, password: password)
        case .logIn:
            error = appState.logIn(username: username, password: password)
        }
        if let error {
            providerMessage = error
            showingProviderAlert = true
            return
        }
        appState.markVerificationEmailSent()
        if let providerError = appState.completeProviderLogin(
            username: username,
            provider: authMode == .signUp ? "local_signup" : "local_login"
        ) {
            providerMessage = providerError
            showingProviderAlert = true
        } else {
            appState.configurePrimaryProfile(
                primaryMode: primaryProfileMode,
                socialVisible: socialVisible,
                corporateVisible: corporateVisible,
                createSecondary: createSecondaryProfile
            )
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
