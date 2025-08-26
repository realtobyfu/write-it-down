//
//  OnboardingView.swift
//  Write-It-Down
//
//  Created by Tobias Fu on 4/9/25.
//

// Create a new SwiftUI view called OnboardingView.swift
import SwiftUI

struct OnboardingView: View {
    @StateObject private var coordinator = OnboardingCoordinator()

    var body: some View {
        ZStack {
            // Clean white background
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ProgressBar(currentStep: coordinator.currentStep, totalSteps: coordinator.totalSteps)
                    .padding(.horizontal)
                    .padding(.top)

                TabView(selection: $coordinator.currentStep) {
                    WelcomeStep()
                        .tag(0)

                    CoreFeaturesDemo()
                        .tag(1)

                    PremiumOverviewStep()
                        .tag(2)
                    
                    GetStartedStep()
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                HStack(spacing: 16) {
                    if coordinator.currentStep > 0 {
                        Button("Back") {
                            coordinator.previousStep()
                        }
                        .font(.body)
                        .foregroundColor(.secondary)
                    } else {
                        // Invisible spacer to keep Next button aligned
                        Button("Back") {
                            coordinator.previousStep()
                        }
                        .font(.body)
                        .foregroundColor(.clear)
                    }

                    Spacer()

                    Button(coordinator.currentStep == coordinator.totalSteps - 1 ? "Get Started" : "Next") {
                        if coordinator.currentStep == coordinator.totalSteps - 1 {
                            coordinator.completeOnboarding()
                        } else {
                            coordinator.nextStep()
                        }
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.0, green: 0.48, blue: 1.0))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }
}
