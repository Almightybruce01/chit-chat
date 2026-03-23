import SwiftUI

struct ConnectionsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var contactSync = ContactSyncManager()
    @State private var tab: Int
    @State private var query = ""

    private var primaryText: Color { BrandPalette.adaptiveTextPrimary(for: colorScheme) }
    private var secondaryText: Color { BrandPalette.adaptiveTextSecondary(for: colorScheme) }

    init(initialTab: Int = 0) {
        _tab = State(initialValue: initialTab)
    }

    var body: some View {
        ZStack {
            EliteBackground()
            VStack(spacing: 10) {
                Picker("Connections", selection: $tab) {
                    Text("Following").tag(0)
                    Text("Followers").tag(1)
                    Text("Suggested").tag(2)
                    Text("Contacts").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(secondaryText)
                    TextField("Search handles", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(primaryText)
                }
                .textFieldStyle(EliteTextFieldStyle())
                .padding(.horizontal)

                List {
                    if tab == 0 {
                        Section("Following (\(appState.followingCount))") {
                            ForEach(filteredHandles(appState.activeFollowingHandles), id: \.self) { handle in
                                HStack {
                                    Text(handle)
                                    Spacer()
                                    Button(appState.closeFriendsHandles.contains(handle) ? "Close Friends" : "Add Close Friend") {
                                        appState.toggleCloseFriend(handle)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    Button("Unfollow") {
                                        appState.unfollow(handle)
                                    }
                                    .buttonStyle(.bordered)
                                }
                                .contextMenu {
                                    if appState.isBlocked(handle) {
                                        Button("Unblock") {
                                            appState.unblockHandle(handle)
                                        }
                                    } else {
                                        Button("Block", role: .destructive) {
                                            appState.blockHandle(handle)
                                        }
                                    }
                                }
                            }
                        }
                    } else if tab == 1 {
                        Section("Followers (\(appState.followersCount))") {
                            ForEach(filteredHandles(appState.activeFollowerHandles), id: \.self) { handle in
                                HStack {
                                    Text(handle)
                                    Spacer()
                                    if !appState.isFollowing(handle) {
                                        Button("Follow Back") {
                                            appState.follow(handle)
                                        }
                                        .buttonStyle(.borderedProminent)
                                    } else {
                                        Text("Following")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .contextMenu {
                                    Button("Remove follower", role: .destructive) {
                                        appState.removeFollower(handle)
                                    }
                                    if appState.isBlocked(handle) {
                                        Button("Unblock") {
                                            appState.unblockHandle(handle)
                                        }
                                    } else {
                                        Button("Block", role: .destructive) {
                                            appState.blockHandle(handle)
                                        }
                                    }
                                }
                            }
                        }
                    } else if tab == 2 {
                        Section("Suggested for You") {
                            ForEach(appState.suggestedConnections().filter { matchesQuery($0.user.handle) }) { suggestion in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(suggestion.user.handle).font(.headline)
                                        Text("\(suggestion.mutualCount) mutual follows")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button("Follow") {
                                        appState.follow(suggestion.user.handle)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .contextMenu {
                                    if appState.isBlocked(suggestion.user.handle) {
                                        Button("Unblock") {
                                            appState.unblockHandle(suggestion.user.handle)
                                        }
                                    } else {
                                        Button("Block", role: .destructive) {
                                            appState.blockHandle(suggestion.user.handle)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        Section {
                            Text(contactSync.statusMessage)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Button("Sync Contacts") {
                                contactSync.requestAndLoadContacts()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        Section("Your Contacts on Chit Chat") {
                            ForEach(filteredHandles(appState.matchedContactHandles), id: \.self) { handle in
                                HStack {
                                    Text(handle)
                                    Spacer()
                                    if appState.isFollowing(handle) {
                                        Text("Following")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Button("Follow") {
                                            appState.follow(handle)
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .onChange(of: contactSync.displayNames) { _, names in
                appState.syncContacts(displayNames: names, identifiers: contactSync.identifiers)
            }
        }
        .navigationTitle(appState.mode == .enterprise ? "Corporate Network" : "Connections")
    }

    private func filteredHandles(_ handles: Set<String>) -> [String] {
        Array(handles).sorted().filter(matchesQuery)
    }

    private func matchesQuery(_ handle: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return handle.localizedCaseInsensitiveContains(trimmed)
    }
}
