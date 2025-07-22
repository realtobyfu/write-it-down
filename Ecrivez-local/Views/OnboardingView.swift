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
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                ProgressBar(currentStep: coordinator.currentStep, totalSteps: coordinator.totalSteps)
                    .padding()

                TabView(selection: $coordinator.currentStep) {
                    WelcomeStep()
                        .tag(0)

                    InteractiveCategoryDemo()
                        .tag(1)

                    RichTextEditingDemo()
                        .tag(2)

                    LocationAndMetadataDemo()
                        .tag(3)

                    PublicSharingDemo()
                        .tag(4)
                    
                    PremiumOverviewStep()
                        .tag(5)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                HStack {
                    if coordinator.currentStep > 0 {
                        Button("Back") {
                            coordinator.previousStep()
                        }
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(coordinator.currentStep == coordinator.totalSteps - 1 ? "Get Started" : "Next") {
                        if coordinator.currentStep == coordinator.totalSteps - 1 {
                            coordinator.completeOnboarding()
                        } else {
                            coordinator.nextStep()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }
}
