//
//  SupabaseManager.swift
//  Ecrivez-local
//
//  Created xby Tobias Fu on 12/20/24.
//


import SwiftUI
import Supabase
import Boutique

/// Your global manager for Supabase
class SupabaseManager: ObservableObject {
    // Singleton or shared instance
    @MainActor static let shared = SupabaseManager()

    let client: SupabaseClient
    
    /// Here's the Boutique stored property
//    @ObservationIgnored
//    @StoredValue(wrappedValue: nil, key: "currentUserSession") private var storedSession: CurrentUserSession?
    
    // Track whether user is authenticated in memory
    @Published var isAuthenticated: Bool = false
    
    private init() {
        let supabaseUrl = URL(string: "https://qrfiagbuwbqkpfnjuepd.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFyZmlhZ2J1d2Jxa3Bmbmp1ZXBkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI2ODExODYsImV4cCI6MjA0ODI1NzE4Nn0.ATQV9LFofoQubykX6V2R6mQ499V3eIoIDVCRcEcSN1Q"

        self.client = SupabaseClient(
            supabaseURL: supabaseUrl,
            supabaseKey: supabaseKey
        )
        
        // 1) On init, try to restore session from Boutique
//        Task {
//            await restoreSessionIfAvailable()
//        }
    }
    
//    // MARK: - Session Restoration
//    
//    /// If we have a session stored in Boutique, set it in Supabase.
//    @MainActor
//    private func restoreSessionIfAvailable() async {
//        guard let savedSession = storedSession else {
//            print("[SupabaseManager] No saved session found in Boutique.")
//            isAuthenticated = false
//            return
//        }
//        do {
//            // This tries to make Supabase accept that old session
//            try await client.auth.setSession(
//                accessToken: savedSession.accessToken,
//                refreshToken: savedSession.refreshToken
//            )
//            print("[SupabaseManager] Successfully restored session from Boutique!")
//            isAuthenticated = true
//        } catch {
//            print("[SupabaseManager] Failed to restore session: \(error)")
//            isAuthenticated = false
//        }
//    }
//    
//    // MARK: - Store or Clear Session
//    
//    /// Called when the user successfully logs in or refreshes their session.
//    @MainActor
//    func storeSession(accessToken: String, refreshToken: String) async {
//        let newSession = CurrentUserSession(
//            accessToken: accessToken,
//            refreshToken: refreshToken
//        )
//        
//        // Save to supabase-swift memory too, if needed:
//        do {
//            try await client.auth.setSession(
//                accessToken: accessToken,
//                refreshToken: refreshToken
//            )
//            isAuthenticated = true
//        } catch {
//            print("[SupabaseManager] Error calling setSession: \(error)")
//        }
//        
//        // Save to Boutique
//        do {
//            try $storedSession.set(newSession)
//            print("[SupabaseManager] Session saved in Boutique.")
//        } catch {
//            print("[SupabaseManager] Failed to store session in Boutique: \(error)")
//        }
//    }
//    
//    /// Called when user logs out
//    @MainActor
//    func clearSession() async {
//        do {
//            // Clear on server side
//            try await client.auth.signOut()
//        } catch {
//            print("[SupabaseManager] signOut error: \(error)")
//        }
//        
////        // Clear locally
////        do {
////            try $storedSession.remove()
////            print("[SupabaseManager] Session removed from Boutique.")
////        } catch {
////            print("[SupabaseManager] Failed to remove session: \(error)")
////        }
//        
//        isAuthenticated = false
//    }
}

