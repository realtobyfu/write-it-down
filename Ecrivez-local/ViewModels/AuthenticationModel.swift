import SwiftUI
import Observation
import Supabase


struct Profile: Codable {
    let id: UUID      // the user.id as a string
  let username: String
  let phone: String
}

@Observable
@MainActor
final class AuthenticationViewModel {

  // MARK: - Fields Bound to UI
  var email: String = ""
  var code: String = ""
  var username: String = ""     // If user is new, ask for username

  // Flow states
  var isVerifyingCode = false
  var showUsernameField = false

  // Toast
  var toast: ToastState?

  // MARK: - Main Button Action
    func handleAction(onSuccess: @escaping () -> Void) {
        if !isVerifyingCode {
            // Not sent code yet -> Send code
            Task { await sendOTP() }
        } else if isVerifyingCode && !showUsernameField {
            // Entering OTP -> Verify code
            Task { await verifyCode(onSuccess: onSuccess) }
        }
    }

  // MARK: - Step 1: Send OTP
    private func sendOTP() async {
    guard !email.isEmpty else {
      showError("Please enter your email.")
      return
    }

    do {
      try await SupabaseManager.shared.client.auth.signInWithOTP(email: email)
      isVerifyingCode = true
      showSuccess("OTP sent! Check your email.")
    } catch {
//        print("Phone Number used:", email)
        print(error.localizedDescription)
      showError("Failed to send OTP: \(error.localizedDescription)")
    }
  }

  // MARK: - Step 2: Verify Code
  private func verifyCode(onSuccess: @escaping  () -> Void) async {
    guard !code.isEmpty else {
      showError("Please enter the verification code.")
      return
    }

    do {
        let session = try await SupabaseManager.shared.client.auth.verifyOTP(
        email: email,
        token: code,
        type: .signup
      )
//       session.user is the newly authenticated user
      let userId = session.user.id // This is a String

      // Check if profile already exists
      let exists = try await doesProfileExist(for: userId)
      if exists {
        // If profile is found, we are done
        onSuccess()
      } else {
        // Ask user for username
        showUsernameField = true
      }
        onSuccess()

    } catch {
      showError("Failed to verify code: \(error.localizedDescription)")
    }
  }

//  // MARK: - Step 3: Check If Profile Exists
  private func doesProfileExist(for userId: UUID) async throws -> Bool {
      let response: [Profile] = try await SupabaseManager.shared.client
//      .database
      .from("profiles")
      .select("*")
      .eq("id", value: userId)
      .execute()
      .value

    // Use the new decoding approach
//    let rows = try response.decoded(to: [Profile].self)
    return !response.isEmpty
  }
//
//  // MARK: - Step 4: Create Profile
//  private func createUserProfileIfNeeded() async {
//    guard !username.isEmpty else {
//      showError("Please choose a username.")
//      return
//    }
//
//    // Session is no longer optional. Directly access it:
//      do {
//          let session = try await SupabaseManager.shared.client.auth.session
//          let userId = session.user.id
//          // Continue with your logic...
//      } catch {
//          // Handle the error—e.g., show a toast or set an error message
//          showError("No authenticated user found: \(error.localizedDescription)")
//          return
//      }
//
//    do {
//      let profile = Profile(id: userId, username: username, phone: phoneNumber)
//      _ = try await SupabaseManager.shared.client
//        .from("profiles")
//        .insert([profile], returning: .representation)
//        .execute()
//
//      showSuccess("Profile created successfully!")
//    } catch {
//      showError("Failed to create profile: \(error.localizedDescription)")
//    }
//  }
//
  // MARK: - Helpers
  private func showError(_ message: String) {
    toast = ToastState(
      status: .error,
      title: "Error",
      description: message
    )
  }

  private func showSuccess(_ message: String) {
    toast = ToastState(
      status: .success,
      title: "Success",
      description: message
    )
  }
}
