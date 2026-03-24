import SwiftUI

struct LiveStudioView: View {
    @EnvironmentObject private var appState: AppState
    @State private var activeDJ = "@brian"
    @State private var isLive = false
    @State private var coHostDraft = ""
    @State private var audienceHandleDraft = ""
    @State private var audienceRole: SocialLiveAudienceRole = .viewer

    var body: some View {
        ZStack {
            EliteBackground()
            Form {
                Section("Live DJ Room") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(isLive ? "LIVE" : "Offline")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isLive ? Color.red.opacity(0.85) : Color.gray.opacity(0.7))
                            .clipShape(Capsule())
                            .foregroundStyle(.white)
                    }
                    Text("Active DJ: \(activeDJ)")
                    Text("Song titles are visible to everyone.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.78))
                }

                Section("Queue") {
                    ForEach(appState.songQueue) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(item.title) - \(item.artist)")
                                .foregroundStyle(.white)
                            Text("Requested by \(item.requestedBy)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.74))
                        }
                    }
                }

                Section("Controls") {
                    Button("Switch DJ to next requester") {
                        if let next = appState.songQueue.first {
                            activeDJ = next.requestedBy
                        }
                    }
                    .buttonStyle(.bordered)
                    Button(isLive ? "End Live" : "Go Live Now") {
                        isLive.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isLive ? .red : BrandPalette.neonGreen)
                }

                Section("Co-Hosts") {
                    HStack(spacing: 8) {
                        TextField("Add @cohost", text: $coHostDraft)
                        Button("Toggle") {
                            guard !coHostDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                            appState.toggleLiveCoHost(coHostDraft)
                            coHostDraft = ""
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    if appState.liveCoHosts.isEmpty {
                        Text("No co-hosts yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(appState.liveCoHosts, id: \.self) { host in
                            HStack {
                                Text(host)
                                Spacer()
                                Label("Co-host", systemImage: "person.2.fill")
                                    .font(.caption)
                                    .foregroundStyle(BrandPalette.neonBlue)
                            }
                        }
                    }
                }

                Section("Audience Roles") {
                    HStack(spacing: 8) {
                        TextField("Audience handle", text: $audienceHandleDraft)
                        Picker("Role", selection: $audienceRole) {
                            ForEach(SocialLiveAudienceRole.allCases) { role in
                                Text(role.rawValue.capitalized).tag(role)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    Button("Assign Audience Role") {
                        guard !audienceHandleDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        appState.setAudienceRole(handle: audienceHandleDraft, role: audienceRole)
                        audienceHandleDraft = ""
                    }
                    .buttonStyle(.bordered)
                    ForEach(Array(appState.audienceRoleByHandle.keys.sorted()), id: \.self) { handle in
                        HStack {
                            Text(handle)
                            Spacer()
                            Text(appState.audienceRole(for: handle).rawValue.capitalized)
                                .font(.caption.bold())
                                .foregroundStyle(BrandPalette.neonGreen)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Live Studio")
    }
}
