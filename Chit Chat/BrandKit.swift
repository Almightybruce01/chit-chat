import SwiftUI
import UIKit

enum BrandPalette {
    static let bgStart = Color(red: 0.10, green: 0.13, blue: 0.30)
    static let bgMid = Color(red: 0.09, green: 0.43, blue: 0.62)
    static let bgEnd = Color(red: 0.30, green: 0.25, blue: 0.66)
    static let neonBlue = Color(red: 0.52, green: 0.91, blue: 1.0)
    static let neonGreen = Color(red: 0.58, green: 1.0, blue: 0.82)
    static let accentPurple = Color(red: 0.78, green: 0.63, blue: 1.0)
    static let accentPink = Color(red: 1.0, green: 0.53, blue: 0.84)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.82)
    static let cardBg = Color(red: 0.10, green: 0.15, blue: 0.31).opacity(0.72)
    static let glassStroke = Color.white.opacity(0.28)

    static func adaptiveCardBg(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .light {
            return Color.white.opacity(0.9)
        }
        return cardBg
    }

    static func adaptiveGlassStroke(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .light {
            return Color.black.opacity(0.08)
        }
        return glassStroke
    }

    static func adaptiveTextPrimary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .light ? Color.black.opacity(0.9) : textPrimary
    }

    static func adaptiveTextSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .light ? Color.black.opacity(0.68) : textSecondary
    }
}

enum LayoutTokens {
    /// 8pt grid — Apple HIG spacing rhythm.
    static let screenHorizontal: CGFloat = 16
    static let cardRadius: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let sectionGap: CGFloat = 16
    /// Minimum interactive target (Human Interface Guidelines).
    static let minTouchTarget: CGFloat = 44
    /// Max width for primary reading column on iPad / large phones in landscape.
    static let readableMaxWidth: CGFloat = 560
}

enum TypeTokens {
    static let title = Font.title3.bold()
    static let body = Font.body
    static let caption = Font.caption
    static let micro = Font.caption2
}

enum MotionTokens {
    static let quick = 0.18
    static let normal = 0.28
    static let slow = 0.38
    static let spring = Animation.spring(response: 0.34, dampingFraction: 0.82)
    static let premiumSpring = Animation.spring(response: 0.42, dampingFraction: 0.86)
}

enum HapticTokens {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct ElitePillButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.bold())
            .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(BrandPalette.adaptiveCardBg(for: colorScheme).opacity(configuration.isPressed ? 0.72 : 0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(BrandPalette.adaptiveGlassStroke(for: colorScheme), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: MotionTokens.quick), value: configuration.isPressed)
    }
}

struct EliteBackground: View {
    var body: some View {
        CinematicBackgroundView()
            .ignoresSafeArea()
    }
}

struct CinematicBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            GeometryReader { proxy in
                let size = proxy.size
                ZStack {
                    baseGradient
                    movingOrb(
                        color: BrandPalette.neonBlue.opacity(colorScheme == .light ? 0.18 : 0.28),
                        diameter: min(size.width, size.height) * 0.78,
                        x: size.width * (0.18 + 0.10 * sin(t * 0.12)),
                        y: size.height * (0.20 + 0.08 * cos(t * 0.17))
                    )
                    movingOrb(
                        color: BrandPalette.accentPink.opacity(colorScheme == .light ? 0.14 : 0.24),
                        diameter: min(size.width, size.height) * 0.66,
                        x: size.width * (0.82 + 0.11 * cos(t * 0.10)),
                        y: size.height * (0.24 + 0.09 * sin(t * 0.15))
                    )
                    movingOrb(
                        color: BrandPalette.neonGreen.opacity(colorScheme == .light ? 0.12 : 0.20),
                        diameter: min(size.width, size.height) * 0.74,
                        x: size.width * (0.54 + 0.14 * sin(t * 0.08)),
                        y: size.height * (0.83 + 0.08 * cos(t * 0.13))
                    )
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .light ? 0.16 : 0.03),
                            Color.black.opacity(colorScheme == .light ? 0.04 : 0.26)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .drawingGroup()
            }
        }
    }

    private var baseGradient: some View {
        LinearGradient(
            colors: colorScheme == .light
                ? [
                    Color(red: 0.99, green: 0.995, blue: 1.0),
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.92, green: 0.96, blue: 1.0)
                ]
                : [
                    Color(red: 0.03, green: 0.04, blue: 0.08),
                    BrandPalette.bgMid.opacity(0.95),
                    BrandPalette.bgEnd.opacity(0.95)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func movingOrb(color: Color, diameter: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: diameter, height: diameter)
            .blur(radius: diameter * 0.13)
            .position(x: x, y: y)
    }
}

struct AppLogoView: View {
    var size: CGFloat = 150
    var cornerRadius: CGFloat = 22

