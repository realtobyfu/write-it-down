import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var selectedSubscription: SubscriptionType = .yearly
    
    enum SubscriptionType {
        case monthly, yearly
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featuresSection
                    pricingSection
                    ctaButton
                    restoreButton
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationBarItems(trailing: closeButton)
            .alert("Restore Purchases", isPresented: $showRestoreAlert) {
                Button("OK") {}
            } message: {
                Text(restoreMessage)
            }
        }
    }
    
    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.gray)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Premium Features")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Everything you need to capture and organize your thoughts")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }
    
    private var featuresSection: some View {
        VStack(spacing: 16) {
            FeatureCard(
                icon: "infinity",
                title: "Unlimited Notes",
                description: "Create more than 10 notes with no restrictions"
            )
            
            FeatureCard(
                icon: "folder.badge.plus",
                title: "Custom Categories", 
                description: "Create and organize your own custom categories"
            )
            
            FeatureCard(
                icon: "icloud.and.arrow.up",
                title: "Cloud Sync",
                description: "Automatically sync your notes across all devices"
            )
        }
    }
    
    private var pricingSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Yearly Option (Recommended)
                subscriptionOption(
                    type: .yearly,
                    price: premiumManager.getYearlyPrice(),
                    period: "per year",
                    description: "Save 67% - Best Value!",
                    isRecommended: true
                )
                
                // Monthly Option  
                subscriptionOption(
                    type: .monthly,
                    price: premiumManager.getMonthlyPrice(),
                    period: "per month",
                    description: "Billed monthly",
                    isRecommended: false
                )
            }
        }
    }
    
    private func subscriptionOption(type: SubscriptionType, price: String, period: String, description: String, isRecommended: Bool) -> some View {
        Button(action: {
            selectedSubscription = type
        }) {
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .bottom, spacing: 4) {
                            Text(price)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(period)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(selectedSubscription == type ? Color.blue : Color.clear)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray, lineWidth: 2)
                            )
                        
                        if selectedSubscription == type {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                
                if isRecommended {
                    HStack {
                        Text("RECOMMENDED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(4)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedSubscription == type ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedSubscription == type ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var ctaButton: some View {
        Button(action: {
            Task {
                switch selectedSubscription {
                case .monthly:
                    await premiumManager.purchaseMonthlySubscription()
                case .yearly:
                    await premiumManager.purchaseYearlySubscription()
                }
                
                if premiumManager.purchaseError == nil {
                    dismiss()
                }
            }
        }) {
            if premiumManager.isProcessingPurchase {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(12)
            } else {
                Text(ctaButtonText)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.0, green: 0.48, blue: 1.0))
                    .cornerRadius(12)
            }
        }
        .disabled(premiumManager.isProcessingPurchase)
    }
    
    private var ctaButtonText: String {
        switch selectedSubscription {
        case .monthly:
            return "Start Monthly Subscription"
        case .yearly:
            return "Start Yearly Subscription"
        }
    }
    
    private var restoreButton: some View {
        Button(action: {
            Task {
                await premiumManager.restorePurchases()
                
                if premiumManager.currentTier != .free {
                    restoreMessage = "Purchases restored successfully!"
                    showRestoreAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                } else if let error = premiumManager.purchaseError {
                    restoreMessage = error
                    showRestoreAlert = true
                } else {
                    restoreMessage = "No purchases found to restore"
                    showRestoreAlert = true
                }
            }
        }) {
            Text("Restore Purchases")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 10)
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}


#Preview {
    PaywallView()
}
