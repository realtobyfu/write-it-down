//
//  SupabaseManager.swift
//  Ecrivez-local
//
//  Created xby Tobias Fu on 12/20/24.
//


import SwiftUI
import Supabase

/// Your global manager for Supabase
class SupabaseManager: ObservableObject {
    // Singleton or shared instance
    @MainActor static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    // Track whether user is authenticated in memory
    @Published var isAuthenticated: Bool = false
    
    private init() {
        let supabaseUrl = URL(string: "https://qrfiagbuwbqkpfnjuepd.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFyZmlhZ2J1d2Jxa3Bmbmp1ZXBkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI2ODExODYsImV4cCI6MjA0ODI1NzE4Nn0.ATQV9LFofoQubykX6V2R6mQ499V3eIoIDVCRcEcSN1Q"
        
        self.client = SupabaseClient(
            supabaseURL: supabaseUrl,
            supabaseKey: supabaseKey
        )
    }
}
