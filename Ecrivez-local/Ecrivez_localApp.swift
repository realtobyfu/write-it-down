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
    @StateObject private var dataController = DataController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
            
                .onOpenURL { url in
                    handleURL(url: url)
                }
        }
    }
    
    func handleURL(url: URL) {
        // 1) Ensure the callback scheme is correct
        guard url.scheme == "com.tobiasfu.write-it-down" else {
            print("Received unsupported URL scheme.")
            return
        }
        
        // TODO: Fix the authentication here
//        // 2) Parse out the token (if you want to do manual checks)
//        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
//              let queryItems = components.queryItems,
//              let accessToken = queryItems.first(where: { $0.name == "access_token" })?.value else {
//            print("No access_token found in the callback URL.")
//            return
//        }
//        
//        // 3) If you want, do additional validations with `accessToken` here (e.g. log, confirm format, etc.)
//        print("Access token from URL: \(accessToken)")
        
        // 4) Now let Supabase parse the session
        Task {
            do {
                try await SupabaseManager.shared.client.auth.session
                print("Successfully parsed session from Supabase")
            } catch {
                print("Failed to parse session from url: \(error)")
            }
        }
    }

}
