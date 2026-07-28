import Foundation

public enum HTTPMethod: String, Sendable {
    case delete = "DELETE"
    case get = "GET"
    case post = "POST"
    case put = "PUT"
}

private actor ResponseCache {
    struct Entry: Sendable {
        let data: Data
        let etag: String?
    }

    private var entries: [URL: Entry] = [:]

    func entry(for url: URL) -> Entry? {
        entries[url]
    }

    func store(_ data: Data, etag: String?, for url: URL) {
        entries[url] = Entry(data: data, etag: etag)
    }
}

public final class APIClient: @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let sessionStore: any SessionStoring
    private let retryDelayNanoseconds: UInt64
    private let cache = ResponseCache()

    public init(
        baseURL: URL,
        session: URLSession = .shared,
        sessionStore: any SessionStoring,
        retryDelayNanoseconds: UInt64 = 250_000_000
    ) {
        self.baseURL = baseURL
        self.session = session
        self.sessionStore = sessionStore
        self.retryDelayNanoseconds = retryDelayNanoseconds
    }

    public func get<Response: Decodable & Sendable>(
        _ path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> Response {
        try await perform(
            path: path,
            method: .get,
            queryItems: queryItems,
            body: nil,
            idempotencyKey: nil
        )
    }

    public func send<Response: Decodable & Sendable, Body: Encodable & Sendable>(
        _ path: String,
        method: HTTPMethod,
        body: Body,
        idempotencyKey: String? = nil
    ) async throws -> Response {
        let encoded: Data
        do {
            encoded = try MasalJSON.encoder.encode(body)
        } catch {
            throw APIError.invalidResponse
        }
        return try await perform(
            path: path,
            method: method,
            queryItems: [],
            body: encoded,
            idempotencyKey: idempotencyKey
        )
    }

    public func send<Response: Decodable & Sendable>(
        _ path: String,
        method: HTTPMethod,
        idempotencyKey: String? = nil
    ) async throws -> Response {
        try await perform(
            path: path,
            method: method,
            queryItems: [],
            body: nil,
            idempotencyKey: idempotencyKey
        )
    }

    public func sendWithoutResponse(_ path: String, method: HTTPMethod) async throws {
        let url = try makeURL(path: path, queryItems: [])
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = try await sessionStore.loadToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            if (200..<300).contains(http.statusCode) {
                return
            }
            if http.statusCode == 401 {
                try await sessionStore.clearToken()
            }
            throw decodeServerError(data: data, statusCode: http.statusCode)
        } catch is CancellationError {
            throw APIError.cancelled
        } catch let error as APIError {
            throw error
        } catch let error as URLError where error.code == .cancelled {
            throw APIError.cancelled
        } catch {
            throw APIError.transport
        }
    }

    private func perform<Response: Decodable & Sendable>(
        path: String,
        method: HTTPMethod,
        queryItems: [URLQueryItem],
        body: Data?,
        idempotencyKey: String?
    ) async throws -> Response {
        let url = try makeURL(path: path, queryItems: queryItems)
        let cached = method == .get ? await cache.entry(for: url) : nil
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let token = try await sessionStore.loadToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let idempotencyKey {
            request.setValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key")
        }
        if let etag = cached?.etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        let maximumAttempts = method == .get ? 2 : 1
        var attempt = 0
        while attempt < maximumAttempts {
            attempt += 1
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                if http.statusCode == 304, let cached {
                    return try decode(Response.self, from: cached.data)
                }
                if (200..<300).contains(http.statusCode) {
                    if method == .get {
                        await cache.store(
                            data,
                            etag: http.value(forHTTPHeaderField: "ETag"),
                            for: url
                        )
                    }
                    return try decode(Response.self, from: data)
                }
                if http.statusCode == 401 {
                    try await sessionStore.clearToken()
                }
                if method == .get,
                   attempt < maximumAttempts,
                   [502, 503, 504].contains(http.statusCode) {
                    try await waitBeforeRetry()
                    continue
                }
                throw decodeServerError(data: data, statusCode: http.statusCode)
            } catch is CancellationError {
                throw APIError.cancelled
            } catch let error as APIError {
                throw error
            } catch let error as URLError {
                if error.code == .cancelled {
                    throw APIError.cancelled
                }
                if method == .get, attempt < maximumAttempts {
                    try await waitBeforeRetry()
                    continue
                }
                throw APIError.transport
            } catch {
                throw APIError.transport
            }
        }
        throw APIError.transport
    }

    private func makeURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let url = baseURL.appendingPathComponent(cleanPath)
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let result = components.url else {
            throw APIError.invalidURL
        }
        return result
    }

    private func decode<Response: Decodable>(_ type: Response.Type, from data: Data) throws -> Response {
        do {
            return try MasalJSON.decoder.decode(type, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    private func decodeServerError(data: Data, statusCode: Int) -> APIError {
        guard let envelope = try? MasalJSON.decoder.decode(APIErrorEnvelope.self, from: data) else {
            return .server(
                code: "HTTP_\(statusCode)",
                message: "İşlem şu anda tamamlanamadı. Lütfen yeniden deneyin.",
                requestID: nil,
                statusCode: statusCode
            )
        }
        if statusCode == 401 {
            return .unauthorized(
                message: envelope.error.message,
                requestID: envelope.error.requestID
            )
        }
        return .server(
            code: envelope.error.code,
            message: envelope.error.message,
            requestID: envelope.error.requestID,
            statusCode: statusCode
        )
    }

    private func waitBeforeRetry() async throws {
        guard retryDelayNanoseconds > 0 else { return }
        try await Task.sleep(nanoseconds: retryDelayNanoseconds)
    }
}
