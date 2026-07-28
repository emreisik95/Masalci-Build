import MasalciCore
import SwiftUI

struct FeaturedStoryView: View {
    let story: Story
    let apiBaseURL: URL

    var body: some View {
        NavigationLink {
            StoryDetailView(story: story, apiBaseURL: apiBaseURL)
        } label: {
            ZStack(alignment: .bottomLeading) {
                StoryArtwork(
                    title: story.title,
                    categories: story.categories,
                    imageURL: story.imageURL,
                    baseURL: apiBaseURL
                )
                .frame(height: 330)
                .clipped()

                LinearGradient(
                    colors: [.clear, MasalTheme.night900.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 9) {
                    Label("Bu gecenin masalı", systemImage: "sparkles")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MasalTheme.apricot)
                    Text(story.title)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(MasalTheme.cream)
                        .multilineTextAlignment(.leading)
                    Text(story.summary)
                        .font(.subheadline)
                        .foregroundStyle(MasalTheme.textSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    Label("Masalı aç", systemImage: "play.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 46)
                        .background(MasalTheme.actionGradient, in: Capsule())
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .overlay {
                RoundedRectangle(cornerRadius: 30)
                    .stroke(MasalTheme.cream.opacity(0.15))
            }
            .shadow(color: .black.opacity(0.28), radius: 22, y: 12)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Bu gecenin masalı: \(story.title). \(story.summary)")
        .accessibilityHint("Masalı açar")
        .accessibilityIdentifier("ana-sayfa.one-cikan-masal")
    }
}
