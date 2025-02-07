//
//  Ecrivez_localApp.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 7/22/24.
//
import SwiftUI
import CoreData
import Boutique

struct CurrentUser: Codable, Equatable {
    let userId: String
    let accessToken: String
    let refreshToken: String
}



@main
struct NoteApp: App {
    
    // at the root level, define the behaviors for when app is opened again
    // if auth screen is still open -> dismiss it
    // optional: show a message indicating the user is logged in
    // go to the home screen
    @StateObject private var dataController = DataController()
    
    
    @StateObject private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(authVM)

                .onOpenURL { url in
                    Task {
                        await handleURL(url: url)
                    }
                }
                .task {
                    // On launch, check if there's an existing valid session
                    await authVM.checkIsAuthenticated()
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
