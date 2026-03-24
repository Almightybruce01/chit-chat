import SwiftUI

struct CreatorGuideView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                EliteBackground()
                List {
                    Section("How to Post") {
                        guideRow("1. Open the Post tab", "Tap `Post` from the tab bar.")
                        guideRow("2. Pick your content type", "Choose post, reel, story, or short.")
                        guideRow("3. Add caption + publish", "Write a caption and press publish.")
                    }

                    Section("How to Go Live") {
                        guideRow("1. Open Home", "Tap the Home tab.")
                        guideRow("2. Tap live studio button", "Use the top-right studio icon.")
                        guideRow("3. Choose your live mode", "Start social live, DJ room, or business session.")
                    }

                    Section("Pro Tips") {
                        guideRow("Use music smartly", "Open Music from bottom quick actions while creating content.")
                        guideRow("Switch platform mode", "Use the bottom mode button to flip Social / Enterprise.")
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle("Creator Guide")
        }
    }

    @ViewBuilder
    private func guideRow(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(BrandPalette.adaptiveTextSecondary(for: colorScheme))
        }
        .listRowBackground(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.65))
    }
}
