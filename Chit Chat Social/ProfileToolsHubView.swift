//
//  ProfileToolsHubView.swift
//  Chit Chat Social
//

import SwiftUI

/// Settings / tools hub — NavigationLink destination so the main Profile tab stays lightweight.
struct ProfileToolsHubView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.storeKit) private var storeKit
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    @State private var aliasDraft = ""
    @State private var displayNameDraft = ""
    @State private var profileLinkDraft = ""
    @State private var quoteDraft = ""
    @State private var showQuoteEditor = false
    @State private var profileQuoteModerationMessage = ""

    private var primaryText: Color { BrandPalette.adaptiveTextPrimary(for: colorScheme) }

    var body: some View {
        ZStack {
            EliteBackground()
            List {
                Section("Identity") {
                    TextField("Corporate alias", text: $aliasDraft)
                    TextField("Display name", text: $displayNameDraft)
                    TextField("Profile link (https://...)", text: $profileLinkDraft)
                    Button("Save identity") {
                        appState.updateCurrentIdentity(enterpriseAlias: aliasDraft, displayName: displayNameDraft)
                        appState.setProfileLink(profileLinkDraft)
                    }
                }

                Section("Quote bubble") {
                    Toggle("Show profile quote bubble", isOn: Binding(
                        get: { appState.currentUser.isProfileQuoteVisible },
                        set: { appState.setProfileQuoteVisibility($0) }
                    ))
                    if showQuoteEditor {
                        TextField("Quote", text: $quoteDraft, axis: .vertical)
                            .lineLimit(2...5)
                    }
                    Button(showQuoteEditor ? "Save quote" : "Edit quote") {
                        if showQuoteEditor {
                            if appState.setProfileQuote(quoteDraft) {
                                profileQuoteModerationMessage = ""
                            } else {
                                profileQuoteModerationMessage = "Quote blocked by safety checks."
                            }
                        } else {
                            quoteDraft = appState.currentUser.profileQuote
                        }
                        showQuoteEditor.toggle()
                    }
                    if !profileQuoteModerationMessage.isEmpty {
                        Text(profileQuoteModerationMessage)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Section("Privacy & posting defaults") {
                    Toggle(
                        "Allow enterprise side to reveal social @username",
                        isOn: Binding(
                            get: { appState.currentUser.allowEnterpriseReveal },
                            set: { appState.setEnterpriseReveal($0) }
                        )
                    )
                    Toggle("Hide likes count by default", isOn: $appState.hideLikeCountsByDefault)
                    Toggle("Hide comments count by default", isOn: $appState.hideCommentCountsByDefault)
                    Toggle("Ad account tools (ops-gated)", isOn: Binding(
                        get: { appState.currentUser.isAdAccount },
                        set: { appState.setAdAccountEnabled($0) }
                    ))
                }

                Section("Account") {
                    NavigationLink {
                        VerificationView()
                            .environmentObject(appState)
                    } label: {
                        Label("Verification & paid badge (IAP)", systemImage: "checkmark.seal")
                    }
                    Button {
                        Task {
                            await storeKit.restorePurchases()
                            appState.syncPaidVerificationEntitlement(active: storeKit.hasPaidVerification)
                        }
                    } label: {
                        Label(
                            storeKit.isRestoring ? "Restoring purchases…" : "Restore App Store purchases",
                            systemImage: "arrow.clockwise"
                        )
                    }
                    .disabled(storeKit.isRestoring)
                    NavigationLink {
                        ConnectionsView()
                            .environmentObject(appState)
                    } label: {
                        Label("Followers & connections", systemImage: "person.2.fill")
                    }
                    NavigationLink {
                        LaunchSettingsView()
                            .environmentObject(appState)
                    } label: {
                        Label("Launch settings", systemImage: "gearshape.2.fill")
                    }
                    NavigationLink {
                        SafetySettingsView()
                            .environmentObject(appState)
                    } label: {
                        Label("Safety settings", systemImage: "checkmark.shield.fill")
                    }
                    NavigationLink {
                        NotificationSettingsView()
                            .environmentObject(appState)
                    } label: {
                        Label("Notification settings", systemImage: "bell.badge.fill")
                    }
                    NavigationLink {
                        PrivacyControlView()
                            .environmentObject(appState)
                    } label: {
                        Label("Privacy controls", systemImage: "hand.raised.fill")
                    }
                    NavigationLink {
                        SocialLinksView()
                            .environmentObject(appState)
                    } label: {
                        Label("Connected platforms", systemImage: "link")
                    }
                    Button {
                        let subj = "Chit Chat Social support"
                        let q = subj.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        if let url = URL(string: "mailto:bruce44%2Bchitchat@getbusyllc.com?subject=\(q)") {
                            openURL(url)
                        }
                    } label: {
                        Label("Help & support", systemImage: "envelope.open.fill")
                    }
                    if appState.canAccessInternalDashboard {
                        NavigationLink {
                            AdminDashboardView()
                                .environmentObject(appState)
                        } label: {
                            Label("Admin dashboard", systemImage: "person.badge.shield.checkmark")
                        }
                    }
                }

                Section("Creator & business") {
                    NavigationLink {
                        ResumeEnterpriseView()
                            .environmentObject(appState)
                    } label: {
                        Label("Resume & enterprise", systemImage: "doc.text.fill")
                    }
                    NavigationLink {
                        CommunitiesHubView()
                            .environmentObject(appState)
                    } label: {
                        Label("Groups & communities", systemImage: "person.3.fill")
                    }
                    NavigationLink {
                        ShopHubView()
                            .environmentObject(appState)
                    } label: {
                        Label("Shop & live selling", systemImage: "bag.fill")
                    }
                    NavigationLink {
                        PulseBoardView()
                            .environmentObject(appState)
                    } label: {
                        Label("Pulse feed", systemImage: "bolt.bubble.fill")
                    }
                    NavigationLink {
                        MusicHubView()
                            .environmentObject(appState)
                    } label: {
                        Label("Music hub", systemImage: "music.note")
                    }
                    if appState.mode == .enterprise {
                        NavigationLink {
                            CorporateHubView()
                                .environmentObject(appState)
                        } label: {
                            Label("Corporate hub", systemImage: "building.2.crop.circle")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings & tools")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            aliasDraft = appState.currentUser.enterpriseAlias
            displayNameDraft = appState.currentUser.displayName
            profileLinkDraft = appState.currentUser.profileLinkURL
            quoteDraft = appState.currentUser.profileQuote
        }
    }
}
