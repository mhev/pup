import Foundation
import StoreKit
import SwiftUI

@MainActor
class SubscriptionService: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedSubscriptions: [Product] = []
    @Published var subscriptionStatus: [Product.SubscriptionInfo.Status] = []
    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var updateListenerTask: Task<Void, Error>?
    private var transactionListener: Task<Void, Error>?
    
    static let shared = SubscriptionService()
    
    // Product identifiers
    private let productIdentifiers = [
        "com.hev.pup.monthly",
        "com.hev.pup.yearly"
    ]
    
    private init() {
        // Start listening for transaction updates
        transactionListener = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
        transactionListener?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let products = try await Product.products(for: productIdentifiers)
            self.products = products.sorted { product1, product2 in
                // Sort monthly first, then yearly
                if product1.id == "com.hev.pup.monthly" { return true }
                if product2.id == "com.hev.pup.monthly" { return false }
                return product1.displayPrice < product2.displayPrice
            }
        } catch {
            print("Failed to load products: \(error)")
            errorMessage = "Failed to load subscription options"
        }
    }
    
    // MARK: - Purchase Handling
    
    func purchase(product: Product) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verificationResult):
                switch verificationResult {
                case .verified(let transaction):
                    await transaction.finish()
                    await updateSubscriptionStatus()
                    return true
                case .unverified(_, let error):
                    print("Purchase verification failed: \(error)")
                    errorMessage = "Purchase verification failed"
                    return false
                }
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            print("Purchase failed: \(error)")
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Subscription Status
    
    func updateSubscriptionStatus() async {
        var currentSubscriptions: [Product] = []
        var subscriptionStatuses: [Product.SubscriptionInfo.Status] = []
        
        // Check for current subscriptions
        for product in products {
            if let subscriptionInfo = product.subscription {
                let status = try? await subscriptionInfo.status.first
                if let status = status {
                    subscriptionStatuses.append(status)
                    
                    // Check if subscription is in an active state
                    if status.state == .subscribed ||
                       status.state == .inGracePeriod ||
                       status.state == .inBillingRetryPeriod {
                        currentSubscriptions.append(product)
                    }
                }
            }
        }
        
        purchasedSubscriptions = currentSubscriptions
        subscriptionStatus = subscriptionStatuses
        isPremium = !currentSubscriptions.isEmpty
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                case .unverified(_, let error):
                    print("Unverified transaction: \(error)")
                }
            }
        }
    }
    
    // MARK: - Promo Codes
    
    func redeemPromoCode(_ code: String) async -> Bool {
        // Check if this is a valid promo code
        let validPromoCodes = ["FREEPUP", "MARTINA2024", "BETAUSER"]
        
        if validPromoCodes.contains(code.uppercased()) {
            // Grant premium access
            UserDefaults.standard.set(true, forKey: "hasPromoCodeAccess")
            UserDefaults.standard.set(code.uppercased(), forKey: "usedPromoCode")
            isPremium = true
            return true
        }
        
        return false
    }
    
    func hasPromoCodeAccess() -> Bool {
        return UserDefaults.standard.bool(forKey: "hasPromoCodeAccess")
    }
    
    // MARK: - Helper Methods
    
    func formattedPrice(for product: Product) -> String {
        return product.displayPrice
    }
    
    func savingsText(for product: Product) -> String? {
        guard product.id == "com.hev.pup.yearly" else { return nil }
        
        // Calculate savings compared to monthly
        let monthlyPrice = 14.99
        let yearlyPrice = 99.99
        let monthlyCost = monthlyPrice * 12
        let savings = monthlyCost - yearlyPrice
        let percentage = Int((savings / monthlyCost) * 100)
        
        return "Save \(percentage)% vs Monthly"
    }
    
    func isActiveSubscription(for product: Product) -> Bool {
        return purchasedSubscriptions.contains(where: { $0.id == product.id })
    }
}

// MARK: - Subscription Status Helper

extension SubscriptionService {
    var subscriptionTypeText: String {
        guard isPremium else { return "Free" }
        
        if hasPromoCodeAccess() {
            return "Premium (Promo)"
        }
        
        if let activeSubscription = purchasedSubscriptions.first {
            return activeSubscription.id == "com.hev.pup.monthly" ? "Monthly Premium" : "Yearly Premium"
        }
        
        return "Premium"
    }
    
    var nextRenewalDate: Date? {
        guard let status = subscriptionStatus.first else { return nil }
        // Try to get renewal date from renewal info
        do {
            let renewalInfo = try status.renewalInfo.payloadValue
            return renewalInfo.renewalDate
        } catch {
            return nil
        }
    }
} 