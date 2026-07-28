import Foundation
import MasalciCore
import Observation

@MainActor
@Observable
final class StoryDetailModel {
    private let apiClient: APIClient
    private var didRecordView = false
    var story: Story
    var isFavorite: Bool
    var likesCount: Int
    var isLoading = false
    var isUpdatingFavorite = false
    var errorMessage: String?

    init(story: Story, apiClient: APIClient) {
        self.story = story
        self.apiClient = apiClient
        self.isFavorite = story.isFavorite
        self.likesCount = story.likesCount
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let detail: Story = try await apiClient.get("/v1/stories/\(story.id)")
            story = detail
            isFavorite = detail.isFavorite
            likesCount = detail.likesCount
            await recordViewIfNeeded()
        } catch is CancellationError {
            return
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
        }
    }

    func toggleFavorite() async {
        guard !isUpdatingFavorite else { return }
        isUpdatingFavorite = true
        defer { isUpdatingFavorite = false }
        let previousFavorite = isFavorite
        let previousLikes = likesCount
        isFavorite.toggle()
        likesCount = max(0, likesCount + (isFavorite ? 1 : -1))
        do {
            let response: FavoriteState = try await apiClient.send(
                "/v1/stories/\(story.id)/favorite",
                method: isFavorite ? .put : .delete
            )
            isFavorite = response.isFavorite
            likesCount = response.likesCount
        } catch {
            isFavorite = previousFavorite
            likesCount = previousLikes
            errorMessage = "Favori değişikliği kaydedilemedi. Lütfen yeniden deneyin."
        }
    }

    private func recordViewIfNeeded() async {
        guard !didRecordView else { return }
        didRecordView = true
        do {
            let response: StoryViewState = try await apiClient.send(
                "/v1/stories/\(story.id)/views",
                method: .post,
                idempotencyKey: "view-\(story.id)-\(UUID().uuidString)"
            )
            _ = response
        } catch {
            didRecordView = false
        }
    }
}
