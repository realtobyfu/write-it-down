//
//  RegistrationView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 12/23/24.
//

import SwiftUI
import Supabase

struct RegistrationView: View {
    @Binding var email: String
    @Binding var password: String

    // Callbacks
    let onAutoConfirmed: () -> Void
    let onNeedsEmailCheck: () -> Void

    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Sign Up")
                .font(.headline)

            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)

            SecureField("Password", text: $password)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button("Sign Up") {
                Task {
                    await registerUser()
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.indigo.opacity(0.8))
            .cornerRadius(12)
            
        }
        .padding()

    }

    private func registerUser() async {
        // Basic validation
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        do {
            // signUp call
            let regAuthResponse = try await SupabaseManager.shared.client.auth
                .signUp(email: email, password: password)

            // If email confirmations are enabled, session == nil
            if let session = regAuthResponse.session {
                // The user is auto-confirmed (happens if you disabled confirmations in Supabase)
                print("User is auto-confirmed, session:", session)
                onAutoConfirmed()
            } else {
                // Usually the case if user must confirm email
                print("No session. Please check your email to confirm.")
                onNeedsEmailCheck()
            }
        } catch {
            errorMessage = "Registration failed: \(error.localizedDescription)"
        }
    }
}
