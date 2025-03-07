//
//  AuthenticationView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 12/14/24.
//
import SwiftUI
import AuthenticationServices
import CryptoKit

struct AuthenticationView: View {
    @ObservedObject var authVM: AuthViewModel
    
    @State private var result: Result<Void, Error>?

    var body: some View {
        Form {
            VStack(spacing: 20) {
                Spacer().frame(height: 15)
                
                Text("Create an Account to share your notes and interact with other users!")
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
                
                // Existing "Sign in" with Magic Link
                Section {
                    Button("Sign in") {
                        signInButtonTapped()
                    }
                    
                    if authVM.isLoading {
                        ProgressView()
                    }
                }
                
                // ******* ADD: Sign in with Apple ********
                Section {
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            // 1) Generate random nonce and store in authVM
                            let nonce = authVM.randomNonceString()
                            authVM.currentNonce = nonce

                            // 2) Hash the nonce and attach it to the request
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = sha256(nonce)
                        },
                        onCompletion: { outcome in
                            switch outcome {
                            case .success(let authorization):
                                handleAppleSignIn(authorization)
                            case .failure(let error):
                                print("Apple sign-in failed: \(error)")
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                }
                
                // Display result or error
                if let result {
                    Section {
                        switch result {
                        case .success:
                            Text("Check your inbox.")
                        case .failure(let error):
                            Text(error.localizedDescription)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Handle Magic Link Flow
    private func signInButtonTapped() {
        Task {
            authVM.isLoading = true
            do {
                try await authVM.signIn()
                result = .success(())
            } catch {
                result = .failure(error)
            }
            authVM.isLoading = false
        }
    }

    // MARK: - Handle Apple Credential
    private func handleAppleSignIn(_ authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("Invalid cred from Apple")
            return
        }
        
        // Grab the ID token data
        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to get Apple ID token as string")
            return
        }

        // Call into AuthViewModel
        Task {
            do {
                authVM.isLoading = true
                try await authVM.signInWithApple(idTokenString: idTokenString)
                // Optionally handle success in `result`
                result = .success(())
            } catch {
                result = .failure(error)
            }
            authVM.isLoading = false
        }
    }

    // MARK: - Helper: hash the nonce
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
