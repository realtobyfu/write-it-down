//
//  SupabaseManager.swift
//  Ecrivez-local
//
//  Created xby Tobias Fu on 12/20/24.
//


import SwiftUI
import Supabase
import OSLog

struct FeatureSuggestion: Codable {
    let id: UUID?
    let title: String
    let description: String
    let email: String?
}
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
        
        // Create client with logging enabled
        self.client = SupabaseClient(
            supabaseURL: supabaseUrl,
            supabaseKey: supabaseKey,
            options: SupabaseClientOptions(
                db: .init(), // Use default database options
                auth: .init() // Use default auth options
            )
        )
    }
    
    func submitFeatureSuggestion(_ suggestion: FeatureSuggestion) async throws {
        try await client
            .from("feature_suggestions")
            .insert(suggestion)
            .execute()
    }
    
    // Helper to check if a table exists and print its schema
    func checkTableSchema(tableName: String) async {
        do {
            print("Checking schema for table: \(tableName)")
            let result: [JSONObject] = try await client
                .from("information_schema.columns")
                .select("column_name, data_type, is_nullable")
                .eq("table_name", value: tableName)
                .execute()
                .value
            
            print("Table \(tableName) schema:")
            for column in result {
                print(" - \(column)")
            }
        } catch {
            print("Error checking schema: \(error.localizedDescription)")
        }
    }
    
    // Helper to test synced_categories table
    func testCategoriesTable() async {
        do {
            print("Fetching all categories from synced_categories table...")
            let result: [JSONObject] = try await client
                .from("synced_categories")
                .select()
                .execute()
                .value
            
            print("Retrieved \(result.count) categories from Supabase")
            for (index, category) in result.enumerated() {
                print("Category \(index + 1): \(category)")
            }
        } catch {
            print("Error fetching categories: \(error.localizedDescription)")
        }
    }
}
