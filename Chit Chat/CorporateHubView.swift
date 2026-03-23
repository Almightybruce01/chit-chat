import SwiftUI

struct CorporateHubView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var aiPrompt = ""
    @State private var aiOutput = "AI strategy output will appear here."
    @AppStorage("chitchat.corporate.onboarding.done") private var corporateOnboardingDone = false
    @AppStorage("chitchat.corporate.permissions.notifications") private var corporateNotifEnabled = true
    @AppStorage("chitchat.corporate.permissions.contacts") private var corporateContactsEnabled = false
    @AppStorage("chitchat.corporate.permissions.outreach") private var corporateOutreachEnabled = true
    private var primaryText: Color { BrandPalette.adaptiveTextPrimary(for: colorScheme) }
    private var secondaryText: Color { BrandPalette.adaptiveTextSecondary(for: colorScheme) }

    var body: some View {
        ZStack {
            EnterpriseBackground()
            ScrollView {
                VStack(spacing: 14) {
                    sectionCard(title: "Corporate Setup", icon: "checklist") {
                        Toggle("Corporate notifications", isOn: $corporateNotifEnabled)
                            .foregroundStyle(primaryText)
                        Toggle("Corporate contacts sync", isOn: $corporateContactsEnabled)
                            .foregroundStyle(primaryText)
                        Toggle("Cold outreach mode", isOn: $corporateOutreachEnabled)
                            .foregroundStyle(primaryText)
                        Button(corporateOnboardingDone ? "Corporate onboarding complete" : "Finish onboarding checklist") {
                            corporateOnboardingDone = true
                            appState.setMode(.enterprise)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    sectionCard(title: "Corporate Feed", icon: "newspaper.fill") {
                        let corporatePosts = appState.posts
                            .filter { !$0.isArchived && ($0.surfaceStyle == .chat || $0.audience != .closeFriends) }
                            .prefix(5)
                        if corporatePosts.isEmpty {
                            Text("No corporate posts yet.")
                                .foregroundStyle(secondaryText)
                        } else {
                            ForEach(Array(corporatePosts), id: \.id) { post in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(post.authorHandle)
                                        .font(.caption.bold())
                                        .foregroundStyle(BrandPalette.neonBlue)
                                    Text(post.caption)
                                        .foregroundStyle(primaryText)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }

                    sectionCard(title: "Network Graph", icon: "point.3.connected.trianglepath.dotted") {
                        HStack {
                            metricPill("Following", value: "\(appState.enterpriseFollowingHandles.count)")
                            metricPill("Followers", value: "\(appState.enterpriseFollowerHandles.count)")
                            metricPill("Mode", value: appState.mode == .enterprise ? "Corporate" : "Social")
                        }
                    }

                    sectionCard(title: "Operations KPI Board", icon: "gauge.open.with.lines.needle.33percent") {
                        let corporatePostsCount = appState.posts.filter { !$0.isArchived && $0.surfaceStyle == .chat }.count
                        let hiringCount = appState.contracts.count
                        let networkSize = appState.enterpriseFollowerHandles.count + appState.enterpriseFollowingHandles.count
                        HStack {
                            metricPill("Corporate Posts", value: "\(corporatePostsCount)")
                            metricPill("Open Roles", value: "\(hiringCount)")
                            metricPill("Network Size", value: "\(networkSize)")
                        }
                        Text("KPI board updates in real-time from corporate mode activity.")
                            .font(.caption2)
                            .foregroundStyle(secondaryText)
                    }

                    sectionCard(title: "Approvals Center", icon: "checkmark.seal.text.page.fill") {
                        let pendingVerifications = appState.verificationRequests.filter { $0.status == .pending }.count
                        let pendingDM = appState.dmRequests.count
                        HStack {
                            metricPill("Verify Queue", value: "\(pendingVerifications)")
                            metricPill("DM Requests", value: "\(pendingDM)")
                        }
                        NavigationLink(destination: AdminDashboardView().environmentObject(appState)) {
                            Label("Open Moderation & Verification", systemImage: "person.badge.shield.checkmark")
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    sectionCard(title: "Corporate Identity Controls", icon: "person.crop.rectangle.stack.fill") {
                        HStack {
                            Text("Profile visibility")
                                .foregroundStyle(primaryText)
                            Spacer()
                            Button(appState.corporateProfileVisible ? "Hide Corporate" : "Show Corporate") {
                                appState.toggleProfileVisibility(.enterprise)
                            }
                            .buttonStyle(.bordered)
                        }
                        HStack {
                            Text("Current mode")
                                .foregroundStyle(primaryText)
                            Spacer()
                            Text(appState.mode == .enterprise ? "Corporate" : "Social")
                                .font(.caption.bold())
                                .foregroundStyle(BrandPalette.neonBlue)
                        }
                    }

                    sectionCard(title: "Campaign Studio", icon: "megaphone.fill") {
                        Text("Build launch campaigns with reusable copy blocks and AI playbooks.")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                        Button("Generate Campaign Plan") {
                            aiOutput = generatePlan(from: "Campaign sprint: product launch + creator outreach + B2B hiring visibility")
                        }
                        .buttonStyle(.borderedProminent)
                        Text(aiOutput)
                            .font(.caption)
                            .foregroundStyle(primaryText)
                    }

                    sectionCard(title: "Network", icon: "person.3.fill") {
                        NavigationLink(destination: ConnectionsView().environmentObject(appState)) {
                            Label("Corporate connections", systemImage: "person.crop.circle.badge.checkmark")
                        }
                        .buttonStyle(.borderedProminent)
                        Text("Mode: \(appState.mode == .enterprise ? "Corporate" : "Social")")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }

                    sectionCard(title: "Resume Builder", icon: "doc.text.fill") {
                        NavigationLink(destination: ResumeEnterpriseView().environmentObject(appState)) {
                            Label("Edit resume and profile", systemImage: "square.and.pencil")
                        }
                        .buttonStyle(.borderedProminent)
                        Text(appState.resume.headline)
                            .font(.subheadline)
                            .foregroundStyle(primaryText)
                    }

                    sectionCard(title: "Jobs", icon: "briefcase.fill") {
                        if appState.contracts.isEmpty {
                            Text("No opportunities yet.")
                                .foregroundStyle(secondaryText)
                        } else {
                            ForEach(appState.contracts.prefix(5)) { contract in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(contract.title)
                                            .font(.headline)
                                            .foregroundStyle(primaryText)
                                        Text("\(contract.location) • $\(contract.budgetUSD)")
                                            .font(.caption)
                                            .foregroundStyle(secondaryText)
                                    }
                                    Spacer()
                                    Text(contract.isLocalHire ? "Local" : "Remote")
                                        .font(.caption2.bold())
                                        .foregroundStyle(contract.isLocalHire ? BrandPalette.neonGreen : BrandPalette.neonBlue)
                                    Button(role: .destructive) {
                                        appState.deleteContract(contract.id)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }

                    sectionCard(title: "AI", icon: "sparkles") {
                        TextField("Ask AI for a strategy plan", text: $aiPrompt, axis: .vertical)
                            .lineLimit(2...4)
                            .textInputAutocapitalization(.sentences)
                        Button("Generate Playbook") {
                            aiOutput = generatePlan(from: aiPrompt)
                        }
                        .buttonStyle(.borderedProminent)
                        Text(aiOutput)
                            .font(.subheadline)
                            .foregroundStyle(primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    sectionCard(title: "Superapp Engine", icon: "infinity.circle.fill") {
                        NavigationLink(destination: SuperAppFeatureHubView().environmentObject(appState)) {
                            Label("Manage 19000 cross-platform modules", systemImage: "slider.horizontal.3")
                        }
                        .buttonStyle(.borderedProminent)
                        Text("Pulling patterns from Instagram, X/Twitter, LinkedIn, Facebook, Snapchat, and more.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.76))
                    }

                    sectionCard(title: "Execution Queue", icon: "checklist.unchecked") {
                        NavigationLink(destination: ExecutionQueueView().environmentObject(appState)) {
                            Label("Work through 1000 net-new updates in order", systemImage: "list.number")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Corporate Hub")
    }

    @ViewBuilder
    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        EnterpriseCard {
            VStack(alignment: .leading, spacing: 10) {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(EnterprisePalette.textPrimary)
                content()
            }
        }
    }

    private func generatePlan(from input: String) -> String {
        let prompt = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if prompt.isEmpty {
            return "Post 4 reels this week, prioritize one collaboration, and publish one hiring update on Pulse."
        }
        return "Plan for: \(prompt)\n1) Define target audience and KPI.\n2) Publish two short reels + one product post.\n3) Send three network outreach DMs.\n4) Track response and iterate in 48 hours."
    }

    @ViewBuilder
    private func metricPill(_ title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundStyle(EnterprisePalette.textPrimary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(EnterprisePalette.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
