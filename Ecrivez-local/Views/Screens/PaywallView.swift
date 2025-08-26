import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    
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
            VStack(spacing: 8) {
                Text("Premium")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text(premiumManager.getYearlyPrice())
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("per year")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("Billed annually")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var ctaButton: some View {
        Button(action: {
            Task {
                await premiumManager.purchaseYearlySubscription()
                
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
        return "Continue"
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
