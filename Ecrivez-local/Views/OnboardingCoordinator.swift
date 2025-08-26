import SwiftUI

@MainActor
class OnboardingCoordinator: ObservableObject {
    @Published var currentStep = 0
    let totalSteps = 4

    func nextStep() {
        if currentStep < totalSteps - 1 {
            withAnimation(.spring()) {
                currentStep += 1
            }
        }
    }

    func previousStep() {
        if currentStep > 0 {
            withAnimation(.spring()) {
                currentStep -= 1
            }
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
} 