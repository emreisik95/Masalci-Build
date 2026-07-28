import MasalciCore
import SwiftUI

enum MasalTheme {
    static let night900 = Color(red: 7 / 255, green: 24 / 255, blue: 44 / 255)
    static let night800 = Color(red: 16 / 255, green: 40 / 255, blue: 74 / 255)
    static let night700 = Color(red: 25 / 255, green: 53 / 255, blue: 95 / 255)
    static let cream = Color(red: 1, green: 243 / 255, blue: 207 / 255)
    static let textPrimary = Color(red: 247 / 255, green: 249 / 255, blue: 252 / 255)
    static let textSecondary = Color(red: 184 / 255, green: 197 / 255, blue: 216 / 255)
    static let berry = Color(red: 201 / 255, green: 54 / 255, blue: 85 / 255)
    static let apricot = Color(red: 1, green: 155 / 255, blue: 100 / 255)
    static let lavender = Color(red: 158 / 255, green: 140 / 255, blue: 1)
    static let mint = Color(red: 105 / 255, green: 211 / 255, blue: 176 / 255)

    static let actionGradient = LinearGradient(
        colors: [berry, Color(red: 211 / 255, green: 63 / 255, blue: 80 / 255)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let nightGradient = LinearGradient(
        colors: [night900, Color(red: 13 / 255, green: 26 / 255, blue: 63 / 255)],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct NightSkyBackground: View {
    var body: some View {
        ZStack {
            MasalTheme.nightGradient

            Circle()
                .fill(MasalTheme.lavender.opacity(0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: 150, y: -260)

            Circle()
                .fill(MasalTheme.apricot.opacity(0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 70)
                .offset(x: -170, y: 300)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct MasalCardSurface: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .background(
                MasalTheme.night800.opacity(
                    AccessibilityPreferences.surfaceOpacity(
                        reduceTransparency: reduceTransparency
                    )
                ),
                in: RoundedRectangle(cornerRadius: 24)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(MasalTheme.cream.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.20), radius: 18, y: 10)
    }
}

extension View {
    func masalCard() -> some View {
        modifier(MasalCardSurface())
    }
}

struct MasalPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .padding(.horizontal, 18)
            .background(MasalTheme.actionGradient, in: Capsule())
            .shadow(color: MasalTheme.berry.opacity(0.35), radius: 14, y: 8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(
                AccessibilityPreferences.allowsMotion(reduceMotion: reduceMotion)
                    ? .snappy(duration: 0.2)
                    : nil,
                value: configuration.isPressed
            )
    }
}

private struct MasalReadableMaterialModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content.background(materialStyle)
    }

    private var materialStyle: AnyShapeStyle {
        reduceTransparency
            ? AnyShapeStyle(MasalTheme.night800)
            : AnyShapeStyle(.ultraThinMaterial)
    }
}

private struct MasalReadableMaterialShapeModifier<S: Shape>: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let shape: S

    func body(content: Content) -> some View {
        content.background(materialStyle, in: shape)
    }

    private var materialStyle: AnyShapeStyle {
        reduceTransparency
            ? AnyShapeStyle(MasalTheme.night800)
            : AnyShapeStyle(.ultraThinMaterial)
    }
}

extension View {
    func masalReadableMaterial() -> some View {
        modifier(MasalReadableMaterialModifier())
    }

    func masalReadableMaterial<S: Shape>(in shape: S) -> some View {
        modifier(MasalReadableMaterialShapeModifier(shape: shape))
    }
}
