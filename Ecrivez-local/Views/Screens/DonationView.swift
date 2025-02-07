//
//  DonationView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 2/6/25.
//

import SwiftUI
import Lottie

struct DonationView: View {
    let starAnimationView = LottieAnimationView(name: "cool_animation")

    @State var animationProgress: CGFloat = 0
    @State private var donationAmount: CGFloat = 0.0
    private let donationSteps: [CGFloat] = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
    
    var body: some View {
        VStack {
            Text("Name Your Price")
                .font(.title)
                .padding()
            Text("Pay any price you want to use our app!")
                .font(.subheadline)
                .padding()
            LottieView(animation: .named("smiley"))
                .resizable()
                .configure(\.contentMode, to: .scaleAspectFill)
                .currentProgress(animationProgress)
                .frame(width: 250, height: 250)
            
            Slider(value: $animationProgress, in: 0...1)
            .padding()
            
            
            var donationAmount: CGFloat {
                let closestStep = donationSteps.min(by: { abs($0 - animationProgress) < abs($1 - animationProgress) }) ?? 0
                return closestStep // Scale to match donation value
            }

            Button(action: {
                // Handle donation logic here
            }) {
                Text(donationAmount == 0 ? "Free" : "$\(Int(donationAmount * 15))")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
            }
        }
        .foregroundStyle(.blue)
        .padding()
        .background(Color.orange)
    }
}
