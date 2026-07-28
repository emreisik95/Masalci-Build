import Foundation

public enum StoryElementKind: String, Codable, Sendable {
    case character
    case place
    case voice
}

public struct StoryElement: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let kind: StoryElementKind
    public let name: String
    public let description: String?
    public let imageURL: URL?
    public let previewAudioURL: URL?
    public let tags: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case name
        case description
        case imageURL = "image_url"
        case previewAudioURL = "preview_audio_url"
        case tags
    }
}

public struct StoryElementPage: Codable, Equatable, Sendable {
    public let items: [StoryElement]
}

public struct FavoriteState: Codable, Equatable, Sendable {
    public let isFavorite: Bool
    public let likesCount: Int

    enum CodingKeys: String, CodingKey {
        case isFavorite = "is_favorite"
        case likesCount = "likes_count"
    }
}

public struct StoryViewState: Codable, Equatable, Sendable {
    public let viewCount: Int

    enum CodingKeys: String, CodingKey {
        case viewCount = "view_count"
    }
}
