//
//  ChatView.swift
//  Chit Chat
//
//  Created by Brian Bruce on 2025-06-24.
//

import SwiftUI
import UIKit

struct ChatView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    private let rooms: [CallRoomType] = [.oneOnOne, .groupDJ, .executive]
    @State private var selectedSegment = 0
    @State private var inboxTab = 0
    @State private var query = ""
    @State private var hideMuted = true
    private var primaryText: Color { BrandPalette.adaptiveTextPrimary(for: colorScheme) }
    private var secondaryText: Color { BrandPalette.adaptiveTextSecondary(for: colorScheme) }

    var body: some View {
        NavigationStack {
            ZStack {
                EliteBackground()
                VStack(spacing: 10) {
                    FuturisticSectionHeader(
                        title: "Inbox + Calls",
                        subtitle: "Messages, live rooms, and executive call spaces."
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, LayoutTokens.screenHorizontal)

                    Picker("Mode", selection: $selectedSegment) {
                        Text("Inbox").tag(0)
                        Text("Calls").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, LayoutTokens.screenHorizontal)

                    if selectedSegment == 0 {
                        Picker("Inbox Tabs", selection: $inboxTab) {
                            Text("Primary").tag(0)
                            Text("General").tag(1)
                            Text("Requests").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, LayoutTokens.screenHorizontal)

                        Toggle("Hide muted threads", isOn: $hideMuted)
                            .font(.caption)
                            .foregroundStyle(primaryText)
                            .padding(.horizontal, LayoutTokens.screenHorizontal)
                    }

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(secondaryText)
                        TextField("Search chats or rooms", text: $query)
                            .foregroundStyle(primaryText)
                    }
                    .textFieldStyle(EliteTextFieldStyle())
                    .padding(.horizontal, LayoutTokens.screenHorizontal)

                    List {
                        if selectedSegment == 0 {
                            if inboxTab != 2 {
                                Section("Notes") {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(appState.inboxNotes) { note in
                                                VStack(alignment: .leading, spacing: 3) {
                                                    Text(note.authorHandle)
                                                        .font(.caption.bold())
                                                        .foregroundStyle(primaryText)
                                                    Text(note.text)
                                                        .font(.caption2)
                                                        .lineLimit(2)
                                                        .foregroundStyle(secondaryText)
                                                }
                                                .frame(width: 120, alignment: .leading)
                                                .padding(10)
                                                .background(BrandPalette.cardBg.opacity(0.9))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(BrandPalette.glassStroke, lineWidth: 1)
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                            }

                            if inboxTab == 2 {
                                Section("Message Requests") {
                                    if appState.dmRequests.isEmpty {
                                        Text("No pending requests.")
                                            .foregroundStyle(secondaryText)
                                    } else {
                                        ForEach(appState.dmRequests) { request in
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text(request.fromHandle)
                                                    .font(.headline)
                                                    .foregroundStyle(primaryText)
                                                Text(request.previewText)
                                                    .font(.caption)
                                                    .foregroundStyle(secondaryText)
                                                HStack {
                                                    Button("Decline") {
                                                        appState.declineDMRequest(request.id)
                                                    }
                                                    .buttonStyle(.bordered)
                                                    Button("Accept") {
                                                        appState.acceptDMRequest(request.id)
                                                    }
                                                    .buttonStyle(NeonPrimaryButtonStyle())
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                let threads = filteredThreads.filter { !hideMuted || !appState.isThreadMuted($0.id) }
                                let pinned = threads.filter { appState.pinnedThreadIDs.contains($0.id) }
                                let nonPinned = threads.filter { !appState.pinnedThreadIDs.contains($0.id) }

                                if !pinned.isEmpty {
                                    Section("Pinned") {
                                        ForEach(pinned) { thread in
                                            threadRow(thread)
                                        }
                                    }
                                }

                                Section(appState.mode == .social ? "Direct Messages" : "Business Messages") {
                                    ForEach(nonPinned) { thread in
                                        threadRow(thread)
                                    }
                                }

                                Section("Channels") {
                                    ForEach(appState.broadcastChannels) { channel in
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(channel.title).font(.headline).foregroundStyle(.white)
                                            Text(channel.latestMessage).font(.caption).foregroundStyle(secondaryText)
                                            Text("\(channel.memberCount) members")
                                                .font(.caption2)
                                                .foregroundStyle(BrandPalette.neonGreen)
                                        }
                                    }
                                }
                            }
                        } else {
                            Section("Call Rooms") {
                                ForEach(rooms, id: \.rawValue) { room in
                                    NavigationLink(destination: CallRoomView(room: room).environmentObject(appState)) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(room.title)
                                                .font(.headline)
                                                .foregroundStyle(primaryText)
                                            Text(room.description)
                                                .font(.subheadline)
                                                .foregroundStyle(secondaryText)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
            }
            .navigationTitle("Chat + Calls")
        }
    }

    private var filteredThreads: [ChatThread] {
        appState.filteredThreads(query: query)
    }

    @ViewBuilder
    private func threadRow(_ thread: ChatThread) -> some View {
        NavigationLink(destination: ThreadDetailView(threadID: thread.id).environmentObject(appState)) {
            HStack(spacing: 10) {
                Circle()
                    .fill(BrandPalette.neonBlue.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(thread.title.prefix(1)).uppercased())
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                    )
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(thread.title)
                            .foregroundStyle(primaryText)
                        if appState.pinnedThreadIDs.contains(thread.id) {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundStyle(BrandPalette.neonGreen)
                        }
                        if appState.isThreadMuted(thread.id) {
                            Image(systemName: "bell.slash.fill")
                                .font(.caption2)
                                .foregroundStyle(secondaryText)
                        }
                    }
                    Text(thread.messages.last?.text ?? "No messages yet")
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(secondaryText)
                    if let typing = appState.typingStatus(threadID: thread.id) {
                        Text(typing)
                            .font(.caption2)
                            .foregroundStyle(BrandPalette.neonGreen)
                    }
                }
                Spacer()
                Circle()
                    .fill(appState.isThreadSeen(thread.id) ? .clear : BrandPalette.neonBlue)
                    .frame(width: 8, height: 8)
            }
        }
        .contextMenu {
            Button(appState.pinnedThreadIDs.contains(thread.id) ? "Unpin" : "Pin") {
                appState.togglePinThread(thread.id)
            }
            Button(appState.isThreadMuted(thread.id) ? "Unmute" : "Mute") {
                appState.toggleMuteThread(thread.id)
            }
            Button {
                appState.markThreadSeen(thread.id)
            } label: {
                Label("Mark seen", systemImage: "eye")
            }
        }
    }
}

enum CallRoomType: String {
    case oneOnOne
    case groupDJ
    case executive

    var title: String {
        switch self {
        case .oneOnOne: return "1-on-1 Call"
        case .groupDJ: return "Group Call + DJ Room"
        case .executive: return "Executive / Business Call"
        }
    }

    var description: String {
        switch self {
        case .oneOnOne:
            return "Social call with emoji face effects and live music sync."
        case .groupDJ:
            return "Group social room with DJ queue and reaction bursts."
        case .executive:
            return "Corporate suite with roles, meeting rooms, and notes."
        }
    }
}

struct CallRoomView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    let room: CallRoomType
    @State private var isSharingScreen = false
    @State private var meetingNotes = ""
    @State private var isMusicSyncOn = true
    @State private var emojiMask = "😎"
    @State private var selectedHandle = ""
    @State private var selectedRole: CorporateCallRole = .presenter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(room.title)
                    .font(.title2.bold())
                    .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                Text(room.description)
                    .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))

                Toggle("Share Screen", isOn: $isSharingScreen)
                    .tint(BrandPalette.neonBlue)

                if room != .executive {
                    socialCallPanel
                }

                if room == .executive {
                    corporateCallPanel
                }

                if room == .groupDJ {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Now Playing")
                            .font(.headline)
                            .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                        ForEach(appState.songQueue.prefix(3)) { song in
                            Text("\(song.title) - \(song.artist)")
                                .font(.subheadline)
                                .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Call Room")
    }

    private var socialCallPanel: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Social Call Features")
                    .font(.headline)
                Toggle("Music sync", isOn: $isMusicSyncOn)
                    .onChange(of: isMusicSyncOn) { _, newValue in
                        appState.socialMusicSyncEnabled = newValue
                    }
                Button("Emoji Face Effect \(emojiMask)") {
                    let next = ["😎", "🤖", "🔥", "😂", "👻", "🎭"].randomElement() ?? "😎"
                    emojiMask = next
                    appState.applySocialFaceEmojiMask(next)
                }
                .buttonStyle(.borderedProminent)
                Text("Interactive reactions and playful overlays are enabled in social rooms.")
                    .font(.caption)
                    .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
            }
        }
    }

    private var corporateCallPanel: some View {
        EliteSectionCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Corporate Meeting Controls")
                    .font(.headline)
                Text("Roles, breakout rooms, notes, and structured meeting controls.")
                    .font(.caption)
                    .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                HStack(spacing: 8) {
                    TextField("Handle", text: $selectedHandle)
                        .textFieldStyle(EliteTextFieldStyle())
                    Picker("Role", selection: $selectedRole) {
                        ForEach(CorporateCallRole.allCases) { role in
                            Text(role.rawValue.capitalized).tag(role)
                        }
                    }
                    .pickerStyle(.menu)
                    Button("Assign") {
                        appState.assignCorporateRole(handle: selectedHandle, role: selectedRole)
                        selectedHandle = ""
                    }
                    .buttonStyle(.borderedProminent)
                }
                Button("Split into meeting rooms") {
                    appState.splitCorporateMeetingRooms()
                }
                .buttonStyle(.bordered)
                ForEach(appState.corporateMeetingRooms.prefix(5)) { room in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(room.title).font(.subheadline.bold())
                        Text(room.activeAgenda).font(.caption).foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                    }
                }
                Text("Meeting Notes")
                    .font(.headline)
                TextEditor(text: $meetingNotes)
                    .frame(height: 140)
                    .padding(8)
                    .background(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(BrandPalette.adaptiveGlassStroke(for: colorScheme), lineWidth: 1)
                    )
            }
        }
    }
}

