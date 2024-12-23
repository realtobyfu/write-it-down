//
//  AuthenticationView.swift
//  Ecrivez-local
//
//  Created by Tobias Fu on 12/14/24.
//
import SwiftUI
struct AuthenticationView: View {
    // Enum to switch between login and registration
    enum AuthMode {
        case login
        case register
    }
    
    var model = AuthenticationViewModel()
    @Environment(\.presentationMode) var presentationMode // To dismiss the view
    
    @State private var authMode: AuthMode = .login
    
    // User input fields
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    // Error handling
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                    .frame(height: 15)
                Text("Create an Account to share your notes!")
                    .font(.custom(
                        "AmericanTypewriter",
                        fixedSize: 20))
                    .padding(.horizontal, 10)
                Spacer()
                    .frame(height: 35)
                // Toggle between Login and Register
                Picker(selection: $authMode, label: Text("Authentication")) {
                    Text("Login").tag(AuthMode.login)
                    Text("Register").tag(AuthMode.register)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Email Field
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                // Password Field
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                // Confirm Password Field (only for registration)
                if authMode == .register {
                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                }
                // Display error message if any
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                // Action Button
//                Button(action: handleAction) {
//                    Text("Log In")
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.blue)
//                        .cornerRadius(8)
//                }
//                .padding(.top, 10)
                
                Button(action: {
                    Task {
                        await handleAction()
                    }
                }) {
                    Text("Sign Up")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.indigo)
                        .opacity(0.8)
                        .cornerRadius(12)
                }
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .font(.custom(
            "AmericanTypewriter", size: 20))
    }
    
    // Handle Login or Registration
    private func handleAction() async {
        // Basic validation
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        
        if authMode == .register {
            guard password == confirmPassword else {
                errorMessage = "Passwords do not match."
                return
            }
            // Implement registration logic here
            await registerUser()
        } else {
            // Implement login logic here
            loginUser()
        }
    }
    
    // Placeholder for registration logic
    private func registerUser() async {
        do {
          try await model.registerNewUserWithEmail(email:email, password:password)
        } catch {
    //        print("Phone Number used:", email)
            print(error.localizedDescription)
        }

        print("Registering user with email: \(email)")
        // Simulate successful registration
        presentationMode.wrappedValue.dismiss()
    }
    
    // Placeholder for login logic
    private func loginUser() {
        // TODO: Integrate with your authentication backend (e.g., Firebase, OAuth)
        print("Logging in user with email: \(email)")
        // Simulate successful login
        presentationMode.wrappedValue.dismiss()
    }
}
struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
