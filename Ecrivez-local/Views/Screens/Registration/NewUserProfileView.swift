//
//  NewUserProfileView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 1/16/25.
//

import SwiftUI
import Supabase

struct NewUserProfileView: View {
    /// These come from the parent (UserView) so the user doesn't need to type them again
    let userId: UUID?
    let userEmail: String

    @State private var username: String = ""
    @State private var displayName: String = ""

    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Create your Profile")
                .font(.headline)

            // Show the user's email in read-only format (optional)
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
            // Build a Profile object with the userId and userEmail from the parent
            let newProfile = Profile(
                id: userId!,
                username: username,
                email: userEmail,
                display_name: displayName
            )

            // Insert into "profiles"
            let response = try await SupabaseManager.shared.client
                .from("profiles")
                .insert([newProfile], returning: .representation)
                .single()  // we expect a single row back
                .execute()

            // You could also navigate away, store the profile in state, etc.
        } catch {
            errorMessage = "Failed to create profile: \(error.localizedDescription)"
        }
    }
}
