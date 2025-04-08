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
    
    @State private var signInResult: Result<Void, Error>?

    var body: some View {
        VStack(spacing: 24) {
            
            Text("Create an Account")
                .font(.title2)
                .bold()
                .padding(.top, 20)
            
            Text("to share notes and interact with other users")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 3)
            
            // MARK: Email Field
            VStack(alignment: .leading, spacing: 6) {
                Text("Email address:")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                
                TextField("Enter your email", text: $authVM.email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.15)) // light gray background
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            
            // MARK: Sign in (Magic Link) Button
            VStack(spacing: 8) {
                Button {
                    Task {
                        await signInButtonTapped()
                    }
                } label: {
                    if authVM.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .frame(height: 22)
                    } else {
                        Text("Sign in with Magic Link")
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
                .padding(.horizontal, 20)
                
                if let error = authVM.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }
                
                if case .success = signInResult {
                    Text("Check your inbox for the magic link.")
                        .font(.footnote)
                        .foregroundColor(.green)
                        .padding(.horizontal, 20)
                }
            }

            Divider().padding(.vertical, 10)
            
            // MARK: Sign in with Apple
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    let nonce = authVM.randomNonceString()
                    authVM.currentNonce = nonce
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
            .cornerRadius(8)
            .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.top, 10)
        .background(Color(UIColor.systemBackground)) // or any custom color
        .edgesIgnoringSafeArea(.bottom)
    }
}

// MARK: - Private Helpers
extension AuthenticationView {
    
    private func signInButtonTapped() async {
        authVM.isLoading = true
        do {
            try await authVM.signIn()
            signInResult = .success(())
        } catch {
            signInResult = .failure(error)
        }
        authVM.isLoading = false
    }

    private func handleAppleSignIn(_ authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to get Apple ID token as string")
            return
        }
        Task {
            do {
                authVM.isLoading = true
                try await authVM.signInWithApple(idTokenString: idTokenString)
                signInResult = .success(())
            } catch {
                signInResult = .failure(error)
            }
            authVM.isLoading = false
        }
    }

    /// For extra security, hash the nonce before sending it to Apple.
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
