//
//  DonationManager.swift
//  Write-It-Down
//
//  Created by Tobias Fu on 4/8/25.
//

import SwiftUI
import Lottie
import StoreKit

@MainActor
class DonationManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    @Published var purchaseInProgress = false
    
    private var productsLoaded = false
    private let productIDs = [
        "com.tobiasfu.write_it_down.donation.tier1",  // $2.99
        "com.tobiasfu.write_it_down.donation.tier2",  // $4.99
        "com.tobiasfu.write_it_down.donation.tier3",  // $7.99
        "com.tobiasfu.write_it_down.donation.tier4a",  // $11.99
        "com.tobiasfu.write_it_down.donation.tier5"   // $14.99
    ]
    
    init() {
        Task {
            await loadProducts()
        }
    }
    
    func loadProducts() async {
        guard !productsLoaded else { return }
        
        do {
            let storeProducts = try await Product.products(for: Set(productIDs))
            self.products = storeProducts.sorted { $0.price < $1.price }
            self.productsLoaded = true
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(product: Product) async throws -> Bool {
        purchaseInProgress = true
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verificationResult):
                let transaction = try checkVerified(verificationResult)
                await transaction.finish()
                purchasedProductIDs.insert(product.id)
                purchaseInProgress = false
                return true
                
            case .userCancelled, .pending:
                purchaseInProgress = false
                return false
                
            @unknown default:
                purchaseInProgress = false
                return false
            }
        } catch {
            purchaseInProgress = false
            throw error
        }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    enum StoreError: Error {
        case failedVerification
    }
    
    func priceForIndex(_ index: Int) -> Decimal? {
        guard index > 0, index < products.count + 1, !products.isEmpty else {
            return nil
        }
        return products[index - 1].price
    }
    
    func productForIndex(_ index: Int) -> Product? {
        guard index > 0, index < products.count + 1, !products.isEmpty else {
            return nil
        }
        return products[index - 1]
    }
}
