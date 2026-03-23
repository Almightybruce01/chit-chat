//
//  MainTabView.swift
//  Chit Chat
//
//  Created by Brian Bruce on 2025-06-24.
//

import SwiftUI
import UIKit

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var permissionManager = AppPermissionManager()
    @AppStorage("hasRequestedCorePermissions") private var hasRequestedCorePermissions = false
    @State private var selectedTab = 0
    @State private var showChat = false
    @State private var showActivity = false
    @State private var showAccountSwitcher = false

    var body: some View {
        TabView(selection: $selectedTab) {
            tabContent(index: 0)
            tabContent(index: 1)
            tabContent(index: 2)
            tabContent(index: 3)
            tabContent(index: 4)
        }
        .id(appState.mode)
        .animation(MotionTokens.spring, value: appState.mode)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showActivity = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(BrandPalette.neonGreen)
                        if appState.unreadActivityCount > 0 {
                            Text("\(min(appState.unreadActivityCount, 9))")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(4)
                                .background(.red)
                                .clipShape(Circle())
                                .offset(x: 8, y: -7)
                        }
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showChat = true
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(BrandPalette.neonBlue)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if shouldShowCustomTabBar {
                customTabBar
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                    .padding(.horizontal, 14)
                    .allowsHitTesting(true)
            }
        }
        .sheet(isPresented: $showAccountSwitcher) {
            NavigationStack {
                HStack(spacing: 18) {
                    Text("Accounts")
                        .font(.title3.bold())
                    Spacer()
                    Button("Done") { showAccountSwitcher = false }
                }
                .padding()
                List {
                    Section("Logged in") {
                        ForEach(appState.loggedInAccounts) { account in
                            Button {
                                _ = appState.switchToAccount(username: account.username)
                                showAccountSwitcher = false
                            } label: {
                                HStack {
                                    Text(account.handle)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if appState.currentUser.username.lowercased() == account.username.lowercased() {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(BrandPalette.neonGreen)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Section("Mode") {
                        Button("Switch to Social") {
                            appState.setMode(.social)
                            showAccountSwitcher = false
                        }
                        Button("Switch to Corporate") {
                            appState.setMode(.enterprise)
                            showAccountSwitcher = false
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(EliteBackground())
            }
        }
        .sheet(isPresented: $showActivity, onDismiss: {
            appState.markAllActivityRead()
        }) {
            NavigationStack {
                ActivityView()
                    .environmentObject(appState)
            }
        }
        .sheet(isPresented: $showChat) {
            NavigationStack {
                ChatView()
                    .environmentObject(appState)
            }
        }
        .onAppear {
            guard !hasRequestedCorePermissions else { return }
            permissionManager.requestAllPermissions()
            hasRequestedCorePermissions = true
        }
        .onChange(of: permissionManager.latestCity) { _, newCity in
            guard let newCity, !newCity.isEmpty else { return }
            appState.setLocalCity(newCity)
        }
        .onChange(of: appState.mode) { _, _ in
            withAnimation(MotionTokens.spring) {
                selectedTab = 0
            }
        }
        .onChange(of: appState.requestedTabIndex) { _, requested in
            guard let idx = requested else { return }
            let clamped = max(0, min(idx, 4))
            selectedTab = clamped
            appState.requestedTabIndex = nil
        }
    }

    private var customTabBar: some View {
        let specs = tabSpecs
        return HStack(spacing: 0) {
            ForEach(Array(specs.enumerated()), id: \.offset) { idx, spec in
                tabBarButton(index: idx, title: spec.title, system: spec.icon)
            }
            profileTabBarButton
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous).fill(tabBarBackgroundFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(tabBarStrokeColor, lineWidth: 1.1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(colorScheme == .light ? 0.12 : 0.25), radius: 12, y: 4)
    }

    private func tabBarButton(index: Int, title: String, system: String) -> some View {
        Button {
            tabTapFeedback()
            selectedTab = index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: system)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.caption2)
            }
            .padding(.vertical, 8)
            .frame(minHeight: 50)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selectedTab == index ? selectedTabHighlight : .clear)
            )
            .foregroundStyle(selectedTab == index ? selectedTabLabelColor : tabLabelColor)
            .contentShape(Rectangle())
        }
        .buttonStyle(SnappyScaleButtonStyle())
    }

    private var profileTabBarButton: some View {
        Button {
            tabTapFeedback()
            selectedTab = 4
        } label: {
            VStack(spacing: 4) {
                profileTabIcon
                    .frame(width: 22, height: 22)
                Text(appState.mode == .enterprise ? "Executive" : "Profile")
                    .font(.caption2)
            }
            .padding(.vertical, 8)
            .frame(minHeight: 50)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selectedTab == 4 ? selectedTabHighlight : .clear)
            )
            .foregroundStyle(selectedTab == 4 ? selectedTabLabelColor : tabLabelColor)
            .contentShape(Rectangle())
        }
        .buttonStyle(SnappyScaleButtonStyle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    showAccountSwitcher = true
                }
        )
    }

    private func tabTapFeedback() {
        HapticTokens.light()
    }

    @ViewBuilder
    private var profileTabIcon: some View {
        if let data = appState.profilePhoto(for: appState.currentUser.handle), let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 22, height: 22)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 0.8))
        } else if let gifData = appState.profileGIF(for: appState.currentUser.handle), let uiImage = UIImage(data: gifData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 22, height: 22)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 0.8))
        } else {
            Image(systemName: "person.crop.circle")
        }
    }

    private var tabLabelColor: Color {
        if appState.mode == .enterprise {
            return EnterprisePalette.textSecondary
        }
        return colorScheme == .light ? .black.opacity(0.82) : .white.opacity(0.78)
    }

    private var selectedTabLabelColor: Color {
        appState.mode == .enterprise ? .white : BrandPalette.neonBlue
    }

    private var selectedTabHighlight: Color {
        appState.mode == .enterprise ? EnterprisePalette.action.opacity(0.40) : BrandPalette.neonBlue.opacity(0.16)
    }

    private var shouldShowCustomTabBar: Bool {
        // Always show tab bar so users can exit Reels/Create; only hide on Create (immersive compose)
        if appState.mode == .enterprise {
            return selectedTab != 2
        }
        return selectedTab != 2  // Show on Reels so user can tap Home/Profile to exit
    }

    private var tabBarBackgroundFill: some ShapeStyle {
        if appState.mode == .enterprise {
            return AnyShapeStyle(Color(red: 0.10, green: 0.12, blue: 0.16).opacity(0.96))
        }
        if colorScheme == .light {
            return AnyShapeStyle(Color.white.opacity(0.96))
        }
        return AnyShapeStyle(.ultraThinMaterial)
    }

    private var tabBarStrokeColor: Color {
        if appState.mode == .enterprise { return EnterprisePalette.stroke }
        return colorScheme == .light ? Color.black.opacity(0.08) : BrandPalette.glassStroke
    }

    private var tabSpecs: [TabSpec] {
        if appState.mode == .enterprise {
            return [
                TabSpec(title: "Exec", icon: "chart.bar.doc.horizontal.fill"),
                TabSpec(title: "Talent", icon: "person.2.crop.square.stack.fill"),
                TabSpec(title: "Compose", icon: "square.and.pencil"),
                TabSpec(title: "Inbox", icon: "tray.full.fill")
            ]
        }
        return [
            TabSpec(title: "Home", icon: "house.fill"),
            TabSpec(title: "Search", icon: "magnifyingglass"),
            TabSpec(title: "Create", icon: "plus.app.fill"),
            TabSpec(title: "Reels", icon: "play.rectangle.fill")
        ]
    }

    @ViewBuilder
    private func tabContent(index: Int) -> some View {
        if appState.mode == .enterprise {
            switch index {
            case 0:
                EnterpriseWorkspaceHomeView().environmentObject(appState).tag(0)
            case 1:
                EnterpriseTalentView().environmentObject(appState).tag(1)
            case 2:
                EnterpriseComposerView().environmentObject(appState).tag(2)
            case 3:
                EnterpriseInboxView().environmentObject(appState).tag(3)
            default:
                EnterpriseProfileView().environmentObject(appState).tag(4)
            }
        } else {
            switch index {
            case 0:
                HomeView().tag(0)
            case 1:
                SearchView().environmentObject(appState).tag(1)
            case 2:
                PostView().tag(2)
            case 3:
                ReelsView().environmentObject(appState).tag(3)
            default:
                ProfileView().tag(4)
            }
        }
    }

    private struct TabSpec {
        let title: String
        let icon: String
    }
}
