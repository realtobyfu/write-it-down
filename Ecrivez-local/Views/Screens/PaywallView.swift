import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var selectedPlan: PlanType = .yearly
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    
    enum PlanType {
        case yearly
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        featuresSection
                        plansSection
                        ctaButton
                        restoreButton
                    }
                    .padding()
                }
            }
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
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Unlock Premium")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Just $5/year for unlimited access")
                .font(.title2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's Included")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                FeatureItem(icon: "infinity", title: "Unlimited Notes", description: "Create more than 10 notes")
                FeatureItem(icon: "folder.fill", title: "Custom Categories", description: "Create your own categories")
                FeatureItem(icon: "icloud.fill", title: "Cloud Sync", description: "Access notes on all devices")
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var plansSection: some View {
        VStack(spacing: 12) {
            PlanOption(
                title: "Annual Premium",
                price: premiumManager.getYearlyPrice(),
                description: "Billed yearly",
                isSelected: true,
                badge: "ONLY $5/YEAR"
            ) {
                selectedPlan = .yearly
            }
        }
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
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
        }
        .disabled(premiumManager.isProcessingPurchase)
    }
    
    private var ctaButtonText: String {
        return "Unlock Premium - $5/year"
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
                .foregroundColor(.blue)
        }
        .padding(.top, 8)
    }
}

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct PlanOption: View {
    let title: String
    let price: String
    let description: String
    let isSelected: Bool
    let badge: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(price)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.blue.opacity(0.05) : Color.clear)
                    )
            )
        }
    }
}

#Preview {
    PaywallView()
}