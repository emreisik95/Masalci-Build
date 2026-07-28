import Foundation

public struct APIErrorEnvelope: Codable, Equatable, Sendable {
    public let error: APIErrorPayload
}

public struct APIErrorPayload: Codable, Equatable, Sendable {
    public let code: String
    public let message: String
    public let requestID: String

    enum CodingKeys: String, CodingKey {
        case code
        case message
        case requestID = "request_id"
    }
}

public enum APIError: Error, Equatable, LocalizedError, Sendable {
    case invalidURL
    case transport
    case cancelled
    case unauthorized(message: String, requestID: String?)
    case server(code: String, message: String, requestID: String?, statusCode: Int)
    case invalidResponse
    case decoding

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Sunucu adresi geçerli değil."
        case .transport:
            "İnternet bağlantısı kurulamadı. Lütfen yeniden deneyin."
        case .cancelled:
            "İşlem iptal edildi."
        case let .unauthorized(message, _), let .server(_, message, _, _):
            message
        case .invalidResponse, .decoding:
            "Sunucudan gelen yanıt okunamadı. Lütfen yeniden deneyin."
        }
    }
}
