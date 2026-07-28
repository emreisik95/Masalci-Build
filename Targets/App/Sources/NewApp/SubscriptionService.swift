import Foundation
import Observation
import RevenueCat

@MainActor
@Observable
final class SubscriptionService {
    struct Option: Identifiable, Equatable {
        let id: String
        let title: String
        let detail: String
        let price: String
    }

    enum State: Equatable {
        case unavailable(String)
        case loading
        case ready
        case purchasing
        case purchased
        case failed(String)
    }

    private let apiKey: String
    private var packagesByID: [String: RevenueCat.Package] = [:]
    private var configuredUserID: String?
    private(set) var options: [Option] = []
    private(set) var state: State
    private(set) var isPremium = false

    init(apiKey: String) {
        self.apiKey = apiKey
        self.state = apiKey.isEmpty || apiKey.contains("$(")
            ? .unavailable("Premium yapılandırması henüz tamamlanmadı.")
            : .loading
    }

    func configure(userID: String) async {
        guard !apiKey.isEmpty, !apiKey.contains("$(") else { return }
        do {
            if configuredUserID == nil {
                Purchases.logLevel = .error
                Purchases.configure(withAPIKey: apiKey, appUserID: userID)
            } else if configuredUserID != userID {
                let result = try await Purchases.shared.logIn(userID)
                updatePremium(from: result.customerInfo)
            }
            configuredUserID = userID
            await loadOfferings()
        } catch {
            state = .failed("Premium bilgileri alınamadı. Lütfen yeniden deneyin.")
        }
    }

    func loadOfferings() async {
        guard configuredUserID != nil else { return }
        state = .loading
        do {
            let offerings = try await Purchases.shared.offerings()
            let packages = offerings.current?.availablePackages ?? []
            packagesByID = Dictionary(uniqueKeysWithValues: packages.map { ($0.identifier, $0) })
            options = packages.map { package in
                Option(
                    id: package.identifier,
                    title: title(for: package.identifier),
                    detail: package.storeProduct.localizedDescription,
                    price: package.storeProduct.localizedPriceString
                )
            }
            let customerInfo = try await Purchases.shared.customerInfo()
            updatePremium(from: customerInfo)
            state = options.isEmpty
                ? .unavailable("Satın alma seçenekleri şu anda bulunamıyor.")
                : .ready
        } catch {
            state = .failed("Premium seçenekleri yüklenemedi. Lütfen yeniden deneyin.")
        }
    }

    func purchase(optionID: String) async -> Bool {
        guard let package = packagesByID[optionID] else { return false }
        state = .purchasing
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled {
                state = .ready
                return false
            }
            updatePremium(from: result.customerInfo)
            state = isPremium ? .purchased : .ready
            return isPremium
        } catch {
            state = .failed("Satın alma tamamlanamadı. Ücret alınmadı; yeniden deneyebilirsin.")
            return false
        }
    }

    func restore() async -> Bool {
        state = .purchasing
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            updatePremium(from: customerInfo)
            state = isPremium ? .purchased : .ready
            return isPremium
        } catch {
            state = .failed("Satın alımlar geri yüklenemedi. Lütfen yeniden deneyin.")
            return false
        }
    }

    private func updatePremium(from customerInfo: CustomerInfo) {
        isPremium = customerInfo.entitlements["premium"]?.isActive == true
    }

    private func title(for identifier: String) -> String {
        let normalized = identifier.lowercased()
        if normalized.contains("annual") || normalized.contains("year") {
            return "Yıllık Premium"
        }
        if normalized.contains("month") {
            return "Aylık Premium"
        }
        return "Masalcı Premium"
    }
}
