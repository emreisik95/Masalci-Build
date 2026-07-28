import MasalciCore
import SwiftUI

struct StoryGrid: View {
    let stories: [Story]
    let apiBaseURL: URL

    private let columns = [
        GridItem(.adaptive(minimum: 155, maximum: 260), spacing: 14, alignment: .top),
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
            ForEach(stories) { story in
                NavigationLink {
                    StoryDetailView(story: story, apiBaseURL: apiBaseURL)
                } label: {
                    StoryCard(story: story, apiBaseURL: apiBaseURL)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct StoryCard: View {
    let story: Story
    let apiBaseURL: URL

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StoryArtwork(
                title: story.title,
                categories: story.categories,
                imageURL: story.imageURL,
                baseURL: apiBaseURL
            )
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            Text(story.title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(MasalTheme.cream)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            Text(story.categories.first ?? "Masal")
                .font(.caption.weight(.semibold))
                .foregroundStyle(MasalTheme.apricot)
        }
        .padding(10)
        .masalCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(story.title), \(story.categories.joined(separator: ", "))")
        .accessibilityHint("Masalı açar")
        .accessibilityIdentifier("masal-karti.\(story.id)")
    }
}
