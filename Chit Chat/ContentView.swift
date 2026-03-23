//
//  ContentView.swift
//  Chit Chat
//
//  Created by Brian Bruce on 2025-06-24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        if !hasSeenOnboarding {
            OnboardingView()
        } else if appState.session?.isAuthenticated == true {
            MainTabView()
        } else {
            LoginView()
        }
    }
}
