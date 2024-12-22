//
//  AuthenticationView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 12/14/24.
//
import SwiftUI

struct AuthenticationView: View {
    @Environment(\.presentationMode) private var presentationMode
    
    // iOS 17+ with @Observable
    @Bindable var model = AuthenticationViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Login / Sign Up with Email")
                    .font(.custom("AmericanTypewriter", size: 20))

                // Always show email field:
                TextField("Email (e.g. user@example.com)", text: $model.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)

                // Show code field only after sending code
                if model.isVerifyingCode {
                    TextField("Verification Code", text: $model.code)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                }

                // Show username field if user is brand new
                if model.showUsernameField {
                    TextField("Choose a username", text: $model.username)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                }

                // Main action button
                Button(action: {
                    model.handleAction {
                        // Dismiss on success
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text(buttonTitle)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        // Attach toast
        .toast(state: $model.toast)
    }

    private var buttonTitle: String {
        if !model.isVerifyingCode {
            return "Send Code"
        } else if model.isVerifyingCode && !model.showUsernameField {
            return "Verify Code"
        } else {
            return "Finish Setup"
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
