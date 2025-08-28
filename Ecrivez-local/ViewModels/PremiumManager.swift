import Foundation
import StoreKit
import Combine
import Supabase

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
    // Core Premium Features (simplified model)
    case unlimitedNotes
    case unlimitedCategories
    case cloudSync
    case locationTagging
    case weatherTagging
    case imageInsertion
    case richTextFormatting
    case publicNoteSharing
    case darkMode
    case customThemes
    case socialFeatures
    case mapPinCustomization
    
    var displayName: String {
        switch self {
        case .unlimitedNotes: return "Unlimited Notes"
        case .unlimitedCategories: return "Custom Categories"
        case .cloudSync: return "Cloud Sync & Backup"
        case .locationTagging: return "Location Tagging"
        case .weatherTagging: return "Weather Tagging"
        case .imageInsertion: return "Image Insertion"
        case .richTextFormatting: return "Rich Text Formatting"
        case .publicNoteSharing: return "Public Note Sharing"
        case .darkMode: return "Dark Mode"
        case .customThemes: return "Custom Themes"
        case .socialFeatures: return "Social Features"
        case .mapPinCustomization: return "Map Pin Customization"
        }
    }
    
    var description: String {
        switch self {
        case .unlimitedNotes: return "Create more than 10 notes"
        case .unlimitedCategories: return "Create your own categories beyond defaults"
        case .cloudSync: return "Sync across all your devices"
        case .locationTagging: return "Tag notes with locations"
        case .weatherTagging: return "Add weather information to notes"
        case .imageInsertion: return "Insert images in your notes"
        case .richTextFormatting: return "Advanced text formatting options"
        case .publicNoteSharing: return "Share notes publicly"
        case .darkMode: return "Dark theme for comfortable viewing"
        case .customThemes: return "Customize app appearance"
        case .socialFeatures: return "Connect and interact with others"
        case .mapPinCustomization: return "Customize map pin colors and styles"
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
    
    // Debug mode for testing
    #if DEBUG
    @Published var debugModeEnabled = UserDefaults.standard.bool(forKey: "debugPremiumMode") {
        didSet {
            UserDefaults.standard.set(debugModeEnabled, forKey: "debugPremiumMode")
            if debugModeEnabled {
                currentTier = debugTier
            } else {
                Task {
                    await updatePurchaseStatus()
                }
            }
        }
    }
    @Published var debugTier: PremiumTier = .premium {
        didSet {
            if debugModeEnabled {
                currentTier = debugTier
            }
        }
    }
    #endif
    
    // StoreKit properties
    private var products: [Product] = []
    private var purchaseTask: Task<Void, Error>?
    private var updateListenerTask: Task<Void, Error>?
    
    // Product IDs
    private let monthlySubscriptionID = "com.tobiasfu.write-it-down.premium.monthly"
    private let yearlySubscriptionID = "com.tobiasfu.write-it-down.premium.yearly"
    
    // Free tier limits
    let freeNoteLimit = 10
    let freeCategoryLimit = 0 // Only default categories allowed
    
    private init() {
        #if DEBUG
        if debugModeEnabled {
            currentTier = debugTier
            return
        }
        #endif
        
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
        // Location tagging is free for all users
        if feature == .locationTagging {
            return true
        }
        
        switch currentTier {
        case .free:
            return false // Premium features (unlimited notes, custom categories, sync) are locked
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
    
    func canCreateCustomCategories() -> Bool {
        switch currentTier {
        case .free:
            return false // Free users can only use default categories
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
    
    // MARK: - Cross-Platform Sync with Supabase
    
    @MainActor
    func syncPremiumStatusWithSupabase(userID: UUID) async {
        do {
            // Check Supabase for premium status
            let response = try await SupabaseManager.shared.client
                .from("premium_subscriptions")
                .select()
                .eq("user_id", value: userID.uuidString)
                .single()
                .execute()
            
            let data = response.data
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            struct PremiumStatus: Decodable {
                let is_active: Bool
                let expiry_date: Date?
                let subscription_tier: String
            }
            
            if let status = try? decoder.decode(PremiumStatus.self, from: data) {
                if status.is_active {
                    if let expiryDate = status.expiry_date, expiryDate > Date() {
                        currentTier = .premium
                        subscriptionExpiryDate = expiryDate
                    }
                }
            }
        } catch {
            print("Error syncing premium status from Supabase: \(error)")
        }
    }
    
    @MainActor
    private func updateSupabasePremiumStatus(userID: UUID, isActive: Bool, expiryDate: Date?, platform: String = "ios") async {
        do {
            struct UpdatePremiumParams: Encodable {
                let p_user_id: String
                let p_is_active: Bool
                let p_expiry_date: String?
                let p_platform: String
            }
            
            let params = UpdatePremiumParams(
                p_user_id: userID.uuidString,
                p_is_active: isActive,
                p_expiry_date: expiryDate?.ISO8601Format(),
                p_platform: platform
            )
            
            _ = try await SupabaseManager.shared.client
                .rpc("update_premium_status", params: params)
                .execute()
        } catch {
            print("Error updating premium status in Supabase: \(error)")
        }
    }
    
    // MARK: - StoreKit Integration
    
    @MainActor
    private func loadProducts() async {
        do {
            let productIDs = [monthlySubscriptionID, yearlySubscriptionID]
            
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
    
    func purchaseYearlySubscription() async {
        await purchase(productID: yearlySubscriptionID)
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
                    
                    // Sync with Supabase for cross-platform
                    if let userID = await getCurrentUserID() {
                        await updateSupabasePremiumStatus(
                            userID: userID,
                            isActive: true,
                            expiryDate: transaction.expirationDate,
                            platform: "ios"
                        )
                    }
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
            return "$2.99"
        }
        return product.displayPrice
    }
    
    func getYearlyPrice() -> String {
        guard let product = products.first(where: { $0.id == yearlySubscriptionID }) else {
            return "$11.99"
        }
        return product.displayPrice
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func getCurrentUserID() async -> UUID? {
        // Get current user ID from Supabase auth
        do {
            let user = try await SupabaseManager.shared.client.auth.session.user
            return UUID(uuidString: user.id.uuidString)
        } catch {
            return nil
        }
    }
}
