import Foundation
import MasalciCore
import Observation

@MainActor
@Observable
final class FavoritesModel {
    private let apiClient: APIClient
    var stories: [Story] = []
    var isLoading = false
    var errorMessage: String?

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let page: StoryPage = try await apiClient.get("/v1/favorites")
            stories = page.items
        } catch is CancellationError {
            return
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Favoriler şu anda yüklenemedi."
        }
    }
}
