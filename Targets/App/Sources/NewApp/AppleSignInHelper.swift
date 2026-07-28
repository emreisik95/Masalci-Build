import AuthenticationServices
import CryptoKit
import Foundation
import Security

enum AppleSignInHelper {
    enum NonceError: Error {
        case generationFailed
    }

    static func prepare(_ request: ASAuthorizationAppleIDRequest) throws -> String {
        let nonce = try randomNonce()
        let digest = SHA256.hash(data: Data(nonce.utf8))
        request.nonce = digest.map { String(format: "%02x", $0) }.joined()
        request.requestedScopes = [.fullName]
        return nonce
    }

    private static func randomNonce() throws -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            throw NonceError.generationFailed
        }
        return Data(bytes).base64EncodedString()
    }
}
