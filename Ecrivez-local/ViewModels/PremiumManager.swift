import Foundation
import StoreKit
import Combine

enum PremiumTier: String, CaseIterable {
    case free = "free"
    case premium = "premium"
    case lifetime = "lifetime"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        case .lifetime: return "Lifetime Pro"
        }
    }
}

enum PremiumFeature: String, CaseIterable {
    // Core Features
    case unlimitedNotes
    case unlimitedCategories
    case cloudSync
    case richTextFormatting
    case imageInsertion
    
    // Advanced Features
    case locationTagging
    case weatherTagging
    case publicNoteSharing
    case anonymousPosting
    case socialFeatures
    
    // Customization
    case darkMode
    case customThemes
    case mapPinCustomization
    case multipleAppIcons
    
    // Export & Integration
    case exportPDF
    case bulkExport
    case importNotes
    
    var displayName: String {
        switch self {
        case .unlimitedNotes: return "Unlimited Notes"
        case .unlimitedCategories: return "Unlimited Categories"
        case .cloudSync: return "Cloud Sync & Backup"
        case .richTextFormatting: return "Rich Text Formatting"
        case .imageInsertion: return "Image Insertion"
        case .locationTagging: return "Location Tagging"
        case .weatherTagging: return "Weather Tagging"
        case .publicNoteSharing: return "Public Note Sharing"
        case .anonymousPosting: return "Anonymous Posting"
        case .socialFeatures: return "Likes & Comments"
        case .darkMode: return "Dark Mode"
        case .customThemes: return "Custom Themes"
        case .mapPinCustomization: return "Map Pin Customization"
        case .multipleAppIcons: return "Multiple App Icons"
        case .exportPDF: return "Export to PDF"
        case .bulkExport: return "Bulk Export"
        case .importNotes: return "Import Notes"
        }
    }
    
    var description: String {
        switch self {
        case .unlimitedNotes: return "Create as many notes as you need"
        case .unlimitedCategories: return "Organize with unlimited categories"
        case .cloudSync: return "Sync across all your devices"
        case .richTextFormatting: return "Bold, italic, colors, and more"
        case .imageInsertion: return "Add photos to your notes"
        case .locationTagging: return "Tag notes with locations"
        case .weatherTagging: return "Add weather to your notes"
        case .publicNoteSharing: return "Share notes with the community"
        case .anonymousPosting: return "Post publicly without revealing identity"
        case .socialFeatures: return "Like and comment on public notes"
        case .darkMode: return "Easy on the eyes in low light"
        case .customThemes: return "Personalize your app appearance"
        case .mapPinCustomization: return "Custom map pin colors and icons"
        case .multipleAppIcons: return "Choose from multiple app icons"
        case .exportPDF: return "Export notes as PDF files"
        case .bulkExport: return "Export multiple notes at once"
        case .importNotes: return "Import from other note apps"
        }
    }
}

@MainActor
class PremiumManager: ObservableObject {
    static let shared = PremiumManager()
    
    // Published properties
    @Published var currentTier: PremiumTier = .free
    @Published var isProcessingPurchase = false
    @Published var purchaseError: String?
    @Published var hasLifetimeAccess = false
    @Published var subscriptionExpiryDate: Date?
    
    // StoreKit properties
    private var products: [Product] = []
    private var purchaseTask: Task<Void, Error>?
    private var updateListenerTask: Task<Void, Error>?
    
    // Product IDs
    private let monthlySubscriptionID = "com.tobiasfu.write-it-down.premium.monthly"
    private let yearlySubscriptionID = "com.tobiasfu.write-it-down.premium.yearly"
    private let lifetimeID = "com.tobiasfu.write-it-down.lifetime"
    private let categoryPackID = "com.tobiasfu.write-it-down.categorypack"
    private let themePackID = "com.tobiasfu.write-it-down.themepack"
    
    // Free tier limits
    let freeNoteLimit = 5
    let freeCategoryLimit = 1
    
