import Testing

@testable import MasalciCore

struct UserProfileTests {
    @Test
    func mergesBackendAndStorePremiumWithoutRemovingEitherEntitlement() {
        let backendPremium = UserProfile(
            id: "kullanici-1",
            accountKind: .apple,
            credits: 3,
            premium: true
        )
        let storePremium = UserProfile(
            id: "kullanici-2",
            accountKind: .anonymous,
            credits: 5,
            premium: false
        )

        #expect(backendPremium.mergingPremiumEntitlement(false).premium)
        #expect(storePremium.mergingPremiumEntitlement(true).premium)
        #expect(!storePremium.mergingPremiumEntitlement(false).premium)
    }
}
