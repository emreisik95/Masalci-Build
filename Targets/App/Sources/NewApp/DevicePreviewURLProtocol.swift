import Foundation

/// GitHub cihaz paketinde tasarımın canlı sunucu kurulmadan incelenebilmesini sağlar.
/// Normal Debug ve Release derlemelerinde Info.plist anahtarı kapalıdır.
final class DevicePreviewURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "masalci-api.emre.zip"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        do {
            let body = try JSONSerialization.data(withJSONObject: Self.payload(for: request, url: url))
            guard let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json; charset=utf-8"]
            ) else {
                throw URLError(.badServerResponse)
            }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    private static func payload(for request: URLRequest, url: URL) -> Any {
        let path = url.path
        let method = request.httpMethod ?? "GET"

        if path == "/v1/auth/anonymous" || path == "/v1/auth/apple" {
            return ["session_token": "cihaz-onizleme-oturumu", "user": profile]
        }
        if path == "/v1/me" {
            return profile
        }
        if path == "/v1/categories" {
            return ["items": ["Uyku", "Dostluk", "Macera", "Deniz"]]
        }
        if path == "/v1/story-elements" {
            return ["items": storyElements]
        }
        if path == "/v1/favorites" {
            return ["items": Array(stories.prefix(2)), "next_cursor": NSNull()]
        }
        if path == "/v1/generations" || path.hasPrefix("/v1/generations/") {
            return generation
        }
        if path.hasSuffix("/favorite") {
            return ["is_favorite": method != "DELETE", "likes_count": method == "DELETE" ? 126 : 127]
        }
        if path.hasSuffix("/views") {
            return ["view_count": 1_248]
        }
        if path == "/v1/stories" {
            let category = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "category" })?.value
            let items = category.map { selected in
                stories.filter { ($0["categories"] as? [String])?.contains(selected) == true }
            } ?? stories
            return ["items": items, "next_cursor": NSNull()]
        }
        if path.hasPrefix("/v1/stories/") {
            let id = path.split(separator: "/").last.map(String.init) ?? "ay-isigi-tavsani"
            return stories.first(where: { $0["id"] as? String == id }) ?? stories[0]
        }
        return [:]
    }

    private static var profile: [String: Any] {
        ["id": "cihaz-onizleme", "account_kind": "anonymous", "credits": 5, "premium": false]
    }

    private static var stories: [[String: Any]] {
        [
            story(
                id: "ay-isigi-tavsani",
                title: "Ay Işığını Arayan Minik Tavşan",
                summary: "Mino, kaybolan ay ışığını dostlarıyla birlikte bulmak için yıldızlı ormana doğru yola çıkar.",
                categories: ["Uyku", "Dostluk"],
                featured: true,
                favorite: true
            ),
            story(
                id: "mercan-bahcesi",
                title: "Mercan Bahçesinin Şarkısı",
                summary: "Cesur denizatı Pırıltı, sessiz kalan mercan bahçesine neşesini geri getirir.",
                categories: ["Deniz", "Macera"],
                favorite: true
            ),
            story(
                id: "bulut-treni",
                title: "Rüyalara Giden Bulut Treni",
                summary: "Lina, yumuşacık bulutların üstünde sakin bir gece yolculuğuna çıkar.",
                categories: ["Uyku", "Macera"]
            ),
            story(
                id: "minik-ejderha",
                title: "Kıkırdayan Minik Ejderha",
                summary: "Alev yerine renkli baloncuklar çıkaran Pofuduk, farklı olmanın gücünü keşfeder.",
                categories: ["Dostluk", "Macera"]
            ),
        ]
    }

    private static func story(
        id: String,
        title: String,
        summary: String,
        categories: [String],
        featured: Bool = false,
        favorite: Bool = false
    ) -> [String: Any] {
        [
            "id": id,
            "title": title,
            "summary": summary,
            "content": "Bir varmış bir yokmuş… \(summary) Yol boyunca cesaretin, iyiliğin ve paylaşmanın en güzel büyü olduğunu öğrenmişler. Gökyüzündeki yıldızlar usulca parıldarken herkes huzurla evine dönmüş.",
            "categories": categories,
            "is_featured": featured,
            "view_count": 1_247,
            "likes_count": favorite ? 126 : 84,
            "is_favorite": favorite,
            "published_at": "2026-07-28T18:00:00Z",
        ]
    }

    private static var storyElements: [[String: Any]] {
        [
            ["id": "tavsan", "kind": "character", "name": "Minik Tavşan", "description": "Meraklı ve cesur", "tags": ["sevimli"]],
            ["id": "ejderha", "kind": "character", "name": "Pofuduk Ejderha", "description": "Neşeli ve yardımsever", "tags": ["komik"]],
            ["id": "yildiz", "kind": "character", "name": "Kayıp Yıldız", "description": "Parlak bir yol arkadaşı", "tags": ["büyülü"]],
            ["id": "orman", "kind": "place", "name": "Yıldızlı Orman", "description": "Ağaçların fısıldaştığı sakin orman", "tags": ["gece"]],
            ["id": "bulut", "kind": "place", "name": "Bulut Şehri", "description": "Gökyüzünde yumuşacık bir şehir", "tags": ["gökyüzü"]],
            ["id": "sicak", "kind": "voice", "name": "Sıcak Anlatıcı", "description": "Yumuşak ve huzurlu Türkçe anlatım", "tags": ["sakin"]],
        ]
    }

    private static var generation: [String: Any] {
        [
            "id": "cihaz-onizleme-masali",
            "status": "completed",
            "progress": 1.0,
            "status_message": "Masalın hazır!",
            "story": ["id": "ay-isigi-tavsani"],
            "credits_remaining": 4,
        ]
    }
}
