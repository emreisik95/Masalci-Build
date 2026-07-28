import Foundation
import MasalciCore
import Observation

@MainActor
@Observable
final class AppEnvironment {
    enum LaunchState: Equatable {
        case starting
        case ready
        case failed(String)
    }

    let apiClient: APIClient
    let apiBaseURL: URL
    let audioPlayer: StoryAudioPlayer
    let subscriptionService: SubscriptionService
    let sessionStore: any SessionStoring
    private(set) var profile: UserProfile?
    private(set) var launchState: LaunchState = .starting

    init(
        apiBaseURL: URL,
        sessionStore: any SessionStoring,
        revenueCatAPIKey: String = "",
        session: URLSession = .shared
    ) {
        self.apiBaseURL = apiBaseURL
        self.sessionStore = sessionStore
        self.audioPlayer = StoryAudioPlayer()
        self.subscriptionService = SubscriptionService(apiKey: revenueCatAPIKey)
        self.apiClient = APIClient(
            baseURL: apiBaseURL,
            session: session,
            sessionStore: sessionStore
        )
    }

    static func live() -> AppEnvironment {
        let configured = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String
        let baseURL = configured.flatMap(URL.init(string:))
            ?? URL(string: "https://masalci-api.emre.zip")!
        let revenueCatAPIKey = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String
        return AppEnvironment(
            apiBaseURL: baseURL,
            sessionStore: KeychainSessionStore(),
            revenueCatAPIKey: revenueCatAPIKey ?? ""
        )
    }

    func start() async {
        guard launchState != .ready else { return }
        launchState = .starting
        do {
            if try await sessionStore.loadToken() == nil {
                try await createAnonymousSession()
            } else {
                do {
                    profile = try await apiClient.get("/v1/me")
                } catch let error as APIError {
                    if case .unauthorized = error {
                        try await createAnonymousSession()
                    } else {
                        throw error
                    }
                }
            }
            if let profile {
                await subscriptionService.configure(userID: profile.id)
            }
            launchState = .ready
        } catch {
            launchState = .failed(
                (error as? LocalizedError)?.errorDescription
                    ?? "Masal dünyasına şu anda ulaşılamıyor. Lütfen yeniden deneyin."
            )
        }
    }

    func updateProfile(_ profile: UserProfile) {
        self.profile = profile
    }

    func updateCredits(_ credits: Int) {
        guard let profile else { return }
        self.profile = UserProfile(
            id: profile.id,
            accountKind: profile.accountKind,
            credits: credits,
            premium: profile.premium
        )
    }

    func updatePremium(_ premium: Bool) {
        guard let profile else { return }
        self.profile = UserProfile(
            id: profile.id,
            accountKind: profile.accountKind,
            credits: profile.credits,
            premium: premium
        )
    }

    func signInWithApple(identityToken: String, rawNonce: String) async throws {
        let session: AnonymousSession = try await apiClient.send(
            "/v1/auth/apple",
            method: .post,
            body: AppleSessionRequest(identityToken: identityToken, rawNonce: rawNonce)
        )
        try await sessionStore.saveToken(session.sessionToken)
        profile = session.user
        await subscriptionService.configure(userID: session.user.id)
    }

    func deleteAccount() async throws {
        try await apiClient.sendWithoutResponse("/v1/account", method: .delete)
        try await sessionStore.clearToken()
        audioPlayer.stop()
        profile = nil
        launchState = .starting
        try await createAnonymousSession()
        if let profile {
            await subscriptionService.configure(userID: profile.id)
        }
        launchState = .ready
    }

    private func createAnonymousSession() async throws {
        let request = AnonymousSessionRequest(installationID: installationID())
        let session: AnonymousSession = try await apiClient.send(
            "/v1/auth/anonymous",
            method: .post,
            body: request
        )
        try await sessionStore.saveToken(session.sessionToken)
        profile = session.user
    }

    private func installationID() -> String {
        let key = "masalci.installation-id"
        if let value = UserDefaults.standard.string(forKey: key) {
            return value
        }
        let value = UUID().uuidString.lowercased()
        UserDefaults.standard.set(value, forKey: key)
        return value
    }
}
