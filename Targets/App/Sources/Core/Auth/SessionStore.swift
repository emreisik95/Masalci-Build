import Foundation
import Security

public protocol SessionStoring: Sendable {
    func loadToken() async throws -> String?
    func saveToken(_ token: String) async throws
    func clearToken() async throws
}

public actor InMemorySessionStore: SessionStoring {
    private var token: String?

    public init(token: String? = nil) {
        self.token = token
    }

    public func loadToken() -> String? {
        token
    }

    public func saveToken(_ token: String) {
        self.token = token
    }

    public func clearToken() {
        token = nil
    }
}

public enum SessionStoreError: Error, LocalizedError, Sendable {
    case keychain(OSStatus)

    public var errorDescription: String? {
        "Oturum bilgisi güvenli biçimde saklanamadı."
    }
}

public actor KeychainSessionStore: SessionStoring {
    private let service: String
    private let account: String

    public init(service: String = "tr.kirke.masalci", account: String = "session-token") {
        self.service = service
        self.account = account
    }

    public func loadToken() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw SessionStoreError.keychain(status)
        }
        return token
    }

    public func saveToken(_ token: String) throws {
        let data = Data(token.utf8)
        var add = baseQuery
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(add as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let updateStatus = SecItemUpdate(
                baseQuery as CFDictionary,
                [kSecValueData as String: data] as CFDictionary
            )
            guard updateStatus == errSecSuccess else {
                throw SessionStoreError.keychain(updateStatus)
            }
        } else if status != errSecSuccess {
            throw SessionStoreError.keychain(status)
        }
    }

    public func clearToken() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SessionStoreError.keychain(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
