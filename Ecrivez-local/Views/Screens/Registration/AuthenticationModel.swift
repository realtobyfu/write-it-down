import SwiftUI
import Supabase

/// ViewModel to handle user authentication logic and states.
@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var email: String = ""

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

    func didCompleteSignIn() {
        isAuthenticated = true
    }
}
