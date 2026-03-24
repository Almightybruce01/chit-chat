//
//  Chit_ChatApp.swift
//  Chit Chat Social
//
//  Created by Brian Bruce on 2025-06-24.
//

import SwiftUI
import FirebaseCore
import UIKit

@main
struct ChitChatApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appState = AppState()
    @AppStorage("chitchat.appearance") private var appearanceRaw = AppAppearance.auto.rawValue

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(appState)
                .preferredColorScheme(preferredColorScheme)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        appState.captureExecutionCompletionSnapshotIfNeededDaily()
                    }
                }
        }
    }

    private var preferredColorScheme: ColorScheme? {
        guard let appearance = AppAppearance(rawValue: appearanceRaw) else { return nil }
        switch appearance {
        case .system: return nil
        case .auto:
            let hour = Calendar.current.component(.hour, from: Date())
            return (hour >= 7 && hour < 19) ? .light : .dark
        case .light: return .light
        case .dark: return .dark
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        styleGlobalAppearance()
        return true
    }

    private func styleGlobalAppearance() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.88)
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue
        ]
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.secondaryLabel
        ]
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor.systemBlue
    }
}