    var body: some View {
        Group {
            if let uiImage = resolvedAppIcon {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.clear
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            if resolvedAppIcon != nil {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(BrandPalette.glassStroke, lineWidth: 1.0)
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
    }

    private var resolvedAppIcon: UIImage? {
        if let byName = UIImage(named: "AppIcon-1024") { return byName }
        if let bySet = UIImage(named: "AppIcon") { return bySet }
        if
            let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let files = primary["CFBundleIconFiles"] as? [String],
            let best = files.last,
            let byIconFile = UIImage(named: best)
        {
            return byIconFile
        }
        if let path = Bundle.main.path(forResource: "AppIcon-1024", ofType: "png") {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }
}

struct OrbitLogoMark: View {
    var body: some View {
        ZStack {
            Ellipse()
                .stroke(BrandPalette.neonGreen.opacity(0.9), lineWidth: 18)

            Ellipse()
                .stroke(BrandPalette.neonBlue.opacity(0.95), lineWidth: 18)
                .rotationEffect(.degrees(90))

            Circle()
                .fill(Color(red: 0.83, green: 0.91, blue: 0.91))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(52)

            ChatBubbleGlyph()
                .fill(Color(red: 0.00, green: 0.06, blue: 0.11))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(74)

            HStack(spacing: 12) {
                Circle()
                    .fill(BrandPalette.neonGreen)
                    .frame(width: 14, height: 14)
                Circle()
                    .fill(BrandPalette.neonBlue)
                    .frame(width: 14, height: 14)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct ChatBubbleGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let corner = min(rect.width, rect.height) * 0.32
        let bubble = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: rect.height * 0.82
        )
        path.addRoundedRect(in: bubble, cornerSize: CGSize(width: corner, height: corner))

        path.move(to: CGPoint(x: rect.minX + rect.width * 0.20, y: bubble.maxY - rect.height * 0.04))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.43, y: bubble.maxY))
        path.closeSubpath()
        return path
    }
}

struct EliteSectionCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(14)
            .padding(LayoutTokens.cardPadding - 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
            .background(
                LinearGradient(
                    colors: [
                        BrandPalette.adaptiveCardBg(for: colorScheme),
                        BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(BrandPalette.adaptiveGlassStroke(for: colorScheme), lineWidth: 1.1)
            )
            .shadow(color: (colorScheme == .light ? .black : BrandPalette.neonBlue).opacity(colorScheme == .light ? 0.08 : 0.16), radius: 9, y: 3)
            .clipShape(RoundedRectangle(cornerRadius: LayoutTokens.cardRadius))
    }
}

struct EliteTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(uiColor: .secondarySystemBackground).opacity(0.98))
            .overlay(
                RoundedRectangle(cornerRadius: 11)
                    .stroke(Color(uiColor: .separator).opacity(0.45), lineWidth: 1.1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 11))
            .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
    }
}

struct EliteCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .foregroundStyle(BrandPalette.adaptiveTextPrimary(for: colorScheme))
            .background(
                LinearGradient(
                    colors: [
                        BrandPalette.adaptiveCardBg(for: colorScheme),
                        BrandPalette.adaptiveCardBg(for: colorScheme).opacity(0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(BrandPalette.adaptiveGlassStroke(for: colorScheme), lineWidth: 1.2)
            )
            .shadow(
                color: (colorScheme == .light ? .black : BrandPalette.neonBlue)
                    .opacity(colorScheme == .light ? 0.08 : 0.2),
                radius: 12,
                y: 4
            )
            .shadow(color: .black.opacity(colorScheme == .light ? 0.08 : 0.25), radius: 6, y: 3)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct NeonPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.black.opacity(0.86))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [BrandPalette.neonGreen, BrandPalette.neonBlue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(BrandPalette.glassStroke, lineWidth: 1)
            )
            .shadow(color: BrandPalette.neonBlue.opacity(configuration.isPressed ? 0.15 : 0.3), radius: 10, y: 3)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: MotionTokens.quick), value: configuration.isPressed)
    }
}

struct FuturisticSectionHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(colorScheme == .light ? Color.black : BrandPalette.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(colorScheme == .light ? Color.black.opacity(0.65) : BrandPalette.textSecondary)
            }
        }
    }
}

enum EnterprisePalette {
    static let bgTop = Color(red: 0.07, green: 0.09, blue: 0.12)
    static let bgBottom = Color(red: 0.12, green: 0.14, blue: 0.18)
    static let panel = Color(red: 0.15, green: 0.17, blue: 0.22).opacity(0.92)
    static let stroke = Color.white.opacity(0.10)
    static let textPrimary = Color.white.opacity(0.94)
    static let textSecondary = Color.white.opacity(0.72)
    static let action = Color(red: 0.35, green: 0.71, blue: 0.98)
    static let success = Color(red: 0.42, green: 0.82, blue: 0.58)
}

struct EnterpriseBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                ZStack {
                    LinearGradient(
                        colors: [EnterprisePalette.bgTop, EnterprisePalette.bgBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    RoundedRectangle(cornerRadius: 280, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: width * 0.72, height: height * 0.42)
                        .rotationEffect(.degrees(-18))
                        .offset(x: -width * 0.22 + CGFloat(sin(t * 0.08) * 10), y: -height * 0.30)
                    RoundedRectangle(cornerRadius: 280, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .frame(width: width * 0.86, height: height * 0.34)
                        .rotationEffect(.degrees(12))
                        .offset(x: width * 0.28 + CGFloat(cos(t * 0.07) * 10), y: height * 0.20)
                }
                .drawingGroup()
            }
        }
        .ignoresSafeArea()
    }
}

struct EnterpriseCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(EnterprisePalette.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(EnterprisePalette.stroke, lineWidth: 1)
            )
    }
}

struct EnterprisePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(EnterprisePalette.action.opacity(configuration.isPressed ? 0.78 : 1.0))
            )
    }
}

struct SnappyScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1.0)
            .animation(.easeInOut(duration: MotionTokens.quick), value: configuration.isPressed)
    }
}
