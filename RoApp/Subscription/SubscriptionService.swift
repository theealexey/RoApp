import Foundation
import Observation
import StoreKit

enum RoProduct: String, CaseIterable {
    case monthly = "roapp_monthly"
    case annual = "roapp_annual"
}

@MainActor
protocol SubscriptionServiceProtocol: AnyObject {
    var products: [Product] { get }
    var isLoading: Bool { get }
    var isPro: Bool { get }
    var purchaseErrorMessage: String? { get }

    func loadProducts() async
    func purchase(_ product: Product) async
    func restorePurchases() async
    func refresh() async
}

@MainActor
@Observable
final class SubscriptionService: SubscriptionServiceProtocol {
    private(set) var products: [Product] = []
    private(set) var isLoading = false
    private(set) var isPro = false
    private(set) var purchaseErrorMessage: String?

    init() {
        Task {
            await observeVerifiedTransactions()
        }
    }

    func loadProducts() async {
        isLoading = true
        purchaseErrorMessage = nil

        do {
            let productIdentifiers = RoProduct.allCases.map(\.rawValue)
            let storeProducts = try await Product.products(for: productIdentifiers)

            let productPriority: [String: Int] = [
                RoProduct.annual.rawValue: 0,
                RoProduct.monthly.rawValue: 1
            ]

            products = storeProducts.sorted {
                let leftPriority = productPriority[$0.id] ?? .max
                let rightPriority = productPriority[$1.id] ?? .max
                return leftPriority < rightPriority
            }
        } catch {
            purchaseErrorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func purchase(_ product: Product) async {
        purchaseErrorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await refresh()

                case .unverified(_, let error):
                    purchaseErrorMessage = error.localizedDescription
                }

            case .userCancelled:
                break

            case .pending:
                purchaseErrorMessage = String(localized: "paywall.pending", defaultValue: "Purchase is pending approval.")

            @unknown default:
                purchaseErrorMessage = String(localized: "paywall.error.unknown", defaultValue: "Unknown purchase result.")
            }
        } catch {
            purchaseErrorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        purchaseErrorMessage = nil

        do {
            try await AppStore.sync()
            await refresh()
        } catch {
            purchaseErrorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        isPro = false

        let productIdentifiers = Set(RoProduct.allCases.map(\.rawValue))

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if productIdentifiers.contains(transaction.productID) {
                isPro = true
                break
            }
        }
    }

    private func observeVerifiedTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }

            await transaction.finish()
            await refresh()
        }
    }
}
