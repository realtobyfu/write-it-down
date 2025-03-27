//
//  SuggestedFeature.swift
//  Write-It-Down
//
//  Created by Tobias Fu on 3/26/25.
//

import SwiftUI

struct SuggestFeatureView: View {
    @Environment(\EnvironmentValues.presentationMode) private var presentationMode
    @State private var featureTitle: String = ""
    @State private var featureDescription: String = ""
    @State private var email: String = ""
    @State private var showConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Your Suggestion")) {
                    TextField("Feature Title", text: $featureTitle)
                    TextEditor(text: $featureDescription)
                        .frame(height: 150)
                }

                Section(header: Text("Contact (Optional)"), footer: Text("Include your email if you'd like updates about your suggestion.")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Suggest a Feature")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitSuggestion()
                    }
                    .disabled(featureTitle.trimmingCharacters(in: .whitespaces).isEmpty || featureDescription.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert("Thanks for your suggestion!", isPresented: $showConfirmation) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    private func submitSuggestion() {
        // Replace with your actual submission logic (e.g., send to Supabase, Firebase, or email)
        print("Feature Suggested: \(featureTitle) - \(featureDescription) - \(email)")

        // Show confirmation
        showConfirmation = true
    }
}

// Preview
struct SuggestFeatureView_Previews: PreviewProvider {
    static var previews: some View {
        SuggestFeatureView()
    }
}

