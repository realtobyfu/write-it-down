import SwiftUI
import Supabase
import CryptoKit

/// ViewModel to handle user authentication logic and states.
@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var email: String = ""
    
    // For Apple Sign-In
    @Published var currentNonce: String? = nil

    func checkIsAuthenticated() async {
        do {
            _ = try await SupabaseManager.shared.client.auth.session
            isAuthenticated = true
        } catch {
            print("No valid session found: \(error)")
            isAuthenticated = false
        }
    }

    /// Replaces your old signInWithOTP usage
    func signIn() async {
        isLoading = true
        errorMessage = nil
        guard isValidEmail(email) else {
            errorMessage = "Invalid email format"
            isLoading = false
            return
        }

        do {
            try await SupabaseManager.shared.client.auth.signInWithOTP(
                email: email,
                redirectTo: URL(string: "com.tobiasfu.write-it-down://login-callback")
            )
            // If successful, user will tap link from their inbox ->
            // handleURL in the App sets isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    /// A basic email format check. You can replace with a more robust regex if you like.
    private func isValidEmail(_ email: String) -> Bool {
        // Quick check that it's non-empty, has an "@" and a dot after it
        // For a more advanced approach, see a robust regex approach.
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("@"), trimmed.contains(".") else { return false }
        return trimmed.count > 5
    }


    func signOut() {
        Task {
            do {
                try await SupabaseManager.shared.client.auth.signOut()
            } catch {
                print("Sign out error: \(error)")
            }
            isAuthenticated = false
        }
    }

    
    // 1) Generate random nonce
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let chars = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var random: UInt8 = 0
            let err = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if err != errSecSuccess {
                fatalError("Unable to generate nonce. Error code: \(err)")
            }
            if random < chars.count {
                result.append(chars[Int(random) % chars.count])
                remainingLength -= 1
            }
        }
        return result
    }

    // 2) Called after Apple returns an ID token
    func signInWithApple(idTokenString: String) async throws {
        guard let nonce = currentNonce else {
            throw URLError(.badServerResponse)
        }
        // Clear the nonce so it’s only used once
        currentNonce = nil

        // Supabase sign in using Apple ID token
        let session = try await SupabaseManager.shared.client.auth.signInWithIdToken(
            credentials: .init(
              provider: .apple,
              idToken: idTokenString
            )
        )
        print("Signed in with Apple. Supabase session: \(session)")
        isAuthenticated = true
    }

    func didCompleteSignIn() {
        isAuthenticated = true
    }
}
