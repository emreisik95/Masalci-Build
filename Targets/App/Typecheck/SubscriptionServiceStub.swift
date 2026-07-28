import Foundation
import Observation

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

    private(set) var options: [Option] = []
    private(set) var state: State = .unavailable("Yerel tip kontrolü")
    private(set) var isPremium = false

    init(apiKey: String) {}
    func configure(userID: String) async {}
    func loadOfferings() async {}
    func purchase(optionID: String) async -> Bool { false }
    func restore() async -> Bool { false }
}
