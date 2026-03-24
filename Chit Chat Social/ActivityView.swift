import SwiftUI

private enum ActivityFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case mentions = "Mentions"
    case follows = "Follows"
    case engagement = "Engagement"

    var id: String { rawValue }
}

struct ActivityView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var filter: ActivityFilter = .all

    var body: some View {
        ZStack {
            EliteBackground()
            VStack(spacing: 10) {
                Picker("Filter", selection: $filter) {
                    ForEach(ActivityFilter.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                List {
                    if filteredActivity.isEmpty {
                        Section {
                            Text("No activity yet.")
                                .foregroundStyle(secondaryText)
                        }
                    } else {
                        Section("Latest") {
                            ForEach(filteredActivity) { item in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: icon(for: item.type))
                                        .foregroundStyle(color(for: item.type))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.detail)
                                            .foregroundStyle(primaryText)
                                        Text(item.createdAt, style: .relative)
                                            .font(.caption)
                                            .foregroundStyle(secondaryText)
                                    }
                                    Spacer()
                                    if !item.isRead {
                                        Circle()
                                            .fill(BrandPalette.neonBlue)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
        }
        .navigationTitle("Activity")
    }

    private var filteredActivity: [ActivityItem] {
        let base = appState.visibleActivityFeed
        switch filter {
        case .all:
            return base
        case .mentions:
            return base.filter { $0.type == .message || $0.type == .comment }
        case .follows:
            return base.filter { $0.type == .follow }
        case .engagement:
            return base.filter { [.like, .comment, .repost, .save].contains($0.type) }
        }
    }

    private func icon(for type: ActivityType) -> String {
        switch type {
        case .like: return "heart.fill"
        case .comment: return "bubble.right.fill"
        case .follow: return "person.badge.plus.fill"
        case .repost: return "arrow.2.squarepath"
        case .save: return "bookmark.fill"
        case .message: return "paperplane.fill"
        case .verification: return "checkmark.seal.fill"
        case .moderation: return "shield.lefthalf.filled"
        }
    }

    private func color(for type: ActivityType) -> Color {
        switch type {
        case .like: return .pink
        case .comment: return BrandPalette.neonBlue
        case .follow: return BrandPalette.neonGreen
        case .repost: return BrandPalette.accentPurple
        case .save: return BrandPalette.accentPink
        case .message: return BrandPalette.neonBlue
        case .verification: return .yellow
        case .moderation: return .orange
        }
    }

    private var primaryText: Color {
        BrandPalette.adaptiveTextPrimary(for: colorScheme)
    }

    private var secondaryText: Color {
        BrandPalette.adaptiveTextSecondary(for: colorScheme)
    }
}
