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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showDonationView = false
    
    @AppStorage("appOpenCount") private var appOpenCount = 0

    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else {
                ContentView()
                    .environment(\.managedObjectContext, dataController.container.viewContext)
                    .environmentObject(authVM)
                    .environmentObject(dataController)
                    .preferredColorScheme(isDarkMode ? .dark : .light)
                
                    .onOpenURL { url in
                        Task {
                            await handleURL(url: url)
                        }
                    }
                    .task {
                        // On launch, check if there's an existing valid session
                        await authVM.checkIsAuthenticated()
                        
                        // Check database health on app launch
                        let isHealthy = dataController.checkDatabaseHealth()
                        if !isHealthy {
                            print("WARNING: Database health check failed on app launch")
                        }
                        
                        // Clean up any duplicate categories on app launch
                        do {
                            try await SyncManager.shared.cleanupDuplicateCategories(context: dataController.container.viewContext)
                        } catch {
                            print("Failed to cleanup duplicate categories: \(error)")
                        }
                        
                        // Trigger sync on app launch if authenticated and enabled
                        if authVM.isAuthenticated && SyncManager.shared.syncEnabled {
                            await SyncManager.shared.performAutoSync(context: dataController.container.viewContext)
                        }
                        
                        appOpenCount += 1
                        
                        // Show donation view after 3 opens
                        if appOpenCount == 4 || (appOpenCount >= 0 && appOpenCount % 10 == 0){
                            // Delay showing the donation view slightly for better UX
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                showDonationView = true
                            }
                        }
                    }
                    .onChange(of: authVM.isAuthenticated) { oldValue, newValue in
                        // Trigger sync when user becomes authenticated
                        if !oldValue && newValue && SyncManager.shared.syncEnabled {
                            Task {
                                await SyncManager.shared.performAutoSync(context: dataController.container.viewContext)
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
