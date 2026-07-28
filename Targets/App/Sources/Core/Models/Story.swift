import Foundation

public struct Story: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    public let content: String?
    public let imageURL: URL?
    public let audioURL: URL?
    public let categories: [String]
    public let isFeatured: Bool
    public let viewCount: Int
    public let likesCount: Int
    public let isFavorite: Bool
    public let publishedAt: Date

    public init(
        id: String,
        title: String,
        summary: String,
        content: String? = nil,
        imageURL: URL? = nil,
        audioURL: URL? = nil,
        categories: [String],
        isFeatured: Bool,
        viewCount: Int,
        likesCount: Int,
        isFavorite: Bool,
        publishedAt: Date
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.content = content
        self.imageURL = imageURL
        self.audioURL = audioURL
        self.categories = categories
        self.isFeatured = isFeatured
        self.viewCount = viewCount
        self.likesCount = likesCount
        self.isFavorite = isFavorite
        self.publishedAt = publishedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case summary
        case content
        case imageURL = "image_url"
        case audioURL = "audio_url"
        case categories
        case isFeatured = "is_featured"
        case viewCount = "view_count"
        case likesCount = "likes_count"
        case isFavorite = "is_favorite"
        case publishedAt = "published_at"
    }
}

public struct StoryPage: Codable, Equatable, Sendable {
    public let items: [Story]
    public let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case items
        case nextCursor = "next_cursor"
    }
}
