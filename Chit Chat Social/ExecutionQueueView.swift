import SwiftUI
import UIKit

struct ExecutionQueueView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var query = ""
    @State private var rangeStart = "1"
    @State private var rangeEnd = "100"
    @State private var queueCSV = ""
    @State private var showCSVSheet = false
    @State private var completionCSV = ""
    @State private var showCompletionCSVSheet = false
    @State private var restorePointLabel = ""

    private var queue: [ExecutionQueueItem] {
        appState.masterExecutionQueue(limit: 1000)
    }

    private var filteredQueue: [ExecutionQueueItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return queue }
        return queue.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.summary.localizedCaseInsensitiveContains(trimmed)
                || $0.id.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var completedCount: Int {
        queue.filter { $0.status == .completed }.count
    }

    private var deltaSummary: ExecutionDeltaSummary {
        appState.executionDeltaSummary()
    }

    private var snapshotStreak: Int {
        appState.executionSnapshotStreakDays()
    }

    var body: some View {
        ZStack {
            EliteBackground()
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    TextField("Search 1000-item queue", text: $query)
                        .textFieldStyle(.roundedBorder)
                    Button("Top 25 done") {
                        appState.markTopExecutionItemsComplete(25)
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Finish All") {
                        appState.markAllExecutionItemsComplete()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.top, 10)

                Text("Completed \(completedCount) / 1000")
                    .font(.caption)
                    .foregroundStyle(secondaryText)

                HStack(spacing: 10) {
                    Toggle("Lock completed items", isOn: Binding(
                        get: { appState.executionQueueLockCompleted },
                        set: { appState.setExecutionQueueLock($0) }
                    ))
                    .foregroundStyle(primaryText)
                    Spacer()
                    Text(String(format: "Delta %+d", deltaSummary.deltaCompleted))
                        .font(.caption.bold())
                        .foregroundStyle(deltaSummary.deltaCompleted >= 0 ? BrandPalette.neonGreen : .orange)
                }
                .padding(.horizontal)

                HStack(spacing: 8) {
                    TextField("Start", text: $rangeStart)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    TextField("End", text: $rangeEnd)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    Button("Mark Range Done") {
                        let start = Int(rangeStart) ?? 1
                        let end = Int(rangeEnd) ?? start
                        _ = appState.markExecutionRangeComplete(start: start, end: end)
                    }
                    .buttonStyle(.borderedProminent)
                }

                HStack(spacing: 10) {
                    Text("Latest: \(deltaSummary.latestCompleted)")
                        .font(.caption2)
                        .foregroundStyle(secondaryText)
                    Text("Prev: \(deltaSummary.previousCompleted)")
                        .font(.caption2)
                        .foregroundStyle(secondaryText)
                    Text(String(format: "Percent: %.2f%%", deltaSummary.latestPercent))
                        .font(.caption2)
                        .foregroundStyle(BrandPalette.neonBlue)
                    Text("Streak: \(snapshotStreak)d")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.horizontal)

                HStack(spacing: 8) {
                    TextField("Restore label", text: $restorePointLabel)
                        .textFieldStyle(.roundedBorder)
                    Button("Save Restore Point") {
                        appState.createExecutionQueueRestorePoint(label: restorePointLabel)
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Restore") {
                        _ = appState.restoreExecutionQueueFromRestorePoint()
                    }
                    .buttonStyle(.bordered)
                    Button("Clear") {
                        appState.clearExecutionQueueRestorePoint()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)

                if let restore = appState.executionQueueRestorePoint {
                    HStack {
                        Text("Restore: \(restore.label) (\(restore.completedCount) complete)")
                            .font(.caption2)
                            .foregroundStyle(secondaryText)
                        Spacer()
                    }
                    .padding(.horizontal)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(appState.pendingExecutionRanges(chunkSize: 50, maxRanges: 8).enumerated()), id: \.offset) { _, range in
                            Button("\(range.start)-\(range.end)") {
                                _ = appState.markExecutionRangeComplete(start: range.start, end: range.end)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.horizontal)
                }

                HStack(spacing: 8) {
                    Button("Export 1000 List CSV") {
                        queueCSV = appState.executionQueueCSV(limit: 1000)
                        showCSVSheet = true
                    }
                    .buttonStyle(.bordered)
                    Button("Snapshot") {
                        appState.captureExecutionCompletionSnapshot()
                    }
                    .buttonStyle(.bordered)
                    Button("Export Progress CSV") {
                        completionCSV = appState.executionCompletionCSV()
                        showCompletionCSVSheet = true
                    }
                    .buttonStyle(.bordered)
                    Button("Mark 1-100 Done") {
                        _ = appState.markExecutionRangeComplete(start: 1, end: 100)
                    }
                    .buttonStyle(.borderedProminent)
                }

                List {
                    ForEach(filteredQueue) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("#\(item.order) \(item.title)")
                                    .font(.headline)
                                    .foregroundStyle(primaryText)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { item.status == .completed },
                                    set: { _ in appState.toggleExecutionQueueItem(item.id) }
                                ))
                                .labelsHidden()
                            }
                            Text(item.summary)
                                .font(.caption)
                                .foregroundStyle(secondaryText)
                            Text(item.id)
                                .font(.caption2)
                                .foregroundStyle(secondaryText)
                        }
                        .listRowBackground(BrandPalette.cardBg.opacity(0.72))
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
        }
        .navigationTitle("1000 Update Queue")
        .sheet(isPresented: $showCSVSheet) {
            NavigationStack {
                VStack(spacing: 10) {
                    TextEditor(text: $queueCSV)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(BrandPalette.cardBg.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Button("Copy 1000 List CSV") {
                        UIPasteboard.general.string = queueCSV
                    }
                    .buttonStyle(NeonPrimaryButtonStyle())
                }
                .padding()
                .navigationTitle("1000 Queue CSV")
            }
        }
        .sheet(isPresented: $showCompletionCSVSheet) {
            NavigationStack {
                VStack(spacing: 10) {
                    TextEditor(text: $completionCSV)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(BrandPalette.cardBg.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Button("Copy Progress CSV") {
                        UIPasteboard.general.string = completionCSV
                    }
                    .buttonStyle(NeonPrimaryButtonStyle())
                }
                .padding()
                .navigationTitle("Progress CSV")
            }
        }
    }
}

private extension ExecutionQueueView {
    var primaryText: Color { BrandPalette.adaptiveTextPrimary(for: colorScheme) }
    var secondaryText: Color { BrandPalette.adaptiveTextSecondary(for: colorScheme) }
}
