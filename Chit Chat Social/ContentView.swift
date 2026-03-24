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

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            } else if appState.session?.isAuthenticated == true {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            ModerationNotificationHelper.requestAuthorizationIfNeeded()
        }
    }
}
