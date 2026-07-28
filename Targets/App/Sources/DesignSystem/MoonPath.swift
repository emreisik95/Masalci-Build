import SwiftUI

struct MoonPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY * 0.78))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.22),
            control1: CGPoint(x: rect.width * 0.28, y: rect.height * 0.30),
            control2: CGPoint(x: rect.width * 0.65, y: rect.height * 0.94)
        )
        return path
    }
}

struct MoonPathDecoration: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shimmer = false

    var body: some View {
        MoonPath()
            .trim(from: 0.05, to: 0.95)
            .stroke(
                LinearGradient(
                    colors: [MasalTheme.lavender.opacity(0), MasalTheme.cream, MasalTheme.apricot.opacity(0)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [3, 8])
            )
            .opacity(shimmer ? 0.85 : 0.42)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                value: shimmer
            )
            .onAppear { shimmer = true }
            .accessibilityHidden(true)
    }
}
