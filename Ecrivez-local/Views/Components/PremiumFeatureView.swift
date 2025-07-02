import SwiftUI

struct PremiumFeatureView<Content: View>: View {
    let feature: PremiumFeature
    let content: () -> Content
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var showPaywall = false
    
    var body: some View {
        if premiumManager.hasAccess(to: feature) {
            content()
        } else {
            Button(action: {
                showPaywall = true
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                    
                    Text(feature.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(feature.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("Tap to unlock")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}

struct PremiumGate: ViewModifier {
    let feature: PremiumFeature
    let showAlert: Bool
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var showPaywall = false
    @State private var showBlockedAlert = false
    
    func body(content: Content) -> some View {
        content
            .disabled(!premiumManager.hasAccess(to: feature))
            .onTapGesture {
                if !premiumManager.hasAccess(to: feature) {
                    if showAlert {
                        showBlockedAlert = true
                    } else {
                        showPaywall = true
                    }
                }
            }
            .alert("Premium Feature", isPresented: $showBlockedAlert) {
                Button("Upgrade") {
                    showPaywall = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("\(feature.displayName) is a premium feature. Upgrade to unlock!")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
    }
}

extension View {
    func premiumGate(_ feature: PremiumFeature, showAlert: Bool = false) -> some View {
        modifier(PremiumGate(feature: feature, showAlert: showAlert))
    }
}

struct PremiumBadge: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(4)
    }
}

struct FeatureRow: View {
    let feature: PremiumFeature
    let isUnlocked: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isUnlocked ? "checkmark.circle.fill" : "lock.circle")
                .foregroundColor(isUnlocked ? .green : .gray)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.displayName)
                    .font(.subheadline)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !isUnlocked {
                PremiumBadge()
            }
        }
        .padding(.vertical, 4)
    }
}

struct LimitWarningView: View {
    let itemType: String
    let currentCount: Int
    let limit: Int
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Free Tier Limit Reached")
                .font(.headline)
            
            Text("You've reached the limit of \(limit) \(itemType) on the free plan.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("\(currentCount) of \(limit) \(itemType) used")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: onUpgrade) {
                Label("Upgrade to Premium", systemImage: "crown.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
            }
            .padding(.top, 8)
        }
        .padding()
    }
}