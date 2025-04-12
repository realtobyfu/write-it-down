//
//  Ecrivez_localApp.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 7/22/24.
//
import SwiftUI
import CoreData



@main
struct NoteApp: App {
    
    // at the root level, define the behaviors for when app is opened again
    // if auth screen is still open -> dismiss it
    // optional: show a message indicating the user is logged in
    // go to the home screen
    @StateObject private var dataController = CoreDataManager()
    @StateObject private var authVM = AuthViewModel()
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false
    
    @AppStorage("onboardingVersion") private var onboardingVersion = 0
    let currentOnboardingVersion = 0 // Increase this when you update onboarding
    
    @AppStorage("appOpenCount") private var appOpenCount = 0
    @State private var showDonationView = false

    var body: some Scene {
        WindowGroup {
            if onboardingVersion < currentOnboardingVersion {
                OnboardingView(showOnboarding: $showOnboarding)
                    .onDisappear {
                        onboardingVersion = currentOnboardingVersion
                    }
            } else {
                ContentView()
                    .environment(\.managedObjectContext, dataController.container.viewContext)
                    .environmentObject(authVM)
                    .preferredColorScheme(isDarkMode ? .dark : .light)
                
                    .onOpenURL { url in
                        Task {
                            await handleURL(url: url)
                        }
                    }
                    .task {
                        // On launch, check if there's an existing valid session
                        await authVM.checkIsAuthenticated()
                        
                        appOpenCount += 1
                        
                        // Show donation view after 3 opens
                        if appOpenCount == 3 {
                            // Delay showing the donation view slightly for better UX
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                showDonationView = true
                            }
                        }
                    }
            }
        }
    }
    
    func handleURL(url: URL) async {
        // 1) Ensure the callback scheme is correct
        guard url.scheme == "com.tobiasfu.write-it-down" else {
            print("Received unsupported URL scheme.")
            return
        }
        do {
            try await SupabaseManager.shared.client.auth.session(from: url)
            authVM.didCompleteSignIn()
        } catch {
            print("Failed to parse session: \(error)")
        }

        
        
        
    }
}
