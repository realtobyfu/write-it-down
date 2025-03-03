//
//  AuthenticationView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 12/14/24.
//
import SwiftUI

struct AuthenticationView: View {
    @ObservedObject var authVM: AuthViewModel
    
    @State private var result: Result<Void, Error>?

    var body: some View {
        Form {
            VStack(spacing: 20) {
                Spacer().frame(height: 15)
                
                Text("Create an Account to share your notes!")
                    .font(.custom("AmericanTypewriter", fixedSize: 20))
                    .padding(.horizontal, 10)
                
                Text("Enter email to receive a magic link!")
                    .font(.custom("AmericanTypewriter", fixedSize: 20))
                    .padding(.horizontal, 10)
                
                Section {
                    TextField("Email", text: $authVM.email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section {
                    Button("Sign in") {
                        signInButtonTapped()
                    }
                    
                    if authVM.isLoading {
                        ProgressView()
                    }
                }
                
                if let result {
                    Section {
                        switch result {
                        case .success:
                            Text("Check your inbox.")
                        case .failure(let error):
                            Text(error.localizedDescription).foregroundStyle(.red)
                        }
                    }
                }
            }
        }
    }
    /// A basic email format check. You can replace with a more robust regex if you like.
    private func isValidEmail(_ email: String) -> Bool {
        // Quick check that it's non-empty, has an "@" and a dot after it
        // For a more advanced approach, see a robust regex approach.
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("@"), trimmed.contains(".") else { return false }
        return trimmed.count > 5
    }

    private func signInButtonTapped() {
        Task {
            // Start spinner
            authVM.isLoading = true
            do {
                try await authVM.signIn()
                // If no error is thrown, we consider signIn success
                result = .success(())
            } catch {
                // If signIn() rethrows, handle here
                result = .failure(error)
            }
            // Stop spinner
            authVM.isLoading = false
        }
    }
}