struct ThreadDetailView: View {
    private enum ThreadMessageFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case text = "Text"
        case media = "Media"
        case voice = "Voice"
        case links = "Links"
        var id: String { rawValue }
    }

    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    let threadID: UUID
    @State private var draftMessage = ""
    @State private var scheduledText = ""
    @State private var showScheduleComposer = false
    @State private var quickMediaMode = false
    @State private var showMediaGallery = false
    @State private var isRecordingVoice = false
    @State private var voiceNoteDuration = 0
    @State private var playingVoiceMessageID: UUID?
    @State private var reactionsByMessageID: [UUID: String] = [:]
    @State private var selectedMessageForActions: MessageItem?
    @State private var showMessageActions = false
    @State private var isEditingMessage = false
    @State private var editMessageDraft = ""
    @State private var bulkModerationMode = false
    @State private var selectedMessageIDs: Set<UUID> = []
    @State private var threadSearchQuery = ""
    @State private var selectedMessageFilter: ThreadMessageFilter = .all

    private var thread: ChatThread? {
        appState.chats.first(where: { $0.id == threadID })
    }

    var body: some View {
        ZStack {
            EliteBackground()
            if let thread {
                VStack(spacing: 0) {
                    HStack {
                        Text(deliveryLabel)
                            .font(.caption)
                            .foregroundStyle(deliveryColor)
                        Spacer()
                        Toggle("Media-first", isOn: mediaFirstBinding)
                        .labelsHidden()
                        Text("Media-first")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                            TextField("Search in thread", text: $threadSearchQuery)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                        }
                        .textFieldStyle(EliteTextFieldStyle())

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ThreadMessageFilter.allCases) { filter in
                                    Button(filter.rawValue) {
                                        selectedMessageFilter = filter
                                    }
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(selectedMessageFilter == filter ? BrandPalette.neonBlue.opacity(0.35) : BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.82))
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(BrandPalette.adaptiveGlassStroke(for: colorScheme), lineWidth: 1)
                                    )
                                    .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 6)

                    if appState.canUndoMessageDeletion {
                        HStack(spacing: 8) {
                            Text("Message deleted")
                                .font(.caption)
                                .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                                .lineLimit(1)
                            Spacer()
                            Button("Undo") {
                                _ = appState.undoLastDeletedMessage()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                    }

                    List(filteredMessages(thread: thread)) { message in
                        messageRow(message)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if bulkModerationMode {
                                    toggleMessageSelection(message.id)
                                } else {
                                    selectedMessageForActions = message
                                    showMessageActions = true
                                }
                            }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)

                    if bulkModerationMode {
                        HStack(spacing: 8) {
                            Text("\(selectedMessageIDs.count) selected")
                                .font(.caption.bold())
                                .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                            Spacer()
                            Button("Cancel") {
                                bulkModerationMode = false
                                selectedMessageIDs.removeAll()
                            }
                            .buttonStyle(.bordered)
                            Button("Delete Selected", role: .destructive) {
                                appState.deleteMessages(threadID: threadID, messageIDs: Array(selectedMessageIDs))
                                selectedMessageIDs.removeAll()
                                bulkModerationMode = false
                                HapticTokens.medium()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(selectedMessageIDs.isEmpty)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 6)
                    }

                    HStack {
                        Menu {
                            Button("On my way", systemImage: "paperplane.fill") {
                                applyTemplate("On my way - will update shortly.")
                            }
                            Button("Sounds good", systemImage: "hand.thumbsup.fill") {
                                applyTemplate("Sounds good. Let's lock it in.")
                            }
                            Button("Can we reschedule?", systemImage: "calendar.badge.exclamationmark") {
                                applyTemplate("Can we reschedule to later today?")
                            }
                            if !draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Button("Clear message", role: .destructive) {
                                    draftMessage = ""
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.message.fill")
                                .foregroundStyle(BrandPalette.neonBlue)
                        }
                        .buttonStyle(.plain)
                        Button {
                            quickMediaMode.toggle()
                        } label: {
                            Image(systemName: quickMediaMode ? "photo.fill.on.rectangle.fill" : "photo.on.rectangle")
                                .foregroundStyle(quickMediaMode ? BrandPalette.neonBlue : .white.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                        Button {
                            if isRecordingVoice {
                                isRecordingVoice = false
                                let payload = "[Voice \(voiceNoteDuration)s] tap to play"
                                appState.addMessage(to: threadID, text: payload)
                                voiceNoteDuration = 0
                            } else {
                                isRecordingVoice = true
                                voiceNoteDuration = 1
                                Task {
                                    while isRecordingVoice && voiceNoteDuration < 30 {
                                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                                        guard isRecordingVoice else { break }
                                        voiceNoteDuration += 1
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: isRecordingVoice ? "stop.circle.fill" : "mic.circle.fill")
                                .foregroundStyle(isRecordingVoice ? .red : BrandPalette.neonBlue)
                        }
                        .buttonStyle(.plain)
                        TextField("Type a message", text: $draftMessage)
                            .textFieldStyle(EliteTextFieldStyle())
                            .onChange(of: draftMessage) { _, newValue in
                                appState.setTyping(threadID: threadID, text: newValue)
                            }
                            .onSubmit {
                                sendCurrentDraft()
                            }
                        Button("Send") {
                            sendCurrentDraft()
                        }
                        .buttonStyle(NeonPrimaryButtonStyle())
                        .disabled(draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView("Thread unavailable", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle(thread?.title ?? "Chat")
        .onAppear {
            appState.markThreadSeen(threadID)
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showMediaGallery = true
                } label: {
                    Image(systemName: "photo.stack.fill")
                }
                Button {
                    appState.togglePinThread(threadID)
                } label: {
                    Image(systemName: appState.pinnedThreadIDs.contains(threadID) ? "pin.slash.fill" : "pin.fill")
                }
                Button {
                    showScheduleComposer = true
                } label: {
                    Image(systemName: "calendar.badge.plus")
                }
                .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                Button {
                    appState.toggleMuteThread(threadID)
                } label: {
                    Image(systemName: appState.isThreadMuted(threadID) ? "bell.slash.fill" : "bell.fill")
                }
                .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                Button {
                    bulkModerationMode.toggle()
                    if !bulkModerationMode {
                        selectedMessageIDs.removeAll()
                    }
                } label: {
                    Image(systemName: bulkModerationMode ? "checklist.checked" : "checklist")
                }
                .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                Menu {
                    Button("Delete My Messages", role: .destructive) {
                        appState.deleteAllMyMessages(threadID: threadID)
                        HapticTokens.medium()
                    }
                    if appState.undoQueueCount > 0 {
                        Button("Undo Latest Action") {
                            _ = appState.undoLatestAction()
                            HapticTokens.light()
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
            }
        }
        .confirmationDialog("Message Actions", isPresented: $showMessageActions, titleVisibility: .visible, presenting: selectedMessageForActions) { message in
            Button("Copy") {
                UIPasteboard.general.string = message.text
            }
            if message.senderHandle.caseInsensitiveCompare(appState.currentUser.handle) == .orderedSame {
                Button("Edit") {
                    editMessageDraft = message.text
                    isEditingMessage = true
                }
                Button("Delete", role: .destructive) {
                    appState.deleteMessage(threadID: threadID, messageID: message.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $isEditingMessage) {
            NavigationStack {
                Form {
                    Section("Edit message") {
                        TextField("Message", text: $editMessageDraft, axis: .vertical)
                            .lineLimit(2...6)
                        Button("Save Changes") {
                            guard let message = selectedMessageForActions else { return }
                            appState.updateMessage(threadID: threadID, messageID: message.id, newText: editMessageDraft)
                            isEditingMessage = false
                        }
                        .buttonStyle(NeonPrimaryButtonStyle())
                    }
                }
                .navigationTitle("Edit")
            }
        }
        .sheet(isPresented: $showScheduleComposer) {
            NavigationStack {
                Form {
                    Section("Schedule message") {
                        TextField("Type message to send later", text: $scheduledText)
                        Menu("Quick schedule") {
                            Button("In 5 min") {
                                queueScheduledMessage(prefix: "[Scheduled +5m]")
                            }
                            Button("In 1 hour") {
                                queueScheduledMessage(prefix: "[Scheduled +1h]")
                            }
                            Button("Tomorrow 9:00 AM") {
                                queueScheduledMessage(prefix: "[Scheduled tomorrow 9:00]")
                            }
                        }
                        Button("Save to draft queue") {
                            guard !scheduledText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                            appState.addMessage(to: threadID, text: "[Scheduled] \(scheduledText)")
                            scheduledText = ""
                            showScheduleComposer = false
                        }
                        .buttonStyle(NeonPrimaryButtonStyle())
                    }
                }
                .navigationTitle("Schedule")
            }
        }
        .sheet(isPresented: $showMediaGallery) {
            NavigationStack {
                List {
                    Section("Media in this thread") {
                        if let thread, thread.messages.filter({ $0.kind == .media || $0.kind == .voice }).isEmpty {
                            Text("No media messages yet.")
                                .foregroundStyle(.secondary)
                        } else if let thread {
                            ForEach(thread.messages.filter { $0.kind == .media || $0.kind == .voice }) { msg in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(msg.senderHandle)
                                        .font(.caption.bold())
                                    Text(msg.text)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Media Gallery")
            }
            .presentationDetents([.fraction(0.45), .large])
        }
    }

    private var deliveryLabel: String {
        switch appState.latestDeliveryState(for: threadID) {
        case .sent: return "Sent"
        case .delivered: return "Delivered"
        case .seen: return "Seen"
        }
    }

    private var mediaFirstBinding: Binding<Bool> {
        Binding(
            get: { appState.isThreadMediaFirst(threadID) },
            set: { _ in appState.toggleThreadMediaFirst(threadID) }
        )
    }

    @ViewBuilder
    private func messageRow(_ message: MessageItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(message.senderHandle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(message.sentAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                Spacer()
                if bulkModerationMode {
                    Image(systemName: selectedMessageIDs.contains(message.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selectedMessageIDs.contains(message.id) ? BrandPalette.neonBlue : BrandPalette.adaptiveTextSecondary(for: colorScheme))
                }
            }
            Group {
                if appState.isThreadMediaFirst(threadID), message.kind == .media {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [BrandPalette.neonBlue.opacity(0.45), BrandPalette.accentPurple.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 150)
                    .overlay(
                        Label("Media attachment", systemImage: "photo.fill")
                            .foregroundStyle(.white)
                    )
                } else if message.kind == .voice {
                    HStack(spacing: 8) {
                        Button {
                            if playingVoiceMessageID == message.id {
                                playingVoiceMessageID = nil
                            } else {
                                playingVoiceMessageID = message.id
                            }
                        } label: {
                            Image(systemName: playingVoiceMessageID == message.id ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title3)
                                .foregroundStyle(BrandPalette.neonBlue)
                        }
                        .buttonStyle(.plain)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(BrandPalette.neonBlue.opacity(0.35))
                            .frame(height: 8)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(BrandPalette.neonGreen)
                                    .frame(width: playingVoiceMessageID == message.id ? 120 : 46, height: 8)
                            }
                            .frame(width: 130)
                        Text(message.text)
                            .font(.caption2)
                            .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                    }
                } else {
                    Text(message.text)
                        .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.white.opacity(0.10), lineWidth: 1)
                    )
            )
            HStack(spacing: 8) {
                reactionChip("👍", for: message.id)
                reactionChip("🔥", for: message.id)
                reactionChip("💯", for: message.id)
                if let reaction = reactionsByMessageID[message.id] {
                    Text("Reacted \(reaction)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
            if message.senderHandle.caseInsensitiveCompare(appState.currentUser.handle) == .orderedSame {
                Text(message.delivery.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.58))
            }
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = message.text
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            Button {
                selectedMessageForActions = message
                showMessageActions = true
            } label: {
                Label("More actions", systemImage: "ellipsis.circle")
            }
            if message.senderHandle.caseInsensitiveCompare(appState.currentUser.handle) == .orderedSame {
                Button(role: .destructive) {
                    appState.deleteMessage(threadID: threadID, messageID: message.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private var deliveryColor: Color {
        switch appState.latestDeliveryState(for: threadID) {
        case .seen: return BrandPalette.neonGreen
        case .delivered: return .white.opacity(0.8)
        case .sent: return .white.opacity(0.65)
        }
    }

    private func applyTemplate(_ text: String) {
        draftMessage = text
        appState.setTyping(threadID: threadID, text: text)
    }

    private func sendCurrentDraft() {
        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let payload = quickMediaMode ? "[Media] \(trimmed)" : trimmed
        appState.addMessage(to: threadID, text: payload)
        HapticTokens.success()
        draftMessage = ""
        quickMediaMode = false
    }

    @ViewBuilder
    private func reactionChip(_ emoji: String, for messageID: UUID) -> some View {
        Button(emoji) {
            reactionsByMessageID[messageID] = emoji
        }
        .buttonStyle(.plain)
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.white.opacity(0.12))
        .clipShape(Capsule())
    }

    private func toggleMessageSelection(_ messageID: UUID) {
        if selectedMessageIDs.contains(messageID) {
            selectedMessageIDs.remove(messageID)
        } else {
            selectedMessageIDs.insert(messageID)
        }
    }

    private func filteredMessages(thread: ChatThread) -> [MessageItem] {
        thread.messages.filter { message in
            let query = threadSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let matchesQuery = query.isEmpty
                || message.text.lowercased().contains(query)
                || message.senderHandle.lowercased().contains(query)

            let matchesFilter: Bool
            switch selectedMessageFilter {
            case .all:
                matchesFilter = true
            case .text:
                matchesFilter = message.kind == .text || message.kind == .system
            case .media:
                matchesFilter = message.kind == .media
            case .voice:
                matchesFilter = message.kind == .voice
            case .links:
                matchesFilter = message.text.lowercased().contains("http://") || message.text.lowercased().contains("https://")
            }
            return matchesQuery && matchesFilter
        }
    }

    private func queueScheduledMessage(prefix: String) {
        let trimmed = scheduledText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        appState.addMessage(to: threadID, text: "\(prefix) \(trimmed)")
        HapticTokens.light()
        scheduledText = ""
        showScheduleComposer = false
    }
}
