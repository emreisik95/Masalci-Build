import Foundation
import MasalciCore
import Observation

@MainActor
@Observable
final class CreateStoryModel {
    private static let maximumPollAttempts = 600
    private let apiClient: APIClient
    private let creditsChanged: @MainActor (Int) -> Void
    private var submissionKey: String?

    var prompt = ""
    var duration: StoryDuration = .medium
    var elements: [StoryElement] = []
    var selectedCharacterIDs: Set<String> = []
    var selectedPlaceIDs: Set<String> = []
    var selectedVoiceID: String?
    var generation: GenerationStatus?
    var completedStory: Story?
    var isLoadingElements = false
    var isSubmitting = false
    var errorMessage: String?

    init(apiClient: APIClient, creditsChanged: @escaping @MainActor (Int) -> Void) {
        self.apiClient = apiClient
        self.creditsChanged = creditsChanged
    }

    var characters: [StoryElement] { elements.filter { $0.kind == .character } }
    var places: [StoryElement] { elements.filter { $0.kind == .place } }
    var voices: [StoryElement] { elements.filter { $0.kind == .voice } }
    var canSubmit: Bool {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10 && !isSubmitting
    }

    func loadElements() async {
        guard elements.isEmpty else { return }
        isLoadingElements = true
        defer { isLoadingElements = false }
        do {
            let page: StoryElementPage = try await apiClient.get("/v1/story-elements")
            elements = page.items
        } catch {
            errorMessage = "Masal seçenekleri yüklenemedi. Yine de kendi fikrini yazabilirsin."
        }
    }

    func toggleCharacter(_ id: String) {
        if selectedCharacterIDs.contains(id) {
            selectedCharacterIDs.remove(id)
        } else if selectedCharacterIDs.count < 3 {
            selectedCharacterIDs.insert(id)
        }
    }

    func togglePlace(_ id: String) {
        if selectedPlaceIDs.contains(id) {
            selectedPlaceIDs.remove(id)
        } else if selectedPlaceIDs.count < 2 {
            selectedPlaceIDs.insert(id)
        }
    }

    func createStory() async {
        guard canSubmit else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        errorMessage = nil
        completedStory = nil
        let key = submissionKey ?? UUID().uuidString.lowercased()
        submissionKey = key

        do {
            let request = CreateGenerationRequest(
                prompt: prompt.trimmingCharacters(in: .whitespacesAndNewlines),
                duration: duration,
                characterIDs: Array(selectedCharacterIDs).sorted(),
                placeIDs: Array(selectedPlaceIDs).sorted(),
                voiceID: selectedVoiceID
            )
            let status: GenerationStatus = try await apiClient.send(
                "/v1/generations",
                method: .post,
                body: request,
                idempotencyKey: key
            )
            generation = status
            creditsChanged(status.creditsRemaining)
            try await followGeneration(id: status.id)
        } catch let error as APIError {
            if case let .server(code, _, _, _) = error, code == "CREDIT_REQUIRED" {
                errorMessage = "Yeni masal oluşturmak için kredi gerekiyor."
            } else if error != .cancelled {
                errorMessage = error.errorDescription
            }
        } catch is CancellationError {
            return
        } catch {
            errorMessage = "Masal şu anda oluşturulamadı. Lütfen yeniden deneyin."
        }
    }

    func resetAfterCompletion() {
        submissionKey = nil
        generation = nil
        completedStory = nil
        prompt = ""
    }

    private func followGeneration(id: String) async throws {
        for _ in 0..<Self.maximumPollAttempts {
            try Task.checkCancellation()
            let status: GenerationStatus = try await apiClient.get("/v1/generations/\(id)")
            generation = status
            creditsChanged(status.creditsRemaining)
            switch status.state {
            case .completed:
                guard let storyID = status.story?.id else {
                    throw APIError.invalidResponse
                }
                completedStory = try await apiClient.get("/v1/stories/\(storyID)")
                submissionKey = nil
                return
            case .failed:
                submissionKey = nil
                throw APIError.server(
                    code: "GENERATION_FAILED",
                    message: status.statusMessage,
                    requestID: nil,
                    statusCode: 500
                )
            case .cancelled:
                submissionKey = nil
                throw APIError.cancelled
            default:
                try await Task.sleep(for: .seconds(1))
            }
        }
        throw APIError.server(
            code: "GENERATION_TIMEOUT",
            message: "Masalın hazırlanması beklenenden uzun sürüyor. Biraz sonra yeniden deneyin.",
            requestID: nil,
            statusCode: 504
        )
    }
}
