//
//  StoreKitManager.swift
//  Chit Chat Social
//

import Foundation
import StoreKit
import SwiftUI

enum IAPProductID {
    /// Non-consumable — unlocks the public paid verification badge on the user's profile.
    static let paidVerification = "com.bruce.ChitChat.paidVerification"

    static var all: [String] { [paidVerification] }
}

enum IAPProductLoadState: Equatable {
    case idle
    case loading
    case ready
    case unavailable(String)
}

@MainActor
final class StoreKitManager: ObservableObject {
    /// Single shared instance so Profile / Verification always talk to the same StoreKit session.
    static let shared = StoreKitManager()

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var productLoadState: IAPProductLoadState = .idle
    @Published var purchaseError: String?
    @Published var isPurchasing = false
    @Published var isRestoring = false

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await refreshPurchasedProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    var paidVerificationProduct: Product? {
        products.first { $0.id == IAPProductID.paidVerification }
    }

    var hasPaidVerification: Bool {
        purchasedProductIDs.contains(IAPProductID.paidVerification)
    }

    var productUnavailableMessage: String {
        if case .unavailable(let message) = productLoadState {
            return message
        }
        return "Paid Verification Badge is not available from the App Store yet."
    }

    func loadProductsIfNeeded() async {
        if case .ready = productLoadState, paidVerificationProduct != nil { return }
        await loadProducts()
    }

    func loadProducts() async {
        productLoadState = .loading
        purchaseError = nil
        let maxAttempts = 3
        for attempt in 0..<maxAttempts {
            do {
                let fetched = try await Product.products(for: IAPProductID.all)
                products = fetched
                if fetched.contains(where: { $0.id == IAPProductID.paidVerification }) {
                    productLoadState = .ready
                    return
                }
            } catch {
                if attempt == maxAttempts - 1 {
                    productLoadState = .unavailable(error.localizedDescription)
                    purchaseError = error.localizedDescription
                    return
                }
            }
            if attempt < maxAttempts - 1 {
                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 * (attempt + 1)))
            }
        }
        let message =
            "Paid Verification Badge (\(IAPProductID.paidVerification)) is not available yet. " +
            "Confirm the IAP is Ready to Submit in App Store Connect, attached to version 1.0, " +
            "and that the Paid Apps Agreement is active."
        productLoadState = .unavailable(message)
    }

    @discardableResult
    func purchasePaidVerification() async -> Bool {
        if paidVerificationProduct == nil {
            await loadProducts()
        }
        guard let product = paidVerificationProduct else {
            purchaseError = productUnavailableMessage
            return false
        }
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await refreshPurchasedProducts()
                await transaction.finish()
                let success = purchasedProductIDs.contains(IAPProductID.paidVerification)
                if !success {
                    purchaseError = "Purchase completed but entitlement was not found. Try Restore Purchases."
                }
                return success
            case .userCancelled:
                return false
            case .pending:
                purchaseError = "Purchase is pending approval."
                return false
            @unknown default:
                return false
            }
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }

    func restorePurchases() async {
        isRestoring = true
        purchaseError = nil
        defer { isRestoring = false }
        do {
            try await AppStore.sync()
            await refreshPurchasedProducts()
            if !hasPaidVerification {
                purchaseError = "No previous Paid Verification Badge purchase was found for this Apple ID."
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func refreshPurchasedProducts() async {
        var purchased = Set<String>()
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.revocationDate == nil {
                purchased.insert(transaction.productID)
            }
        }
        purchasedProductIDs = purchased
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                guard let transaction = try? self.checkVerified(update) else { continue }
                await self.refreshPurchasedProducts()
                await transaction.finish()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitPurchaseError.failedVerification
        case .verified(let value):
            return value
        }
    }
}

enum StoreKitPurchaseError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Could not verify this App Store purchase."
        }
    }
}

private struct StoreKitManagerKey: EnvironmentKey {
    @MainActor static var defaultValue: StoreKitManager { StoreKitManager.shared }
}

extension EnvironmentValues {
    var storeKit: StoreKitManager {
        get { self[StoreKitManagerKey.self] }
        set { self[StoreKitManagerKey.self] = newValue }
    }
}
