import SwiftUI
import Lottie

struct DonationView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    @State var animationProgress: CGFloat = 0
    private let donationSteps: [CGFloat] = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
    private let startFrame: CGFloat = 78
    private let endFrame: CGFloat = 92
    
    // Calculate actual dollar amounts
    private var priceTiers: [String] {
        return ["Free", "$3", "$6", "$9", "$12", "$15"]
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
        case 0.4: return .green
        case 0.6: return .orange
        case 0.8: return .blue
        case 1.0: return .purple
        default: return .blue
        }
    }

    var body: some View {
        ZStack {
            // Orange background for entire view
            Color.orange.opacity(0.15).edgesIgnoringSafeArea(.all)
            
            // Content
            VStack(spacing: 15) {
                // Just the X button in the corner - no back button or settings text
                HStack {
                    Spacer()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
                .background(Color.clear)
                .zIndex(1) // Ensure button stays on top
                
                // Scrollable content
                ScrollView {
                    VStack(spacing: 25) {
                        // Title section
                        VStack(spacing: 8) {
                            Text("Tip the Developer")
                                .font(.system(size: 30, weight: .bold))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Text("Choose any price to help us continue improving the app")
                                .font(.system(size: 17))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, 5)
                        
                        // Larger smiley face animation
                        LottieView(animation: .named("smiley"))
                            .resizable()
                            .configure(\.contentMode, to: .scaleAspectFill)
                            .currentFrame(currentFrame)
                            .frame(width: 400, height: 400) // Increased size
                            .padding(.top, -30) // Adjust spacing
                        
                        // Price display with dynamic color
                        Text(closestDonationStep == 0 ? "Free" : "$\(Int(closestDonationStep * 15))")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(donationColor)
                            .padding(.top, -20)
                        
                        // Slider with dynamic color
                        VStack(spacing: 10) {
                            Slider(value: $animationProgress, in: 0...1)
                                .accentColor(donationColor)
                                .padding(.horizontal)
                            
                            // Price labels with dynamic highlighting
                            HStack(spacing: 0) {
                                ForEach(0..<priceTiers.count, id: \.self) { index in
                                    Text(priceTiers[index])
                                        .font(.footnote)
                                        .foregroundColor(donationSteps[index] == closestDonationStep ? donationColor : .gray)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Support button with dynamic color
                        Button(action: {
                            // Handle payment
                        }) {
                            Text(closestDonationStep == 0 ? "Continue for Free" : "Support with \(priceTiers[donationSteps.firstIndex(of: closestDonationStep) ?? 0])")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(donationColor)
                                .cornerRadius(25)
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, 15)
                        
                        // Bottom spacing
                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .navigationBarHidden(true) // Hide the navigation bar
    }
}