    private init() {
        Task {
            await loadProducts()
            await updatePurchaseStatus()
            startTransactionListener()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Feature Access
    
    func hasAccess(to feature: PremiumFeature) -> Bool {
        switch currentTier {
        case .free:
            return false // All premium features are locked
        case .premium, .lifetime:
            return true // All features unlocked
        }
    }
    
    func canCreateMoreNotes(currentCount: Int) -> Bool {
        switch currentTier {
        case .free:
            return currentCount < freeNoteLimit
        case .premium, .lifetime:
            return true
        }
    }
    
    func canCreateMoreCategories(currentCount: Int) -> Bool {
        switch currentTier {
        case .free:
            return currentCount < freeCategoryLimit
        case .premium, .lifetime:
            return true
        }
    }
    
    func getRemainingNotes(currentCount: Int) -> Int? {
        switch currentTier {
        case .free:
            return max(0, freeNoteLimit - currentCount)
        case .premium, .lifetime:
            return nil // Unlimited
        }
    }
    
    // MARK: - StoreKit Integration
    
    @MainActor
    private func loadProducts() async {
        do {
            let productIDs = [
                monthlySubscriptionID,
                yearlySubscriptionID,
                lifetimeID,
                categoryPackID,
                themePackID
            ]
            
            products = try await Product.products(for: productIDs)
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    @MainActor
    func updatePurchaseStatus() async {
        var hasActiveSubscription = false
        var hasLifetime = false
        var latestExpiryDate: Date?
        
        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                switch transaction.productID {
                case monthlySubscriptionID, yearlySubscriptionID:
                    if let expiryDate = transaction.expirationDate, expiryDate > Date() {
                        hasActiveSubscription = true
                        if latestExpiryDate == nil || expiryDate > latestExpiryDate! {
                            latestExpiryDate = expiryDate
                        }
                    }
                case lifetimeID:
                    hasLifetime = true
                default:
                    break
                }
            }
        }
        
        // Update tier
        if hasLifetime {
            currentTier = .lifetime
            hasLifetimeAccess = true
        } else if hasActiveSubscription {
            currentTier = .premium
            subscriptionExpiryDate = latestExpiryDate
        } else {
            currentTier = .free
            subscriptionExpiryDate = nil
        }
        
        // Store in UserDefaults for offline access
        UserDefaults.standard.set(currentTier.rawValue, forKey: "premiumTier")
        UserDefaults.standard.set(hasLifetimeAccess, forKey: "hasLifetimeAccess")
    }
    
    private func startTransactionListener() {
        updateListenerTask = Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await updatePurchaseStatus()
                    await transaction.finish()
                }
            }
        }
    }
    
    // MARK: - Purchase Methods
    
    @MainActor
    func purchaseMonthlySubscription() async {
        await purchase(productID: monthlySubscriptionID)
    }
    
    @MainActor
    func purchaseYearlySubscription() async {
        await purchase(productID: yearlySubscriptionID)
    }
    
    @MainActor
    func purchaseLifetime() async {
        await purchase(productID: lifetimeID)
    }
    
    @MainActor
    private func purchase(productID: String) async {
        guard let product = products.first(where: { $0.id == productID }) else {
            purchaseError = "Product not found"
            return
        }
        
        isProcessingPurchase = true
        purchaseError = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await updatePurchaseStatus()
                case .unverified:
                    purchaseError = "Purchase could not be verified"
                }
            case .userCancelled:
                break
            case .pending:
                purchaseError = "Purchase is pending"
            @unknown default:
                purchaseError = "Unknown error occurred"
            }
        } catch {
            purchaseError = error.localizedDescription
        }
        
        isProcessingPurchase = false
    }
    
    @MainActor
    func restorePurchases() async {
        isProcessingPurchase = true
        
        do {
            try await AppStore.sync()
            await updatePurchaseStatus()
        } catch {
            purchaseError = "Failed to restore purchases"
        }
        
        isProcessingPurchase = false
    }
    
    // MARK: - Pricing Info
    
    func getMonthlyPrice() -> String {
        guard let product = products.first(where: { $0.id == monthlySubscriptionID }) else {
            return "$4.99/month"
        }
        return product.displayPrice
    }
    
    func getYearlyPrice() -> String {
        guard let product = products.first(where: { $0.id == yearlySubscriptionID }) else {
            return "$39.99/year"
        }
        return product.displayPrice
    }
    
    func getLifetimePrice() -> String {
        guard let product = products.first(where: { $0.id == lifetimeID }) else {
            return "$99.99"
        }
        return product.displayPrice
    }
}