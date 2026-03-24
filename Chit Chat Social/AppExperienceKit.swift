//
//  AppExperienceKit.swift
//  Chit Chat Social
//
//  HIG-aligned layout, touch targets, and reusable home/search chrome.
//  References: Apple HIG — ~44×44pt minimum controls, spacing, Dynamic Type.
//

import SwiftUI

// MARK: - Documented UX constants (aspects your app should honor)

/// Namespace for product-wide UX constraints — use these instead of magic numbers.
enum UXPolicy {
    /// Minimum tappable area (Apple Human Interface Guidelines).
    static let minTouchTarget: CGFloat = 44
    /// 8-point grid for padding and gaps.
    static let grid: CGFloat = 8
    static var spaceXS: CGFloat { grid }
    static var spaceSM: CGFloat { grid * 1.5 }
    static var spaceMD: CGFloat { grid * 2 }
    static var spaceLG: CGFloat { grid * 2.5 }
    static var spaceXL: CGFloat { grid * 3 }
    /// Primary content column cap on regular width (readability).
    static let readableContentMaxWidth: CGFloat = 560
}

// MARK: - Touch target

struct MinimumTouchTargetModifier: ViewModifier {
    var minSize: CGFloat = UXPolicy.minTouchTarget

    func body(content: Content) -> some View {
        content
            .frame(minWidth: minSize, minHeight: minSize)
            .contentShape(Rectangle())
    }
}

extension View {
    /// Ensures at least 44×44 pt hit area (label can be smaller visually inside).
    func minimumInteractiveTarget(_ size: CGFloat = UXPolicy.minTouchTarget) -> some View {
        modifier(MinimumTouchTargetModifier(minSize: size))
    }
}

// MARK: - Readable width (iPad / landscape)

struct ReadableWidthModifier: ViewModifier {
    var maxWidth: CGFloat = UXPolicy.readableContentMaxWidth

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    func readableContentWidth(_ max: CGFloat = UXPolicy.readableContentMaxWidth) -> some View {
        modifier(ReadableWidthModifier(maxWidth: max))
    }
}

// MARK: - Home hero

/// Top-of-home context: greeting, locality, manual refresh (discoverability).
struct HomeWelcomeHeader: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var onRefresh: () -> Void

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hey"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: UXPolicy.spaceMD) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(greeting), \(appState.currentUser.displayName.split(separator: " ").first.map(String.init) ?? "there")")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BrandPalette.neonBlue)
                    Text(appState.localCity)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Local city \(appState.localCity)")
            }
            Spacer(minLength: 8)
            Button {
                HapticTokens.light()
                onRefresh()
            } label: {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 28 : 24, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(BrandPalette.neonGreen)
            }
            .minimumInteractiveTarget()
            .accessibilityLabel("Refresh feed")
            .accessibilityHint("Updates the feed and scroll position")
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Feed control deck (one-tap lens + sort + surface)

/// Replaces buried confirmation dialogs with always-visible, large controls.
struct FeedControlDeck: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var surface: PostSurfaceStyle
    @Binding var lens: FeedLens
    @Binding var sort: FeedSortMode

    var body: some View {
        VStack(alignment: .leading, spacing: UXPolicy.spaceSM) {
            Text("Your feed")
                .font(.caption.weight(.bold))
                .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                .textCase(.uppercase)
                .tracking(0.6)

            Picker("Post style", selection: $surface) {
                Text("Chit").tag(PostSurfaceStyle.chit)
                Text("Chat").tag(PostSurfaceStyle.chat)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Feed surface")
            .padding(.vertical, 2)

            Text("Lens")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FeedLens.allCases) { item in
                        lensChip(item)
                            .frame(minWidth: 108)
                    }
                }
            }

            Text("Sort")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FeedSortMode.allCases, id: \.self) { mode in
                        sortChip(mode)
                            .frame(minWidth: 100)
                    }
                }
            }
        }
        .padding(LayoutTokens.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: LayoutTokens.cardRadius, style: .continuous)
                .fill(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LayoutTokens.cardRadius, style: .continuous)
                .stroke(BrandPalette.adaptiveGlassStroke(for: colorScheme), lineWidth: 1)
        )
        .shadow(
            color: (colorScheme == .light ? Color.black : BrandPalette.neonBlue).opacity(colorScheme == .light ? 0.06 : 0.12),
            radius: 14,
            y: 5
        )
    }

    private func lensChip(_ item: FeedLens) -> some View {
        let selected = lens == item
        let flatFill = BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.55)
        return Button {
            HapticTokens.light()
            lens = item
        } label: {
            HStack(spacing: 6) {
                Image(systemName: item.systemImage)
                    .font(.caption.weight(.bold))
                Text(item.label)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(selected ? Color.black.opacity(0.88) : BrandPalette.adaptiveTextPrimary(for: colorScheme))
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        selected
                            ? LinearGradient(colors: [BrandPalette.neonBlue, BrandPalette.neonGreen.opacity(0.92)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [flatFill, flatFill], startPoint: .top, endPoint: .bottom)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        selected ? Color.clear : BrandPalette.adaptiveGlassStroke(for: colorScheme).opacity(0.9),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.label) lens")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private func sortChip(_ mode: FeedSortMode) -> some View {
        let selected = sort == mode
        let flatFill = BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.55)
        return Button {
            HapticTokens.light()
            sort = mode
        } label: {
            Text(mode.displayTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(selected ? Color.black.opacity(0.88) : BrandPalette.adaptiveTextPrimary(for: colorScheme))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            selected
                                ? LinearGradient(colors: [BrandPalette.accentPink.opacity(0.95), BrandPalette.accentPurple.opacity(0.88)], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [flatFill, flatFill], startPoint: .top, endPoint: .bottom)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            selected ? Color.clear : BrandPalette.adaptiveGlassStroke(for: colorScheme).opacity(0.85),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sort by \(mode.displayTitle)")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

// MARK: - Collapsible shortcuts (reduces visual noise)

struct CollapsibleShortcutRail<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isExpanded: Bool
    let title: String
    let collapsedSummary: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(MotionTokens.spring) {
                    isExpanded.toggle()
                }
                HapticTokens.light()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
                        if !isExpanded {
                            Text(collapsedSummary)
                                .font(.caption)
                                .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                                .lineLimit(2)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(BrandPalette.neonBlue)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(MotionTokens.spring, value: isExpanded)
                }
                .padding(LayoutTokens.cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: LayoutTokens.cardRadius, style: .continuous)
                        .fill(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.88))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutTokens.cardRadius, style: .continuous)
                        .stroke(BrandPalette.adaptiveGlassStroke(for: colorScheme), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "Collapse \(title)" : "Expand \(title)")

            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Search bar chrome

struct DiscoverSearchField: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var text: String
    var placeholder: String = "Search people, tags, audio…"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.semibold))
                .foregroundStyle(BrandPalette.neonBlue)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
            if !text.isEmpty {
                Button {
                    text = ""
                    HapticTokens.light()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
                }
                .minimumInteractiveTarget(36)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(BrandPalette.adaptiveGlassStroke(for: colorScheme), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}
