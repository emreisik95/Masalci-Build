import Foundation
import Testing

@testable import MasalciCore

@Suite(.serialized)
struct APIClientTests {
    @Test
    func addsBearerToken() async throws {
        defer { MockURLProtocol.recorder = nil }
        let store = InMemorySessionStore(token: "oturum-tokeni")
        let recorder = RequestRecorder { request, _ in
            #expect(
                request.value(forHTTPHeaderField: "Authorization") ==
                    "Bearer oturum-tokeni"
            )
            return Self.response(request, status: 200, body: Self.userBody)
        }
        let client = Self.client(store: store, recorder: recorder)

        let profile: UserProfile = try await client.get("/v1/me")
        #expect(profile.credits == 5)
    }

    @Test
    func clearsSessionOnUnauthorized() async throws {
        defer { MockURLProtocol.recorder = nil }
        let store = InMemorySessionStore(token: "eski-token")
        let recorder = RequestRecorder { request, _ in
            Self.response(
                request,
                status: 401,
                body: Data(
                    """
                    {"error":{"code":"AUTH_REQUIRED","message":"Devam etmek için oturum açın.","request_id":"req-401"}}
                    """.utf8
                )
            )
        }
        let client = Self.client(store: store, recorder: recorder)

        do {
            let _: UserProfile = try await client.get("/v1/me")
            Issue.record("401 yanıtı hata üretmeliydi.")
        } catch let error as APIError {
            guard case .unauthorized = error else {
                Issue.record("Beklenmeyen hata: \(error)")
                return
            }
        }
        let token = await store.loadToken()
        #expect(token == nil)
    }

    @Test
    func doesNotRetryGenerationPost() async throws {
        defer { MockURLProtocol.recorder = nil }
        let recorder = RequestRecorder { request, _ in
            #expect(
                request.value(forHTTPHeaderField: "Idempotency-Key") ==
                    "tek-istek-anahtari"
            )
            return Self.response(request, status: 503, body: Data())
        }
        let client = Self.client(store: InMemorySessionStore(), recorder: recorder)
        let body = CreateGenerationRequest(
            prompt: "Ay ışığında dostluğu anlatan sıcak bir masal.",
            duration: .short,
            characterIDs: [],
            placeIDs: [],
            voiceID: nil
        )

        do {
            let _: GenerationStatus = try await client.send(
                "/v1/generations",
                method: .post,
                body: body,
                idempotencyKey: "tek-istek-anahtari"
            )
            Issue.record("503 yanıtı hata üretmeliydi.")
        } catch is APIError {
            // Beklenen hata.
        }
        let count = await recorder.requestCount
        #expect(count == 1)
    }

    @Test
    func retriesSafeGetAfterTemporaryNetworkFailure() async throws {
        defer { MockURLProtocol.recorder = nil }
        let recorder = RequestRecorder { request, count in
            if count == 1 { throw URLError(.timedOut) }
            return Self.response(request, status: 200, body: Self.userBody)
        }
        let client = Self.client(store: InMemorySessionStore(), recorder: recorder)

        let profile: UserProfile = try await client.get("/v1/me")
        #expect(profile.id == "user-1")
        let count = await recorder.requestCount
        #expect(count == 2)
    }

    private static let userBody = Data(
        """
        {"id":"user-1","account_kind":"anonymous","credits":5,"premium":false}
        """.utf8
    )

    private static func client(store: InMemorySessionStore, recorder: RequestRecorder) -> APIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        MockURLProtocol.recorder = recorder
        return APIClient(
            baseURL: URL(string: "https://masal.example")!,
            session: URLSession(configuration: configuration),
            sessionStore: store,
            retryDelayNanoseconds: 0
        )
    }

    private static func response(
        _ request: URLRequest,
        status: Int,
        body: Data
    ) -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, body)
    }
}

actor RequestRecorder {
    typealias Handler = @Sendable (URLRequest, Int) throws -> (HTTPURLResponse, Data)

    private let handler: Handler
    private(set) var requestCount = 0

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    func response(for request: URLRequest) throws -> (HTTPURLResponse, Data) {
        requestCount += 1
        return try handler(request, requestCount)
    }
}

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var recorder: RequestRecorder?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let recorder = Self.recorder else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        Task {
            do {
                let (response, data) = try await recorder.response(for: request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }

    override func stopLoading() {}
}
