import SwiftUI

struct StoryArtwork: View {
    let title: String
    let categories: [String]
    let imageURL: URL?
    let baseURL: URL

    private var resolvedURL: URL? {
        guard let imageURL else { return nil }
        return imageURL.scheme == nil ? URL(string: imageURL.relativeString, relativeTo: baseURL)?.absoluteURL : imageURL
    }

    var body: some View {
        AsyncImage(url: resolvedURL) { phase in
            switch phase {
            case let .success(image):
                image.resizable().scaledToFill()
            default:
                placeholder
            }
        }
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: artworkColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(MasalTheme.cream.opacity(0.92))
                .frame(width: 72, height: 72)
                .blur(radius: 1)
                .offset(x: 62, y: -62)

            Image(systemName: artworkSymbol)
                .font(.system(size: 74, weight: .regular, design: .rounded))
                .symbolRenderingMode(.palette)
                .foregroundStyle(MasalTheme.cream, MasalTheme.apricot)
                .shadow(color: .black.opacity(0.25), radius: 8, y: 6)

            MoonPathDecoration()
                .padding(8)
        }
    }

    private var artworkSymbol: String {
        let joined = categories.joined(separator: " ").lowercased()
        if joined.contains("deniz") { return "fish.fill" }
        if joined.contains("dostluk") { return "hare.fill" }
        if joined.contains("macera") { return "paperplane.fill" }
        if joined.contains("uyku") { return "moon.stars.fill" }
        return "sparkles"
    }

    private var artworkColors: [Color] {
        let seed = abs(title.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) })
        switch seed % 4 {
        case 0:
            return [Color(red: 49 / 255, green: 97 / 255, blue: 145 / 255), MasalTheme.lavender]
        case 1:
            return [Color(red: 45 / 255, green: 112 / 255, blue: 116 / 255), MasalTheme.mint]
        case 2:
            return [Color(red: 91 / 255, green: 62 / 255, blue: 129 / 255), MasalTheme.apricot]
        default:
            return [MasalTheme.night700, MasalTheme.berry]
        }
    }
}
