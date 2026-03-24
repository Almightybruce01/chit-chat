import SwiftUI

struct OnboardingSlide: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
}

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("chitchat.onboarding.primaryMode") private var onboardingPrimaryModeRaw = PlatformMode.social.rawValue
    @AppStorage("chitchat.onboarding.enableLive") private var onboardingEnableLive = true
    @AppStorage("chitchat.onboarding.enableMarketplace") private var onboardingEnableMarketplace = true
    @AppStorage("chitchat.onboarding.enableCreatorKit") private var onboardingEnableCreatorKit = true
    @State private var index = 0

    private let slides: [OnboardingSlide] = [
        .init(
            title: "One App. Two Worlds.",
            subtitle: "Switch instantly between Social and Enterprise without losing identity control.",
            systemImage: "bubble.left.and.bubble.right.fill"
        ),
        .init(
            title: "Elite Creator Stack",
            subtitle: "Reels, collab posts, live DJ rooms, calls, and cross-platform linking.",
            systemImage: "film.stack.fill"
        ),
        .init(
            title: "Enterprise + Marketplace",
            subtitle: "Contracts, local hires, meetings, resumes, and market listings in one flow.",
            systemImage: "briefcase.fill"
        ),
        .init(
            title: "Safe by Design",
            subtitle: "Nudity is blocked by default and violent content requires consent to view.",
            systemImage: "checkmark.shield.fill"
        )
    ]

    var body: some View {
        ZStack {
            EliteBackground()

            VStack(spacing: 24) {
                HStack {
                    Button("Skip") {
                        finishOnboarding()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(secondaryText)
                    Spacer()
                    Text("Step \(index + 1) of \(slides.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(secondaryText)
                }
                .padding(.horizontal, 24)

                AppLogoView(size: 130, cornerRadius: 18)

                TabView(selection: $index) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { item in
                        slideCard(item.element)
                            .padding(.horizontal, 24)
                            .tag(item.offset)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.easeInOut, value: index)
                .frame(height: 370)

                onboardingChecklistCard

                HStack(spacing: 12) {
                    Button("Back") {
                        if index > 0 {
                            index -= 1
                        }
                    }
                    .font(.headline)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(BrandPalette.adaptiveCardBg(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(BrandPalette.adaptiveGlassStroke(for: colorScheme), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(primaryText)
                    .disabled(index == 0)

                    Button(action: primaryAction) {
                        Text(index == slides.count - 1 ? "Enter Chit Chat Social" : "Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(BrandPalette.neonGreen)
                            .foregroundStyle(.black.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
    }

    @ViewBuilder
    private func slideCard(_ slide: OnboardingSlide) -> some View {
        EliteCard {
            VStack(spacing: 18) {
                Image(systemName: slide.systemImage)
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(BrandPalette.neonBlue)
                    .padding(.top, 26)

                Text(slide.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(primaryText)

                Text(slide.subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(secondaryText)
                    .padding(.horizontal, 10)

                Spacer(minLength: 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func primaryAction() {
        if index == slides.count - 1 {
            finishOnboarding()
            return
        }
        index += 1
    }

    @ViewBuilder
    private var onboardingChecklistCard: some View {
        EliteCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Set up your launch defaults")
                    .font(.headline)
                    .foregroundStyle(primaryText)
                Picker("Primary mode", selection: $onboardingPrimaryModeRaw) {
                    Text("Social").tag(PlatformMode.social.rawValue)
                    Text("Corporate").tag(PlatformMode.enterprise.rawValue)
                }
                .pickerStyle(.segmented)
                Toggle("Enable Live toolkit", isOn: $onboardingEnableLive)
                    .foregroundStyle(secondaryText)
                Toggle("Enable Marketplace toolkit", isOn: $onboardingEnableMarketplace)
                    .foregroundStyle(secondaryText)
                Toggle("Enable Creator toolkit", isOn: $onboardingEnableCreatorKit)
                    .foregroundStyle(secondaryText)
            }
        }
        .padding(.horizontal, 24)
    }

    private var primaryText: Color {
        BrandPalette.adaptiveTextPrimary(for: colorScheme)
    }

    private var secondaryText: Color {
        BrandPalette.adaptiveTextSecondary(for: colorScheme)
    }

    private func finishOnboarding() {
        if onboardingPrimaryModeRaw == PlatformMode.enterprise.rawValue {
            appState.setMode(.enterprise)
        } else {
            appState.setMode(.social)
        }
        hasSeenOnboarding = true
    }
}
