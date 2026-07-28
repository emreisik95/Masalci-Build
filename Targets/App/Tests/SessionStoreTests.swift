import Testing

@testable import MasalciCore

struct SessionStoreTests {
    @Test
    func storesAndClearsToken() async throws {
        let store = InMemorySessionStore()

        await store.saveToken("gizli-oturum")
        let storedToken = await store.loadToken()
        #expect(storedToken == "gizli-oturum")

        await store.clearToken()
        let clearedToken = await store.loadToken()
        #expect(clearedToken == nil)
    }
}
