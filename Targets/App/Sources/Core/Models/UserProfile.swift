import Foundation

public struct UserProfile: Codable, Equatable, Identifiable, Sendable {
    public enum AccountKind: String, Codable, Sendable {
        case anonymous
        case apple
    }

    public let id: String
    public let accountKind: AccountKind
    public let credits: Int
    public let premium: Bool

    public init(id: String, accountKind: AccountKind, credits: Int, premium: Bool) {
        self.id = id
        self.accountKind = accountKind
        self.credits = credits
        self.premium = premium
    }

    public func mergingPremiumEntitlement(_ entitlementIsActive: Bool) -> UserProfile {
        UserProfile(
            id: id,
            accountKind: accountKind,
            credits: credits,
            premium: premium || entitlementIsActive
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case accountKind = "account_kind"
        case credits
        case premium
    }
}

public struct AnonymousSession: Codable, Equatable, Sendable {
    public let sessionToken: String
    public let user: UserProfile

    enum CodingKeys: String, CodingKey {
        case sessionToken = "session_token"
        case user
    }
}

public struct AnonymousSessionRequest: Codable, Equatable, Sendable {
    public let installationID: String

    public init(installationID: String) {
        self.installationID = installationID
    }

    enum CodingKeys: String, CodingKey {
        case installationID = "installation_id"
    }
}

public struct AppleSessionRequest: Codable, Equatable, Sendable {
    public let identityToken: String
    public let rawNonce: String

    public init(identityToken: String, rawNonce: String) {
        self.identityToken = identityToken
        self.rawNonce = rawNonce
    }

    enum CodingKeys: String, CodingKey {
        case identityToken = "identity_token"
        case rawNonce = "raw_nonce"
    }
}
