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
        Text("Login / Sign Up with Phone")
          .font(.custom("AmericanTypewriter", size: 20))

        // Always show phone field:
        TextField("Phone (+1 555-1234)", text: $model.phoneNumber)
          .keyboardType(.phonePad)
          .padding()
          .background(Color(UIColor.secondarySystemBackground))
          .cornerRadius(8)

        // Show code field only if verifying code
        if model.isVerifyingCode {
          TextField("Verification Code", text: $model.code)
            .keyboardType(.numberPad)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
        }

        // Show username field only if needed
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
