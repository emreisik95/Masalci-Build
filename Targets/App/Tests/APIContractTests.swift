import Foundation
import Testing

@testable import MasalciCore

struct APIContractTests {
    @Test
    func decodesStoryFixture() throws {
#if SWIFT_PACKAGE
        let resources = Bundle.module
        let url = try #require(
            resources.url(
                forResource: "story-contract",
                withExtension: "json",
                subdirectory: "Fixtures"
            )
        )
#else
        let resources = Bundle(for: TestBundleToken.self)
        let url = try #require(resources.url(forResource: "story-contract", withExtension: "json"))
#endif
        let story = try MasalJSON.decoder.decode(Story.self, from: Data(contentsOf: url))

        #expect(story.id == "00000000-0000-4000-8000-000000000001")
        #expect(story.title == "Ay Işığındaki Minik Tilki")
        #expect(story.imageURL?.relativeString == "/v1/media/covers/minik-tilki.webp")
        #expect(story.categories == ["Uyku", "Macera"])
        #expect(story.publishedAt.timeIntervalSince1970 == 1_785_175_200)
    }

    @Test
    func decodesGenerationStatusAndTurkishMessage() throws {
        let data = Data(
            """
            {
              "id":"10000000-0000-4000-8000-000000000001",
              "status":"illustrating",
              "progress":0.55,
              "status_message":"Masalın resimleri hazırlanıyor.",
              "story":null,
              "credits_remaining":4
            }
            """.utf8
        )

        let status = try MasalJSON.decoder.decode(GenerationStatus.self, from: data)
        #expect(status.state == .illustrating)
        #expect(status.statusMessage == "Masalın resimleri hazırlanıyor.")
        #expect(status.creditsRemaining == 4)
    }

    @Test
    func decodesErrorEnvelope() throws {
        let data = Data(
            """
            {"error":{"code":"AUTH_REQUIRED","message":"Devam etmek için oturum açın.","request_id":"req-1"}}
            """.utf8
        )

        let envelope = try MasalJSON.decoder.decode(APIErrorEnvelope.self, from: data)
        #expect(envelope.error.code == "AUTH_REQUIRED")
        #expect(envelope.error.requestID == "req-1")
    }

    @Test
    func encodesGenerationRequestWithServerKeys() throws {
        let request = CreateGenerationRequest(
            prompt: "Ay ışığında dostluğu anlatan sıcak bir masal.",
            duration: .short,
            characterIDs: ["karakter-1"],
            placeIDs: ["yer-1"],
            voiceID: "ses-1"
        )

        let data = try MasalJSON.encoder.encode(request)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["character_ids"] as? [String] == ["karakter-1"])
        #expect(object["place_ids"] as? [String] == ["yer-1"])
        #expect(object["voice_id"] as? String == "ses-1")
        #expect(object["character_i_ds"] == nil)
    }

    @Test
    func encodesAnonymousSessionRequestWithServerKey() throws {
        let data = try MasalJSON.encoder.encode(
            AnonymousSessionRequest(installationID: "kurulum-1")
        )
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["installation_id"] as? String == "kurulum-1")
    }
}

private final class TestBundleToken {}
