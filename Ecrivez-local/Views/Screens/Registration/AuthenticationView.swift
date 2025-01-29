//
//  AuthenticationView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 12/14/24.
//
import SwiftUI
import Supabase

struct AuthenticationView: View {
    
    @Binding var isAuthenticated: Bool
    @State var email = ""
    @State var isLoading = false
    @State var result: Result<Void, Error>?

    var body: some View {
        Form {
            VStack(spacing: 20) {
                Spacer()
                    .frame(height: 15)
                Text("Create an Account to share your notes!")
                    .font(.custom(
                        "AmericanTypewriter",
                        fixedSize: 20))
                    .padding(.horizontal, 10)
                Text("Enter email to receive a magic link!")
                    .font(.custom(
                        "AmericanTypewriter",
                        fixedSize: 20))
                    .padding(.horizontal, 10)
                
                
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section {
                    Button("Sign in") {
                        signInButtonTapped()
                    }
                    
                    if isLoading {
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
//        .onOpenURL(perform: { url in
//            Task {
//                do {
//                    try await SupabaseManager.shared.client.auth.session(from: url)
//                } catch {
//                    self.result = .failure(error)
//                }
//            }
//        })
    }

  func signInButtonTapped() {
    Task {
      isLoading = true
      defer { isLoading = false }
        
      do {
          try await SupabaseManager.shared.client.auth.signInWithOTP(
            email: email,
            redirectTo: URL(string: "com.tobiasfu.write-it-down://login-callback")
        )
        result = .success(())
      } catch {
        result = .failure(error)
      }
    }
  }
}
