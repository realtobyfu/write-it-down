import SwiftUI
import Lottie
import StoreKit

struct DonationView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var donationManager = DonationManager()
    
    @State var animationProgress: CGFloat = 0
    @State private var isPurchasing = false
    @State private var showThankYou = false
    
    private let donationSteps: [CGFloat] = [0.0, 0.2, 0.333333, 0.533333, 0.8, 1.0]
    private let startFrame: CGFloat = 78
    private let endFrame: CGFloat = 92
    
    // Calculate actual dollar amounts
    private var priceTiers: [String] {
        return ["Free", "$2.99", "$4.99", "$7.99", "$11.99", "$14.99"]
    }
    
    private var currentFrame: CGFloat {
        let totalFrames = endFrame - startFrame
        return startFrame + totalFrames * animationProgress
    }
    
    private var closestDonationStep: CGFloat {
        donationSteps.min(by: { abs($0 - animationProgress) < abs($1 - animationProgress) }) ?? 0
    }
    
    // Dynamic color based on donation amount
    private var donationColor: Color {
        switch closestDonationStep {
        case 0.0: return .pink
        case 0.2: return .teal
        case 0.333333: return .green
        case 0.533333: return .orange
        case 0.8: return .blue
        case 1.0: return .purple
        default: return .blue
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.orange.opacity(0.15)
                    .edgesIgnoringSafeArea(.all)
                
                // Content
                VStack(spacing: 0) {
                    Spacer(minLength: 20)
                    
                    // Main content as VStack instead of ScrollView
                    VStack(spacing: 0) {
                        // Title section with proper spacing
                        VStack(spacing: 10) {
                            Text("Tip the Developer")
                                .font(.system(size: 30, weight: .bold))
                                .multilineTextAlignment(.center)
                            
                            Text("Choose any price to help us continue improving the app")
                                .font(.system(size: 17))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, geometry.size.height * 0.06)
                        .padding(.bottom, geometry.size.height * 0.01)
                        
                        // Lottie animation with adaptive size
                        LottieView(animation: .named("smiley"))
                            .resizable()
                            .configure(\.contentMode, to: .scaleAspectFill)
                            .currentFrame(currentFrame)
                            .frame(
                                width: min(360, geometry.size.width * 0.8),
                                height: min(360, geometry.size.width * 0.8)
                            )
                            .padding(.bottom, geometry.size.height * 0.02)
                        
                        // Price display
                        Text(closestDonationStep == 0 ? "Free" : String(format: "$%.2f", Float(closestDonationStep * 15 - 0.01)))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(donationColor)
                            .padding(.bottom, geometry.size.height * 0.04)
                        
                        // Slider with padding
                        VStack(spacing: 12) {
                            Slider(value: $animationProgress, in: 0...1)
                                .accentColor(donationColor)
                                .padding(.horizontal, geometry.size.width * 0.1)
                            
                            // Price labels
                            HStack(spacing: 0) {
                                ForEach(0..<priceTiers.count, id: \.self) { index in
                                    Text(priceTiers[index])
                                        .font(.footnote)
                                        .foregroundColor(donationSteps[index] == closestDonationStep ? donationColor : .gray)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal, geometry.size.width * 0.08)
                        }
                        .padding(.bottom, geometry.size.height * 0.07)
                        
                        // Support button with proper padding
                        Button(action: {
                            if closestDonationStep == 0 {
                                // Continue for free
                                presentationMode.wrappedValue.dismiss()
                            } else {
                                // Find the donation tier index
                                if let index = donationSteps.firstIndex(of: closestDonationStep),
                                   index > 0,
                                   let product = donationManager.productForIndex(index) {
                                    
                                    // Set state before task
                                    isPurchasing = true
                                    
                                    // Initiate the purchase
                                    Task {
                                        do {
                                            let success = try await donationManager.purchase(product: product)
                                            
                                            await MainActor.run {
                                                if success {
                                                    showThankYou = true
                                                }
                                                isPurchasing = false
                                            }
                                        } catch {
                                            print("Purchase failed: \(error)")
                                            
                                            await MainActor.run {
                                                isPurchasing = false
                                            }
                                        }
                                    }
                                }
                            }
                        }) {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(donationColor)
                                    .cornerRadius(25)
                            } else {
                                Text(closestDonationStep == 0 ? "Continue for Free" : "Support with \(priceTiers[donationSteps.firstIndex(of: closestDonationStep) ?? 0])")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(donationColor)
                                    .cornerRadius(25)
                            }
                        }
                        .disabled(isPurchasing)
                        .padding(.horizontal, geometry.size.width * 0.1)
                        .padding(.bottom, geometry.size.height * 0.01)
                    }
                    
                    Spacer(minLength: 25)
                }
                .edgesIgnoringSafeArea([.top, .bottom]) // Ignoring safe areas for top and bottom
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showThankYou) {
            Alert(
                title: Text("Thank You!"),
                message: Text("Your support helps us continue improving the app."),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

#Preview {
    Group {
        
        DonationView()
    }
}

