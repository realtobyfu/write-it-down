////
////  EnterUsernameView.swift
////  Ecrivez-local
////
////  Created by Tobias Fu on 12/23/24.
////
//
import SwiftUI
import Supabase

struct UserView: View {
    
    @ObservedObject var authVM: AuthViewModel
    @State private var profile: Profile?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // Store user ID and email in state so we can pass them to NewUserProfileView
    @State private var userId: String = ""       // <-- Changed to String
    @State private var userEmail: String = ""

    var body: some View {
        NavigationStack {
            if isLoading {
                ProgressView("Loading profile...")
            }
            else if let profile = profile {
                // We found a matching row in "profiles"
                ProfileView(authVM: authVM, editedProfile: profile)
            }
            else {
                // No profile row, so let them create one if we have a valid userId
                if !userId.isEmpty {
                    // Pass a binding for `profile`
                    NewUserProfileView(
                        userId: userId,
                        userEmail: userEmail,
                        userProfile: $profile  // <-- here's the binding
                    )
                } else {
                    Text("Error: Missing user session.")
                        .foregroundColor(.red)
                }
            }
        }
        .task {
            await loadUserProfile()
        }
    }
    
    private func loadUserProfile() async {
        do {
            // 1) Get current user session (async call)
            let session = try await SupabaseManager.shared.client.auth.session
            let user = session.user
            // Fill in state for userId and userEmail
            self.userId = user.id.uuidString
            self.userEmail = user.email ?? ""
            
            // 2) Query "profiles" by id == userId
            // Attempt to decode a single Profile. .value requires typed generics.
            // If no row is found, .value typically throws an error (status 406).
            let fetchedProfile: Profile = try await SupabaseManager.shared.client
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            

            // If found, assign it to `profile`
            self.profile = fetchedProfile

        } catch {
            // "No row returned" typically triggers an error with code 406
            // So that means the user has no existing profile -> self.profile remains nil
            self.errorMessage = "Error: \(error.localizedDescription)"
        }
        self.isLoading = false
    }
}
