import Foundation

public enum StoryDuration: String, Codable, CaseIterable, Sendable {
    case veryShort = "very_short"
    case short
    case medium
    case long

    public var title: String {
        switch self {
        case .veryShort: "Çok Kısa"
        case .short: "Kısa"
        case .medium: "Orta"
        case .long: "Uzun"
        }
    }
}

public enum GenerationState: String, Codable, Sendable {
    case queued
    case writing
    case illustrating
    case narrating
    case completed
    case failed
    case cancelled
}

public struct GenerationStoryReference: Codable, Equatable, Sendable {
    public let id: String
}

public struct GenerationStatus: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let state: GenerationState
    public let progress: Double
    public let statusMessage: String
    public let story: GenerationStoryReference?
    public let creditsRemaining: Int

    enum CodingKeys: String, CodingKey {
        case id
        case state = "status"
        case progress
        case statusMessage = "status_message"
        case story
        case creditsRemaining = "credits_remaining"
    }
}

public struct CreateGenerationRequest: Codable, Equatable, Sendable {
    public let prompt: String
    public let duration: StoryDuration
    public let characterIDs: [String]
    public let placeIDs: [String]
    public let voiceID: String?

    public init(
        prompt: String,
        duration: StoryDuration,
        characterIDs: [String],
        placeIDs: [String],
        voiceID: String?
    ) {
        self.prompt = prompt
        self.duration = duration
        self.characterIDs = characterIDs
        self.placeIDs = placeIDs
        self.voiceID = voiceID
    }

    enum CodingKeys: String, CodingKey {
        case prompt
        case duration
        case characterIDs = "character_ids"
        case placeIDs = "place_ids"
        case voiceID = "voice_id"
    }
}
