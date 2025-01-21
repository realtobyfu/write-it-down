////
////  EnterUsernameView.swift
////  Ecrivez-local
////
////  Created by Tobias Fu on 12/23/24.
////
//
import Foundation
import SwiftUI
import Supabase

struct ProfileView: View {
    let email: String
    @State private var username: String = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome!")
                .font(.title)
            
            Text("Your account (\(email)) is now confirmed. Choose a username:")
            
            TextField("Username", text: $username)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            Button("Save Username") {
                Task {
                    await saveProfile()
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.green)
            .cornerRadius(8)

            Spacer()
        }
        .padding()
    }
    
    func getInitialProfile() async {
        do {
            
        }
    }

    private func saveProfile() async {
        guard !username.isEmpty else {
            errorMessage = "Please enter a username."
            return
        }

        // Example: Insert row into "profiles" table
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id
            let newProfile = Profile(id: userId, username: username, email: email)

            _ = try await SupabaseManager.shared.client.database
                .from("profiles")
                .insert([newProfile], returning: .representation)
                .execute()
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
        }
    }
}
