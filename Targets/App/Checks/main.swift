import Foundation
import MasalciCore

enum CheckFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case let .failed(message): message
        }
    }
}

func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() { throw CheckFailure.failed(message) }
}

let storyData = Data(
    """
    {
      "id":"00000000-0000-4000-8000-000000000001",
      "title":"Ay Işığındaki Minik Tilki",
      "summary":"Minik bir tilkinin yıldızlarla kurduğu sıcacık dostluk.",
      "image_url":"/v1/media/covers/minik-tilki.webp",
      "audio_url":"/v1/media/audio/minik-tilki.mp3",
      "categories":["Uyku","Macera"],
      "is_featured":true,
      "view_count":12,
      "likes_count":3,
      "is_favorite":false,
      "published_at":"2026-07-27T18:00:00.000Z"
    }
    """.utf8
)
let story = try MasalJSON.decoder.decode(Story.self, from: storyData)
try require(story.title == "Ay Işığındaki Minik Tilki", "Masal sözleşmesi çözülemedi.")
try require(
    story.imageURL?.relativeString == "/v1/media/covers/minik-tilki.webp",
    "Masal görsel adresi çözülemedi."
)
try require(story.publishedAt.timeIntervalSince1970 == 1_785_175_200, "Masal tarihi çözülemedi.")

let generationData = Data(
    """
    {"id":"job-1","status":"illustrating","progress":0.55,"status_message":"Masalın resimleri hazırlanıyor.","story":null,"credits_remaining":4}
    """.utf8
)
let generation = try MasalJSON.decoder.decode(GenerationStatus.self, from: generationData)
try require(generation.state == .illustrating, "Üretim durumu çözülemedi.")
try require(generation.statusMessage == "Masalın resimleri hazırlanıyor.", "Türkçe durum mesajı korunmadı.")

let generationRequest = CreateGenerationRequest(
    prompt: "Ay ışığında dostluğu anlatan sıcak bir masal.",
    duration: .short,
    characterIDs: ["karakter-1"],
    placeIDs: ["yer-1"],
    voiceID: "ses-1"
)
let requestData = try MasalJSON.encoder.encode(generationRequest)
let requestObject = try JSONSerialization.jsonObject(with: requestData) as? [String: Any]
try require(
    requestObject?["character_ids"] as? [String] == ["karakter-1"],
    "Masal isteği sunucu sözleşmesine göre kodlanmadı."
)

let store = InMemorySessionStore(token: "oturum-tokeni")
let storedToken = await store.loadToken()
try require(storedToken == "oturum-tokeni", "Oturum belirteci okunamadı.")

let recorder = CheckRequestRecorder { request, count in
    try require(
        request.value(forHTTPHeaderField: "Authorization") == "Bearer oturum-tokeni",
        "Bearer belirteci eklenmedi."
    )
    if count == 1 { throw URLError(.timedOut) }
    let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
    )!
    let body = Data(
        """
        {"id":"user-1","account_kind":"anonymous","credits":5,"premium":false}
        """.utf8
    )
    return (response, body)
}
let configuration = URLSessionConfiguration.ephemeral
configuration.protocolClasses = [CheckURLProtocol.self]
CheckURLProtocol.recorder = recorder
let client = APIClient(
    baseURL: URL(string: "https://masal.example")!,
    session: URLSession(configuration: configuration),
    sessionStore: store,
    retryDelayNanoseconds: 0
)
let profile: UserProfile = try await client.get("/v1/me")
try require(profile.credits == 5, "Kullanıcı sözleşmesi çözülemedi.")
let requestCount = await recorder.requestCount
try require(requestCount == 2, "Güvenli GET isteği yeniden denenmedi.")

await store.clearToken()
let clearedToken = await store.loadToken()
try require(clearedToken == nil, "Oturum belirteci temizlenmedi.")

print("Masalcı Swift çekirdek denetimleri geçti.")

actor CheckRequestRecorder {
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

final class CheckURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var recorder: CheckRequestRecorder?

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
