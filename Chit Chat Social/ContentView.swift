//
//  ContentView.swift
//  Chit Chat Social
//
//  Created by Brian Bruce on 2025-06-24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("chitchat.communityTermsAccepted.v1") private var communityTermsAccepted = false

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            } else if appState.firebaseSignedInUID != nil {
                if communityTermsAccepted {
                    MainTabView()
                } else {
                    CommunityTermsGateView(didAccept: $communityTermsAccepted)
                        .environmentObject(appState)
                }
            } else {
                LoginView()
            }
        }
        .onAppear {
            ModerationNotificationHelper.requestAuthorizationIfNeeded()
        }
    }
}
