import Foundation
import MasalciCore
import Observation

@MainActor
@Observable
final class HomeModel {
    private let apiClient: APIClient
    var stories: [Story] = []
    var categories: [String] = []
    var selectedCategory: String?
    var isLoading = false
    var errorMessage: String?

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    var featuredStory: Story? {
        stories.first(where: \.isFeatured) ?? stories.first
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let storyPage: StoryPage = apiClient.get(
                "/v1/stories",
                queryItems: selectedCategory.map { [URLQueryItem(name: "category", value: $0)] } ?? []
            )
            async let categoryPage: CategoryPage = apiClient.get("/v1/categories")
            let (loadedStories, loadedCategories) = try await (storyPage, categoryPage)
            stories = loadedStories.items
            categories = loadedCategories.items
        } catch is CancellationError {
            return
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Masallar şu anda yüklenemedi."
        }
    }
}

struct CategoryPage: Codable, Sendable {
    let items: [String]
}
