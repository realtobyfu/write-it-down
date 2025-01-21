//
//  NewUserProfileView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 1/16/25.
//

import SwiftUI
import Supabase

struct NewUserProfileView: View {
    /// The userId and userEmail from the parent (UserView)
    let userId: String
    let userEmail: String
    @Binding var userProfile: Profile?

    @State private var username: String = ""
    @State private var displayName: String = ""

    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Create your Profile")
                .font(.headline)

            Text("Email: \(userEmail)")
                .foregroundColor(.secondary)

            TextField("Username", text: $username)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)

            TextField("Display Name", text: $displayName)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            Button("Save Profile") {
                Task {
                    await saveProfile()
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(isSaving ? Color.gray : Color.blue)
            .cornerRadius(8)
            .disabled(isSaving)

            Spacer()
        }
        .padding()
    }

    private func saveProfile() async {
        
        guard !username.isEmpty else {
            errorMessage = "Please enter a username."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            // The Profile struct's `id` is a String (matching the user's ID from Supabase)
            let newProfile = Profile(
                id: userId,
                username: username,
                email: userEmail,
                display_name: displayName
            )

            // Insert into "profiles"
            try await SupabaseManager.shared.client
                .from("profiles")
                .insert([newProfile], returning: .representation)
                .single()
                .execute()
            
            // TODO: authenticate this / sync from the server?
            userProfile = newProfile
//            userProfile = savedProfile


            // You might call back into UserView to refresh or navigate
            // e.g. pop or dismiss this view if it's in a sheet.

        } catch {
            errorMessage = "Failed to create profile: \(error.localizedDescription)"
        }
    }
}
